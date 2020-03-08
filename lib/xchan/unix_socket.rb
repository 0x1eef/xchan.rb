class XChan::UNIXSocket
  require 'socket'
  require 'base64'

  # @private
  NULL_BYTE = "\x00"

  #
  # @example
  #   ch = XChan::UNIXSocket.new(Marshal)
  #   ch.send "Hello world"
  #   ch.close
  #
  # @param [#dump, #load] serializer
  #   A serializer (eg Marshal, JSON, YAML)
  #
  # @return [XChan::UNIXSocket]
  #
  def initialize(serializer)
    @serializer = serializer
    @last_msg = nil
    @reader, @writer = ::UNIXSocket.pair :STREAM
  end

  #
  # @return [Boolean]
  #   Returns true when a channel is closed.
  #
  def closed?
    @reader.closed? and @writer.closed?
  end

  #
  # @raise [IOError]
  #   When a channel is already closed.
  #
  # @return [Boolean]
  #   Returns true when a channel is closed.
  #
  def close
    if closed?
      raise IOError, 'closed channel'
    else
      @reader.close
      @writer.close
      true
    end
  end

  #
  # Performs a blocking write.
  #
  # @raise (see #timed_send)
  #
  # @param [Object] object
  #   The object to write to a channel.
  #
  def send(object)
    timed_send(object, nil)
  end
  alias_method :write, :send

  #
  # Performs a write with a time out.
  #
  # @param [Object] object
  #   The object to write to a channel.
  #
  # @param [Float, Integer] timeout
  #   The amount of time to wait before timing out.
  #
  # @raise [IOError]
  #   When a channel is closed.
  #
  # @raise [XChan::NilError]
  #   When trying to write `nil` or `false` to a channel.
  #
  # @return [Integer, nil]
  #    Returns the number of bytes written to a channel, or `nil` if the
  #    write times out.
  #
  def timed_send(object, timeout = 0.1)
    raise IOError, 'closed channel' if @writer.closed?
    raise XChan::NilError, "false and nil values can't be written to a channel" if [nil, false].include?(object)
    _, writable, _ = IO.select nil, [@writer], nil, timeout
    if writable
      msg = @serializer.dump(object)
      writable[0].syswrite "#{Base64.strict_encode64(msg)}#{NULL_BYTE}"
    else
      nil
    end
  end
  alias_method :timed_write, :timed_send

  #
  # Performs a blocking read.
  #
  # @raise (see #timed_recv)
  #
  # @return [Object]
  #   Returns the object read from a channel.
  #
  def recv
    timed_recv(nil)
  end
  alias_method :read, :recv

  #
  # Performs a read with a time out.
  #
  # @param [Float, Integer] timeout
  #   The amount of time to wait before timing out.
  #
  # @raise [IOError]
  #   When a channel is closed.
  #
  # @return [Object, nil]
  #   Returns the last object written to a channel, or `nil` if the
  #   read times out.
  #
  def timed_recv(timeout = 0.1)
    if @reader.closed?
      raise IOError, 'closed channel'
    end
    readable, _ = IO.select [@reader], nil, nil, timeout
    if readable
      base64 = readable[0].readline(NULL_BYTE).chomp(NULL_BYTE)
      @last_msg = @serializer.load Base64.strict_decode64(base64)
    else
      nil
    end
  end
  alias_method :timed_read, :timed_recv

  #
  # Reads from a channel until there are no messages left, and
  # then returns the last read message.
  #
  # @return [Object]
  #   The last message read from a channel.
  #
  def last_msg
    @last_msg = recv while readable?
    @last_msg
  end

  #
  # @return [Boolean]
  #   Returns true when there is one or more messages waiting to be read.
  #
  def readable?
    if closed?
      false
    else
      readable, _ = IO.select [@reader], nil, nil, 0
      !! readable
    end
  end
end
