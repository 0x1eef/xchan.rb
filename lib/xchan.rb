module XChan
  NilError = Class.new(RuntimeError)

  require_relative 'xchan/version'
  require_relative 'xchan/unix_socket'

  #
  # A module that is included into Ruby's {Object} class.
  #
  module ObjectMixin
    #
    # @example
    #   ch = xchan Marshal
    #   ch.send "Hello world"
    #   ch.close
    #
    # @param [#dump, #load] serializer (see UNIXSocket#initialize)
    #
    # @return (see UNIXSocket#initialize)
    #
    def xchan(serializer)
      UNIXSocket.new(serializer)
    end
  end
end

class Object
  include XChan::ObjectMixin
end
