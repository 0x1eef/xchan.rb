module XChan
  ##
  # The error raised when directly writing false or nil to a
  # channel.
  NilError = Class.new(RuntimeError)

  require_relative "xchan/version"
  require_relative "xchan/unix_socket"

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
    #   ch.send [1,2,3]
    #   ch.recv.pop # => 3
    #   ch.close
    #
    # @param [#dump, #load] serializer (see UNIXSocket#initialize)
    #
    # @return (see UNIXSocket#initialize)
    def xchan(serializer = Marshal)
      UNIXSocket.new(serializer)
    end
  end
end

class Object
  include XChan::ObjectMixin
end
