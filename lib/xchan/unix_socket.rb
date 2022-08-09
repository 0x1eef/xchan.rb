# frozen_string_literal: true

class Chan::UNIXSocket
  require "socket"
  require "lockf"
  require_relative "byte_buffer"

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
    @lock = Lock::File.new(Tempfile.new("xchan-lock_file").tap(&:unlink))
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
        @buffer, @lock.file].each(&:close)
    end
  end

  ##
  # Performs a write that could block.
  #
  # @param [Object] object
  #  The object to write to a channel.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @return [Object]
  #  The number of bytes written to a channel.
  def send(object)
    lock do
      perform_write(object) { _1.write(_2) }
    end
  end
  alias_method :write, :send

  ##
  # Performs a write that won't block.
  #
  # @param [Object] object
  #  The object to write to a channel.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @raise [Chan::WaitWritable]
  #  When a write to the underlying IO would block.
  #
  # @raise [Chan::WaitLockable]
  #  When a write would block because a lock is held by another process.
  #
  # @return [Integer, nil]
  #  The number of bytes written to a channel.
  def send_nonblock(object)
    lock(nonblock: true) do
      perform_write(object) { _1.write_nonblock(_2) }
    end
  rescue IO::EAGAINWaitWritable => ex
    raise Chan::WaitWritable, ex.message
  rescue Errno::EWOULDBLOCK => ex
    raise Chan::WaitLockable, ex.message
  end
  alias_method :write_nonblock, :send_nonblock

  ##
  # Performs a read that could block.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @return [Object]
  #  An object from a channel.
  def recv
    lock do
      wait_readable if empty?
      perform_read { _1.read(_2) }
    end
  end
  alias_method :read, :recv

  ##
  # Performs a read that won't block.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @raise [Chan::WaitReadable]
  #  When a read from the underlying IO would block.
  #
  # @raise [Chan::WaitLockable]
  #  When a read would block because a lock is held by another process.
  #
  # @return [Object]
  #  An object from a channel.
  def recv_nonblock
    lock(nonblock: true) do
      raise IO::EAGAINWaitReadable, "read would block" if empty?
      perform_read { _1.read_nonblock(_2) }
    end
  rescue IO::EAGAINWaitReadable => ex
    raise Chan::WaitReadable, ex.message
  rescue Errno::EWOULDBLOCK => ex
    raise Chan::WaitLockable, ex.message
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
    lock do
      [].tap { _1.push(recv) until empty? }
    end
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
  #  Returns true when a channel is empty, or closed.
  def empty?
    return true if closed?
    lock { size.zero? }
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to a channel.
  def bytes_sent
    lock { @buffer.bytes_written }
  end
  alias_method :bytes_written, :bytes_sent

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from a channel.
  def bytes_received
    lock { @buffer.bytes_read }
  end
  alias_method :bytes_read, :bytes_received

  ##
  # @return [Integer]
  #  Returns the number of objects waiting to be read from a channel.
  def size
    lock { @buffer.size }
  end

  ##
  # Waits for a channel to be readable.
  #
  # @param [Float, Integer, nil] s
  #  The amount of time to wait.
  #  Waits indefinitely when `nil`.
  #
  # @return [Chan::UNIXSocket, nil]
  #  Returns self when a channel is readable, otherwise returns nil.
  def wait_readable(s = nil)
    @reader.wait_readable(s) and self
  end

  ##
  # Waits for a channel to be writable.
  #
  # @param [Float, Integer, nil] s
  #  The amount of time to wait.
  #  Waits indefinitely when `nil`.
  #
  # @return [Chan::UNIXSocket, nil]
  #  Returns self when a channel is writable, otherwise returns nil.
  def wait_writable(s = nil)
    @writer.wait_writable(s) and self
  end

  private

  ##
  # Yields a block, and wraps it within an exclusive lock.
  # This method avoids obtaining a lock more than once in
  # cases where method calls are nested - for example:
  #
  #   lock { lock { lock { ... } } }
  #
  # @return [void]
  def lock(nonblock: false)
    @lock.synchronize(nonblock: nonblock) { yield }
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
