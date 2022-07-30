# frozen_string_literal: true

class Chan::UNIXSocket
  require "socket"
  require_relative "byte_buffer"
  require_relative "lock"

  ##
  # @return [<#dump, #load>]
  #  Returns the serializer being used by a channel.
  attr_reader :serializer

  ##
  # @example
  #   ch = Chan::UNIXSocket.new(:marshal)
  #   ch.send([1,2,3])
  #   ch.recv.pop # => 3
  #   ch.close
  #
  # @param [Symbol, <#dump, #load>] serializer
  #  A serializer.
  #
  # @return [Chan::UNIXSocket]
  #  Returns an instance of {Chan::UNIXSocket Chan::UNIXSocket}.
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
  # Closes a channel.
  #
  # @raise [IOError]
  #  When a channel is already closed.
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
  # @param lock (see UNIXSocket#timed_send)
  # @return (see #timed_send)
  def send(object)
    obtain_lock
    perform_write(object) { _1.write(_2) }
  ensure
    release_lock
  end
  alias_method :write, :send

  ##
  # Performs a write with a time out.
  #
  # @param [Object] object
  #  The object to write to a channel.
  #
  # @param [Boolean] lock
  #  When `true` the method will be wrapped in an exclusive lock.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @return [Integer, nil]
  #  The number of bytes sent to a channel.
  def send_nonblock(object)
    obtain_lock(nonblock: true)
    perform_write(object) { _1.write_nonblock(_2) }
  ensure
    release_lock
  end
  alias_method :write_nonblock, :send_nonblock

  ##
  # Performs a read that blocks until the underlying IO is readable.
  #
  # @param lock (see UNIXSocket#timed_recv)
  #
  # @raise (see #timed_recv)
  #
  # @return [Object]
  #  An object from a channel.
  def recv
    obtain_lock
    wait_readable if empty?
    perform_read { _1.read(_2) }
  ensure
    release_lock
  end
  alias_method :read, :recv

  ##
  # Performs a read with a time out.
  #
  # @param [Float, Integer] timeout
  #  The amount of time to wait for the underlying IO to be readable.
  #
  # @param [Boolean] lock
  #  When `true` the method will be wrapped in an exclusive lock.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @return [Object, nil]
  #  An object from a channel, or `nil` if the read times out.
  def recv_nonblock
    obtain_lock(nonblock: true)
    raise IO::EAGAINWaitReadable, "read would block" if empty?
    perform_read { _1.read_nonblock(_2) }
  ensure
    release_lock
  end
  alias_method :read_nonblock, :recv_nonblock

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
    ary = []
    ary.push(perform_read { _1.read(_2) }) until empty?
    ary
  ensure
    release_lock
  end

  ##
  # @return [Boolean]
  #  Returns true when a channel can be read from without blocking.
  def readable?
    return false if closed? || @lock.locked?
    !!wait_readable(0)
  end

  ##
  # @return [Boolean]
  #   Returns true when a channel is empty, or closed.
  def empty?
    closed? || bytes_read == bytes_written
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to a channel.
  def bytes_sent
    obtain_lock
    @buffer.bytes_written
  ensure
    release_lock
  end
  alias_method :bytes_written, :bytes_sent

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from a channel
  def bytes_received
    obtain_lock
    @buffer.bytes_read
  ensure
    release_lock
  end
  alias_method :bytes_read, :bytes_received

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

  def obtain_lock(nonblock: false)
    nonblock ? @lock.obtain_nonblock : @lock.obtain
  end

  def release_lock
    @lock.release
  end

  def perform_write(object)
    raise IOError, "closed channel" if @writer.closed?
    byte_count = yield(@writer, @serializer.dump(object))
    @buffer.push(byte_count)
    byte_count
  end

  def perform_read
    raise IOError, "closed channel" if @reader.closed?
    byte_count = @buffer.shift
    @serializer.load(yield(@reader, byte_count))
  end
end
