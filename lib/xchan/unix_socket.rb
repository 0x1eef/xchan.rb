class XChan::UNIXSocket
  require 'socket'
  require 'base64'
  NULL_BYTE = "\x00"

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
  #   Returns true when channel is closed.
  #
  def closed?
    @reader.closed? and @writer.closed?
  end

  #
  # @raise [IOError]
  #   When channel is already closed.
  #
  # @return [Boolean]
  #   Returns true when channel is closed.
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
  # @raise [IOError]
  #   (see #send!)
  #
  # @param [Object] object
  #   Object to write to channel.
  #
  def send(object)
    send!(object, nil)
  end
  alias_method :write, :send

  #
  # Performs a write with a timeout.
  #
  # @param [Object] object
  #   Object to write to channel.
  #
  # @param [Float, Integer] timeout
  #   Number of seconds to wait.
  #
  # @raise [IOError]
  #   An IOError is raised when channel is closed.
  #
  # @raise [XChan::TimeoutError]
  #   When write times out.
  #
  def send!(object, timeout = 0.1)
    if @writer.closed?
      raise IOError, 'closed channel'
    end
    _, writable, _ = IO.select nil, [@writer], nil, timeout
    if writable
      msg = @serializer.dump(object)
      writable[0].syswrite "#{Base64.strict_encode64(msg)}#{NULL_BYTE}"
    else
      raise XChan::TimeoutError, "write timed out after waiting #{timeout} seconds"
    end
  end
  alias_method :write!, :send!

  #
  # Performs a blocking read.
  #
  # @raise
  #   (see XChan::UNIXSocket#recv!)
  #
  # @return [Object]
  #
  def recv
    recv!(nil)
  end
  alias_method :read, :recv

  #
  # Performs a read with a timeout.
  #
  # @param [Float, Integer] timeout
  #   Number of seconds to wait before exception is raised.
  #
  # @raise [IOError]
  #   When channel is closed.
  #
  # @raise [XChan::TimeoutError]
  #   When read times out.
  #
  # @return [Object]
  #
  def recv!(timeout = 0.1)
    if @reader.closed?
      raise IOError, 'closed channel'
    end
    readable, _ = IO.select [@reader], nil, nil, timeout
    if readable
      base64 = readable[0].readline(NULL_BYTE).chomp(NULL_BYTE)
      @last_msg = @serializer.load Base64.strict_decode64(base64)
    else
      raise XChan::TimeoutError, "read timed out after waiting #{timeout} seconds"
    end
  end
  alias_method :read!, :recv!

  #
  # Reads from a channel until there are no messages left, and
  # then returns the last read message.
  #
  # @return [Object]
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
