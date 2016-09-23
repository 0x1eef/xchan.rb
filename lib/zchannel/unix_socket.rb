require 'socket'
class ZChannel::UNIXSocket
  SEP = "\x00"

  #
  # @param [#dump,#load] serializer
  #   Any object that implements "dump" and "load" methods.
  #
  # @return [ZChannel::UNIXSocket]
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
  #   Raises IOError when a channel is already closed.
  #
  # @return [Boolean]
  #   Returns true when a channel is closed successfully.
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
  # Perform a blocking write.
  #
  # @raise [IOError]
  #   (see #send!)
  #
  # @param [Object] object
  #   An object to write to a channel.
  #
  def send(object)
    send!(object, nil)
  end
  alias_method :write, :send

  #
  # Perform a write with a timeout.
  #
  # @param [Object] object
  #   An object to write to a channel.
  #
  # @param [Float, Fixnum] timeout
  #   The number of seconds to wait before raising an exception.
  #
  # @raise [IOError]
  #   Raises an IOError when a channel is closed.
  #
  # @raise [ZChannel::TimeoutError]
  #   Raises a ZChannel::TimeoutError when a write doesn't finish within the specified timeout.
  #
  def send!(object, timeout = 0.1)
    if @writer.closed?
      raise IOError, 'closed channel'
    end
    _, writable, _ = IO.select nil, [@writer], nil, timeout
    if writable
      msg = @serializer.dump(object)
      writable[0].syswrite "#{msg}#{SEP}"
    else
      raise ZChannel::TimeoutError, "write timed out after waiting #{timeout} seconds"
    end
  end
  alias_method :write!, :send!

  #
  # Perform a blocking read.
  #
  # @raise
  #   (see ZChannel::UNIXSocket#recv!)
  #
  # @return [Object]
  #
  def recv
    recv!(nil)
  end
  alias_method :read, :recv

  #
  # Perform a read with a timeout.
  #
  # @param [Float, Fixnum] timeout
  #   The number of seconds to wait before raising an exception.
  #
  # @raise [IOError]
  #   Raises an IOError when a channel is closed.
  #
  # @raise [ZChannel::TimeoutError]
  #   Raises ZChannel::TimeoutError when a read doesn't finish within the specified timeout.
  #
  # @return [Object]
  #
  def recv!(timeout = 0.1)
    if @reader.closed?
      raise IOError, 'closed channel'
    end
    readable, _ = IO.select [@reader], nil, nil, timeout
    if readable
      msg = readable[0].readline(SEP).chomp SEP
      @last_msg = @serializer.load msg
    else
      raise ZChannel::TimeoutError, "read timed out after waiting #{timeout} seconds"
    end
  end
  alias_method :read!, :recv!

  #
  # @return [Object]
  #   Reads from a channel until there are no messages left, and
  #   then returns the last read message.
  #
  def last_msg
    @last_msg = recv while readable?
    @last_msg
  end

  #
  # @return [Boolean]
  #   Returns true when a channel has messages waiting to be read.
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
