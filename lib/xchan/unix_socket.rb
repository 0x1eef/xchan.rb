class XChan::UNIXSocket
  require "socket"
  require "base64"

  include Base64

  ##
  # @api private
  NULL_BYTE = "\x00"

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to the channel
  attr_reader :bytes_written

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from the channel
  attr_reader :bytes_read

  ##
  # @example
  #   ch = XChan::UNIXSocket.new(Marshal)
  #   ch.send [1,2,3]
  #   ch.recv.pop # => 3
  #   ch.close
  #
  # @param [#dump, #load] serializer
  #  A serializer.
  #
  # @return [XChan::UNIXSocket]
  def initialize(serializer)
    @serializer = serializer
    @reader, @writer = ::UNIXSocket.pair :STREAM
    @bytes_written = 0
    @bytes_read = 0
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is closed.
  def closed?
    @reader.closed? and @writer.closed?
  end

  ##
  # @raise [IOError]
  #  Raised when the channel is already closed.
  #
  # @return [Boolean]
  #  Returns true when the channel is closed.
  def close
    if closed?
      raise IOError, "Channel is already closed"
    else
      @reader.close
      @writer.close
      true
    end
  end

  ##
  # Performs a write that blocks until the underlying IO is writable.
  #
  # @raise (see #timed_send)
  #
  # @param [Object] object
  #  The object to send to the channel.
  #
  # @return (see #timed_send)
  def send(object)
    timed_send(object, nil)
  end
  alias_method :write, :send

  ##
  # Performs a write with a time out.
  #
  # @param [Object] object
  #  The object to write to the channel.
  #
  # @param [Float, Integer] timeout
  #  The amount of time to wait for the underlying IO to
  #  be writable
  #
  # @raise [IOError]
  #  Raised when the channel is closed.
  #
  # @raise [XChan::NilError]
  #  Raised when trying to write `nil` or `false` to the channel.
  #
  # @return [Integer, nil]
  #  The number of bytes written to the channel, or `nil` if the write
  #  times out.
  def timed_send(object, timeout = 0.1)
    raise IOError, "closed channel" if @writer.closed?
    raise XChan::NilError, "false and nil can't be written directly to a channel" if [nil, false].include?(object)
    _, writable, _ = IO.select nil, [@writer], nil, timeout
    if writable
      msg = @serializer.dump(object)
      syswrite_count = writable[0].syswrite "#{strict_encode64(msg)}#{NULL_BYTE}"
      @bytes_written += syswrite_count
      syswrite_count
    end
  end
  alias_method :timed_write, :timed_send

  ##
  # Performs a read that blocks until the underlying IO is readable.
  #
  # @raise (see #timed_recv)
  #
  # @return [Object]
  #  An object from the channel.
  def recv
    timed_recv(nil)
  end
  alias_method :read, :recv

  ##
  # Performs a read with a time out.
  #
  # @param [Float, Integer] timeout
  #  The amount of time to wait for the underlying IO to be readable.
  #
  # @raise [IOError]
  #  Raised when the channel is closed.
  #
  # @return [Object, nil]
  #  An object from the channel, or `nil` if the read times out.
  def timed_recv(timeout = 0.1)
    if @reader.closed?
      raise IOError, "closed channel"
    end
    readable, = IO.select [@reader], nil, nil, timeout
    if readable
      base64_str = readable[0].readline(NULL_BYTE)
      @bytes_read += base64_str.bytesize
      @serializer.load strict_decode64(base64_str.chomp(NULL_BYTE))
    end
  end
  alias_method :timed_read, :timed_recv

  ##
  # @example
  #   ch = xchan
  #   ch.send 1
  #   ch.send 2
  #   ch.send 3
  #   ch.recv_last # => 3
  #
  # @return [Object, nil]
  #  Returns the last object written to the channel or "nil" if the underlying IO is
  #  not readable.
  def recv_last
    last = nil
    last = recv while readable?
    last
  end
  alias_method :read_last, :recv_last

  ##
  # @return [Boolean]
  #  Returns true when the channel is ready to be read
  def readable?
    if closed?
      false
    else
      readable, _ = IO.select [@reader], nil, nil, 0
      !!readable
    end
  end
end
