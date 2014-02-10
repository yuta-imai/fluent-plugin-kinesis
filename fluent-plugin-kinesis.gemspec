# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-kinesis"
  spec.version       = '0.0.1'
  spec.authors       = ["Yuta Imai"]
  spec.email         = ["'imai.factory@gmail.com'"]
  spec.description   = %q{Fluent plugin for kinesis. This plugin put record to Amazon Kinesis.}
  spec.summary       = %q{Fluent plugin for kinesis.}
  spec.homepage      = "https://github.com/imaifactory/fluent-plugin-kinesis"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit-rr"

  spec.add_dependency "fluentd"
  # Kinesis client is not work in "< 1.31.3"
  spec.add_dependency "aws-sdk", ">= 1.31.3"
  spec.add_dependency "json"
  spec.add_dependency "msgpack", ">= 0.5.8"
end
