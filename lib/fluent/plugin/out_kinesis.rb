module Fluent
    class KinesisOutput < Fluent::Output
        Fluent::Plugin.register_output('kinesis',self)

        def initialize
            super
            require "base64"
            require 'aws-sdk'
        end

        def configure(conf)
            super
            @stream = conf['stream']
            @aws_access_key_id = conf['aws_access_key_id']
            @aws_secret_access_key = conf['aws_secret_access_key']
            @region = conf['region']
            @host = conf['api_host']
            @partition_key   = conf["partition_key"]
            @sequence_number = conf["sequence_number"] || nil
        end

        def start
            super
            AWS.config(
                :access_key_id =>  @aws_access_key_id ,
                :secret_access_key => @aws_secret_access_key,
                :region => @region
            )
            config = AWS.config
            @credentials = config.credential_provider
            @handler = AWS::Core::Http::NetHttpHandler.new()
        end

        def shutdown
            super
        end

        def emit(tag,es,chain)
            chain.next
            es.each{|time,record|
                request = build_request(record)
                exec_request(request)
            }
        end

        private
        def exec_request request
            response = AWS::Core::Http::Response.new()
            @handler.handle(request,response)
            p response.body
        end

        def build_request record
            request = AWS::Core::Http::Request.new()
            request.http_method = 'POST'
            request.host = @host
            request.body = build_body(record)
            request.headers["X-Amz-Target"] = 'Kinesis_20131104.PutRecord'
            request.headers['x-amz-content-sha256'] ||= hexdigest(request.body || '')
            request.use_ssl = true

            datetime = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
            request.headers['content-type'] ||= 'application/x-amz-json-1.1'
            request.headers['host'] = request.host
            request.headers['x-amz-date'] = datetime
            request.headers['User-Agent'] = "fluent-plugin-kinesis"
                
            parts = []
            parts << "AWS4-HMAC-SHA256 Credential=#{@credentials.access_key_id}/#{credential_string(datetime)}"
            parts << "SignedHeaders=#{signed_headers(request.headers)}"
            parts << "Signature=#{signature(@credentials, datetime, request)}"

            request.headers['authorization'] = parts.join(', ')
            request
        end

        def build_body record
            data = {
                :StreamName   => @stream,
                :PartitionKey => record[@partition_key],
                :Data         => Base64.encode64(JSON.dump(record)).strip!.gsub("\n","")
            }
            JSON.dump(data)
        end

        def hexdigest value
            digest = Digest::SHA256.new
            if value.respond_to?(:read)
            chunk = nil
            chunk_size = 1024 * 1024 # 1 megabyte
            digest.update(chunk) while chunk = value.read(chunk_size)
            value.rewind
            else
            digest.update(value)
            end
            digest.hexdigest
        end

        def credential_string datetime
            parts = []
            parts << datetime[0,8]
            parts << "us-east-1"
            parts << "kinesis"
            parts << 'aws4_request'
            parts.join("/")
        end

        def signed_headers headers
            to_sign = headers.keys.map{|k| k.to_s.downcase }
            to_sign.delete('authorization')
            to_sign.sort.join(";")
        end

        def canonical_headers original_headers
            headers = []
            original_headers.each_pair do |k,v|
                headers << [k,v] unless k == 'authorization'
            end
            headers = headers.sort_by(&:first)
            headers.map{|k,v| "#{k}:#{canonical_header_values(v)}" }.join("\n")
        end

        def signature credentials, datetime, request
            k_secret = credentials.secret_access_key
            k_date = hmac("AWS4" + k_secret, datetime[0,8])
            k_region = hmac(k_date, "us-east-1")
            k_service = hmac(k_region, "kinesis")
            k_credentials = hmac(k_service, 'aws4_request')
            hexhmac(k_credentials, string_to_sign(datetime, request))
        end

        def hmac key, value
            OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, value)
        end

        def hexhmac key, value
            OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'), key, value)
        end

        def string_to_sign datetime, request
            parts = []
            parts << 'AWS4-HMAC-SHA256'
            parts << datetime
            parts << credential_string(datetime)
            parts << hexdigest(canonical_request(request))
            parts.join("\n")
        end

        def canonical_request request
            parts = []
            parts << request.http_method
            parts << request.path
            parts << request.querystring
            parts << canonical_headers(request.headers) + "\n"
            parts << signed_headers(request.headers)
            parts << request.headers['x-amz-content-sha256']
            parts.join("\n")
        end

        def canonical_header_values values
            values = [values] unless values.is_a?(Array)
            values.map(&:to_s).join(',').gsub(/\s+/, ' ').strip
        end
    end
end
