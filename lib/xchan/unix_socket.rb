class XChan::UNIXSocket
  require "socket"
  require_relative "byte_buffer"

  ##
  # @return [#dump, #load]
  #  Returns the serializer being used by the channel
  attr_reader :serializer

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
    @serializer = XChan::SERIALIZERS[serializer]&.call || serializer
    @reader, @writer = ::UNIXSocket.pair(:STREAM)
    @buffer = XChan::ByteBuffer.new
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
      @buffer.close
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
  # @return [Integer, nil]
  #  The number of bytes written to the channel, or `nil` if the write
  #  times out.
  def timed_send(object, timeout = 0.1)
    raise IOError, "closed channel" if @writer.closed?
    writable = @writer.wait_writable(timeout)
    return unless writable
    byte_count = @writer.write(@serializer.dump(object))
    @buffer.push(byte_count)
    byte_count
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
    raise IOError, "closed channel" if @reader.closed?
    readable = @reader.wait_readable(timeout)
    return unless readable
    byte_count = @buffer.shift
    @serializer.load(@reader.read(byte_count))
  end
  alias_method :timed_read, :timed_recv

  ##
  # @example
  #   ch = xchan
  #   1.upto(4) { ch.send(_1) }
  #   ch.to_a.last # => 4
  #
  # @return [Array<Object>]
  #  Returns and consumes the contents of the channel.
  def to_a
    return [] unless readable?
    ary = []
    ary.push(recv) while readable?
    ary
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is ready for a read
  def readable?
    if closed?
      false
    else
      readable = @reader.wait_readable(0)
      !!readable
    end
  end

  ##
  # @return [Boolean]
  #   Returns true when the channel is empty, or closed
  def empty?
    closed? || bytes_read == bytes_written
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to the channel
  def bytes_written
    @buffer.bytes_written
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from the channel
  def bytes_read
    @buffer.bytes_read
  end
end
