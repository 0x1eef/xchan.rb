  ##
  # A module that is included into Ruby's {Object} class.
  module Chan::Mixin
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
      Chan::UNIXSocket.new(serializer)
    end
  end
