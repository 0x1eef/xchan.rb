# frozen_string_literal: true

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
  # @param socket_type (see Chan::UNIXSocket#initialize)
  # @param tmpdir (see Chan::UNIXSocket#initialize)
  # @return (see Chan::UNIXSocket#initialize)
  def xchan(serializer = :marshal, **kw_args)
    Chan::UNIXSocket.new(serializer, **kw_args)
  end
end
