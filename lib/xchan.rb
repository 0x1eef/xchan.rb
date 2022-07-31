# frozen_string_literal: true

module Chan
  require_relative "xchan/version"
  require_relative "xchan/unix_socket"

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

  ##
  # A module that is included into Ruby's {Object} class.
  module ObjectMixin
    ##
    # @example
    #   ch = xchan
    #   ch.send([1,2,3])
    #   ch.recv.pop # => 3
    #   ch.close
    #
    # @param serializer (see Chan::UNIXSocket#initialize)
    #
    # @return (see Chan::UNIXSocket#initialize)
    def xchan(serializer = :marshal)
      UNIXSocket.new(serializer)
    end
  end
end

class Object
  include Chan::ObjectMixin
end
