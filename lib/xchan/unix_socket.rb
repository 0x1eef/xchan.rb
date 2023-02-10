# frozen_string_literal: true

##
# The {Chan::UNIXSocket Chan::UNIXSocket} class implements a channel
# for interprocess communication using an unnamed UNIXSocket.
class Chan::UNIXSocket
  require "socket"
  require "lockf"
  require_relative "byte_buffer"

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
  # @return [<#dump, #load>]
  #  Returns the serializer being used by a channel.
  def serializer
    @serializer
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
  # @group Write methods

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
    send_nonblock(object)
  rescue Chan::WaitWritable, Chan::WaitLockable
    retry
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
    raise IOError, "channel closed" if closed?
    @lock.obtain_nonblock
    len = @writer.write_nonblock(@serializer.dump(object))
    @buffer.push(len)
    len
  rescue IO::WaitWritable => ex
    raise Chan::WaitWritable, ex.message
  rescue Errno::EWOULDBLOCK => ex
    raise Chan::WaitLockable, ex.message
  ensure
    @lock.release
  end
  alias_method :write_nonblock, :send_nonblock

  ##
  # @endgroup

  ##
  # @group Read methods

  ##
  # Performs a read that could block.
  #
  # @raise [IOError]
  #  When a channel is closed.
  #
  # @return [Object]
  #  An object from a channel.
  def recv
    recv_nonblock
  rescue Chan::WaitReadable
    wait_readable
    retry
  rescue Chan::WaitLockable
    retry
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
    @lock.obtain_nonblock
    raise IOError, "closed channel" if closed?
    len = @buffer.shift
    deserialize(@reader.read_nonblock(len.zero? ? 1 : len))
  rescue IO::WaitReadable => ex
    @buffer.unshift(len)
    raise Chan::WaitReadable, ex.message
  rescue Errno::EAGAIN => ex
    @buffer.unshift(len)
    raise Chan::WaitLockable, ex.message
  ensure
    @lock.release
  end
  alias_method :read_nonblock, :recv_nonblock

  ##
  # @endgroup

  ##
  # @example
  #   ch = xchan
  #   1.upto(4) { ch.send(_1) }
  #   ch.to_a.last # => 4
  #
  # @return [Array<Object>]
  #  Returns the consumed contents of a channel.
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
  # @group Size methods

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
  # @endgroup

  ##
  # @group Wait methods

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

  ##
  # @endgroup

  private

  def lock(nonblock: false)
    nonblock ? @lock.obtain_nonblock : @lock.obtain
    yield
  ensure
    @lock.release
  end
end
