module Fluent
    class KinesisOutput < Fluent::BufferedOutput
        include Fluent::SetTimeKeyMixin
        include Fluent::SetTagKeyMixin

        Fluent::Plugin.register_output('kinesis',self)

        def initialize
            super
            require 'aws-sdk'
            require 'base64'
            require 'json'
            require 'logger'
        end

        config_set_default :include_time_key, true
        config_set_default :include_tag_key,  true

        config_param :aws_key_id,   :string, :default => nil
        config_param :aws_sec_key,  :string, :default => nil
        config_param :region,       :string, :default => nil

        config_param :stream_name,            :string, :default => nil
        config_param :partition_key,          :string, :default => nil
        config_param :partition_key_proc,     :string, :default => nil
        config_param :explicit_hash_key,      :string, :default => nil
        config_param :explicit_hash_key_proc, :string, :default => nil

        config_param :sequence_number_for_ordering, :string, :default => nil

        config_param :debug, :bool, :default => false

        def configure(conf)
            super

            [:aws_key_id, :aws_sec_key, :region, :stream_name].each do |name|
                unless self.instance_variable_get("@#{name}")
                    raise ConfigError, "'#{name}' is required"
                end
            end

            unless @partition_key or @partition_key_proc
                raise ConfigError, "'partition_key' or 'partition_key_proc' is required"
            end

            if @partition_key_proc
                @partition_key_proc = eval(@partition_key_proc)
            end

            if @explicit_hash_key_proc
                @explicit_hash_key_proc = eval(@explicit_hash_key_proc)
            end
        end

        def start
            super
            configure_aws
            @client = AWS.kinesis.client
            @client.describe_stream(:stream_name => @stream_name)
        end

        def shutdown
            super
        end

        def format(tag, time, record)
            # XXX: The maximum size of the data blob is 50 kilobytes
            # http://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html
            data = {
                :stream_name => @stream_name,
                :data => encode64(record.to_json),
                :partition_key => get_key(:partition_key,record)
            }

            if @explicit_hash_key or @explicit_hash_key_proc
                data[:explicit_hash_key] = get_key(:explicit_hash_key,record)
            end

            if @sequence_number_for_ordering
                data[:sequence_number_for_ordering] = @sequence_number_for_ordering
            end

            data.to_msgpack
        end

        def write(chunk)
            chunk.msgpack_each do |data|
                while (data = unpack_data(buf))
                    @client.put_record(data)
                end
            end
        end

        private
        def configure_aws
            options = {
                :access_key_id => @aws_key_id,
                :secret_access_key => @aws_sec_key,
                :region => @region
            }

            if @debug
                options.update(
                    :logger => Logger.new($log.out),
                    :log_level => :debug
                )
                # XXX: Add the following options, if necessary
                # :http_wire_trace => true
            end

            AWS.config(options)
        end

        def get_key(name, record)
            key = self.instance_variable_get("@#{name}")
            key_proc = self.instance_variable_get("@#{name}_proc")

            value = key ? record[key] : record

            if key_proc
                value = key_proc.arity.zero? ? key_proc.call : key_proc.call(value)
            end

            value.to_s
        end

        def encode64(str)
            Base64.encode64(str).delete("\n")
        end
    end
end
