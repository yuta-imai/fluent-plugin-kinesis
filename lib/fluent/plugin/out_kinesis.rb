module Fluent
    class KinesisOutput < Fluent::BufferedOutput
        Fluent::Plugin.register_output('kinesis',self)

        def initialize
            super
            require 'aws-sdk'
        end

        def configure(conf)
            super
            @stream = conf['stream']
            @path = conf['path']
        end

        def start
            super
        end

        def shutdown
            super
        end

        def format(tag,time,record)
            [tag,time,record].to_msgpack
        end

        def write(chunk)
            records = []
            chunk.msgpack_each { |record|
                # records << record
            }
            # write records
        end
    end
end
