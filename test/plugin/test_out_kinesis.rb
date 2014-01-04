require 'helper'

class KinesisOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    aws_key_id test_key_id
    aws_sec_key test_sec_key
    stream_name test_stream
    region us-east-1
    partition_key test_partition_key
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::KinesisOutput, tag) do
        def start
            super
        end

        def write(chunk)
            chunk.read
        end
    end.configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'test_key_id', d.instance.aws_key_id
    assert_equal 'test_sec_key', d.instance.aws_sec_key
    assert_equal 'test_stream', d.instance.stream_name
    assert_equal 'us-east-1', d.instance.region
    assert_equal 'test_partition_key', d.instance.partition_key
  end

  def test_format
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"test_partition_key"=>"key1","a"=>1}, time)
    d.emit({"test_partition_key"=>"key2","a"=>2}, time)

    d.expect_format %!\x94\x00\x00\x00\x83\xABstream_name\xABtest_stream\xA4data\xDA\x00`eyJ0ZXN0X3BhcnRpdGlvbl9rZXkiOiJrZXkxIiwiYSI6MSwiX190YWciOiJ0ZXN0IiwiX190aW1lIjoxMjkzOTc0MDU1fQ==\xADpartition_key\xA4key1!.b
    d.expect_format %!\x94\x00\x00\x00\x83\xABstream_name\xABtest_stream\xA4data\xDA\x00`eyJ0ZXN0X3BhcnRpdGlvbl9rZXkiOiJrZXkyIiwiYSI6MiwiX190YWciOiJ0ZXN0IiwiX190aW1lIjoxMjkzOTc0MDU1fQ==\xADpartition_key\xA4key2!.b

    d.run
  end

  def test_format_with_sequence_number_for_ordering
    conf = CONFIG.clone
    conf << "\nsequence_number_for_ordering seq_num\n"
    d = create_driver(conf)

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"test_partition_key"=>"key1","seq_num"=>100,"a"=>1}, time)
    d.emit({"test_partition_key"=>"key2","seq_num"=>100,"a"=>2}, time)

    d.expect_format %!\xC9\x00\x00\x00\x84\xABstream_name\xABtest_stream\xA4data\xDA\x00peyJ0ZXN0X3BhcnRpdGlvbl9rZXkiOiJrZXkxIiwic2VxX251bSI6MTAwLCJhIjoxLCJfX3RhZyI6InRlc3QiLCJfX3RpbWUiOjEyOTM5NzQwNTV9\xADpartition_key\xA4key1\xBCsequence_number_for_ordering\xA7seq_num!.b
    d.expect_format %!\xC9\x00\x00\x00\x84\xABstream_name\xABtest_stream\xA4data\xDA\x00peyJ0ZXN0X3BhcnRpdGlvbl9rZXkiOiJrZXkyIiwic2VxX251bSI6MTAwLCJhIjoyLCJfX3RhZyI6InRlc3QiLCJfX3RpbWUiOjEyOTM5NzQwNTV9\xADpartition_key\xA4key2\xBCsequence_number_for_ordering\xA7seq_num!.b

    d.run
  end

  def test_get_key
    d = create_driver
    assert_equal("1",d.instance.send(:get_key, "partition_key", {"test_partition_key" => 1}))
  end

end
