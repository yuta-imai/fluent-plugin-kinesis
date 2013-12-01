module Fluent
    class KinesisOutput < Fluent::Output
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

        def emit(tag,es,chain)
            chain.next
            es.each{|time,record|
                $stderr.puts "OK!"
            }
        end
    end
end
