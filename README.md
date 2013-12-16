# Fluent::Plugin::Kinesis

## Overview

Output plugin for Amazon Kinesis.
Currently, this plugin is based on 'Fluent::Output', so it emits data to Kinesis at each input.
In the near future, it will be based on Timeslied 'Fluent::TimeSlicedOutput' to increase throghput.

## Configuration
```ruby
    type kinesis
    stream YOUR_STREAM_NAME
    aws_access_key_id YOUR_AWS_ACCESS_KEY
    aws_secret_access_key YOUR_SECRET_KEY
    region us-east-1
    partition_key PARTITION_KEY
    sequence_number SEQUENCE_NUMBER
```
[stream_name] Name of the stream to put data.

[aws_key_id] AWS access key id. This parameter is required when your agent is not running on EC2 instance with an IAM Instance Profile.

[aws_sec_key] AWS secret key. This parameter is required when your agent is not running on EC2 instance with an IAM Instance Profile.

[region] AWS region of your stream. It should be in form like these "us-east-1", "us-west-1".

[partition_key] The key to designate for partition key in Amazon Kinesis.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
