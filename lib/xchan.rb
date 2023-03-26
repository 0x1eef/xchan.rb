# frozen_string_literal: true

module Chan
  require_relative "xchan/version"
  require_relative "xchan/unix_socket"
  require_relative "xchan/mixin"

  WaitReadable = Class.new(IO::EAGAINWaitReadable)
  WaitWritable = Class.new(IO::EAGAINWaitWritable)
  WaitLockable = Class.new(Errno::EWOULDBLOCK)
  Plain = Class.new do
    def self.dump(str) = str.to_s
    def self.load(str) = str.to_s
  end

  def self.serializers
    {
      plain: lambda { Plain },
      marshal: lambda { Marshal },
      json: lambda {
        require "json" unless defined?(JSON)
        JSON
      },
      yaml: lambda {
        require "yaml" unless defined?(YAML)
        YAML
      }
    }
  end
end

class Object
  include Chan::Mixin
end
