# frozen_string_literal: true

module Chan
  require_relative "xchan/version"
  require_relative "xchan/unix_socket"
  require_relative "xchan/mixin"

  WaitReadable = Class.new(IO::EAGAINWaitReadable)
  WaitWritable = Class.new(IO::EAGAINWaitWritable)
  WaitLockable = Class.new(Errno::EWOULDBLOCK)

  SERIALIZERS = {
    marshal: lambda {
      Marshal
    },
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

class Object
  include Chan::Mixin
end
