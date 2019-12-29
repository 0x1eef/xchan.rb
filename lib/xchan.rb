module XChan
  TimeoutError = Class.new(RuntimeError)
  require_relative 'xchan/version'
  require_relative 'xchan/unix_socket'

  module ObjectMixin
    #
    # @param serializer
    #   (see UNIXSocket#initialize).
    #
    # @return
    #   (see UNIXSocket#initialize)
    #
    def xchan(serializer)
      UNIXSocket.new(serializer)
    end
  end
end

class Object
  include XChan::ObjectMixin
end
