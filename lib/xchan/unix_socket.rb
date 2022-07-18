class Chan::UNIXSocket
  require "socket"
  require_relative "byte_buffer"
  require_relative "lock"

  ##
  # @return [#dump, #load]
  #  Returns the serializer being used by a channel
  attr_reader :serializer

  ##
  # @example
  #   ch = Chan::UNIXSocket.new(Marshal)
  #   ch.send [1,2,3]
  #   ch.recv.pop # => 3
  #   ch.close
  #
  # @param [Symbol, <#dump, #load>] serializer
  #  A serializer.
  #
  # @return [Chan::UNIXSocket]
  def initialize(serializer)
    @serializer = Chan::SERIALIZERS[serializer]&.call || serializer
    @reader, @writer = ::UNIXSocket.pair(:STREAM)
    @buffer = Chan::ByteBuffer.new
    @lock = Chan::Lock.new
  end

  ##
  # @return [Boolean]
  #  Returns true when a channel is closed.
  def closed?
    @reader.closed? and @writer.closed?
  end

  ##
  # @raise [IOError]
  #  Raised when a channel is already closed.
  #
  # @return [void]
  def close
    if closed?
      raise IOError, "channel is already closed"
    else
      [@reader, @writer,
        @buffer, @lock].each(&:close)
    end
  end

  ##
  # Performs a write that blocks until the underlying IO is writable.
  #
  # @raise (see #timed_send)
  #
  # @param [Object] object
  #  The object to send to a channel.
  #
  # @return (see #timed_send)
  def send(object, lock: true)
    timed_send(object, timeout: nil, lock: lock)
  end
  alias_method :write, :send

  ##
  # Performs a write with a time out.
  #
  # @param [Object] object
  #  The object to write to a channel.
  #
  # @param [Float, Integer] timeout
  #  The amount of time to wait for the underlying IO to
  #  be writable
  #
  # @raise [IOError]
  #  Raised when a channel is closed.
  #
  # @return [Integer, nil]
  #  The number of bytes written to a channel, or `nil` if the write
  #  times out.
  def timed_send(object, timeout: 0.1, lock: true)
    obtain_lock(lock: lock)
    raise IOError, "closed channel" if @writer.closed?
    writable = @writer.wait_writable(timeout)
    return unless writable
    byte_count = @writer.write(@serializer.dump(object))
    @buffer.push(byte_count)
    byte_count
  ensure
    release_lock(lock: lock)
  end
  alias_method :timed_write, :timed_send

  ##
  # Performs a read that blocks until the underlying IO is readable.
  #
  # @raise (see #timed_recv)
  #
  # @return [Object]
  #  An object from a channel.
  def recv(lock: true)
    timed_recv(timeout: nil, lock: lock)
  end
  alias_method :read, :recv

  ##
  # Performs a read with a time out.
  #
  # @param [Float, Integer] timeout
  #  The amount of time to wait for the underlying IO to be readable.
  #
  # @raise [IOError]
  #  Raised when a channel is closed.
  #
  # @return [Object, nil]
  #  An object from a channel, or `nil` if the read times out.
  def timed_recv(timeout: 0.1, lock: true)
    obtain_lock(lock: lock)
    raise IOError, "closed channel" if @reader.closed?
    readable = @reader.wait_readable(timeout)
    return unless readable
    byte_count = @buffer.shift
    @serializer.load(@reader.read(byte_count))
  ensure
    release_lock(lock: lock)
  end
  alias_method :timed_read, :timed_recv

  ##
  # @example
  #   ch = xchan
  #   1.upto(4) { ch.send(_1) }
  #   ch.to_a.last # => 4
  #
  # @return [Array<Object>]
  #  Returns and consumes the contents of a channel.
  def to_a
    obtain_lock
    return [] unless readable?
    ary = []
    ary.push(recv(lock: false)) while readable?
    ary
  ensure
    release_lock
  end

  ##
  # @return [Boolean]
  #  Returns true when a channel is ready for a read
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
  #   Returns true when a channel is empty, or closed
  def empty?
    closed? || bytes_read == bytes_written
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to a channel
  def bytes_written
    obtain_lock
    @buffer.bytes_written
  ensure
    release_lock
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from a channel
  def bytes_read
    obtain_lock
    @buffer.bytes_read
  ensure
    release_lock
  end

  ##
  # @return [Integer]
  #  Returns the number of objects waiting to be read from a channel
  def size
    obtain_lock
    @buffer.size
  ensure
    release_lock
  end

  private

  def obtain_lock(lock: true)
    return unless lock
    @lock.obtain
  end

  def release_lock(lock: true)
    return unless lock
    @lock.release
  end
end
