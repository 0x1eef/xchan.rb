# frozen_string_literal: true

##
# The {Chan::UNIXSocket Chan::UNIXSocket} class implements a channel
# for interprocess communication (IPC) using an unnamed UNIXSocket.
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
  #  Returns the serializer used by the channel.
  def serializer
    @serializer
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is closed.
  def closed?
    @reader.closed? and @writer.closed?
  end

  ##
  # Closes the channel.
  #
  # @raise [IOError]
  #  When the channel is closed.
  #
  # @return [void]
  def close
    @lock.obtain
    raise IOError, "channel is closed" if closed?
    [ @reader, @writer, @buffer, @lock.file ].each(&:close)
  rescue IOError => ex
    @lock.release
    raise(ex)
  end

  ##
  # @group Write methods

  ##
  # Performs a blocking write
  #
  # @param [Object] object
  #  An object to write to the channel.
  #
  # @raise [IOError]
  #  When the channel is closed.
  #
  # @return [Object]
  #  Returns the number of bytes written to the channel.
  def send(object)
    send_nonblock(object)
  rescue Chan::WaitWritable, Chan::WaitLockable
    retry
  end
  alias_method :write, :send

  ##
  # Performs a non-blocking write
  #
  # @param [Object] object
  #  An object to write to the channel.
  #
  # @raise [IOError]
  #  When the channel is closed.
  #
  # @raise [Chan::WaitWritable]
  #  When a write to the underlying IO blocks.
  #
  # @raise [Chan::WaitLockable]
  #  When a write blocks because of a lock held by another process.
  #
  # @return [Integer, nil]
  #  Returns the number of bytes written to the channel.
  def send_nonblock(object)
    @lock.obtain_nonblock
    raise IOError, "channel closed" if closed?
    len = @writer.write_nonblock(serialize(object))
    @buffer.push(len)
    len.tap { @lock.release }
  rescue IOError, IO::WaitWritable => ex
    @lock.release
    raise Chan::WaitWritable, ex.message
  rescue Errno::EWOULDBLOCK => ex
    raise Chan::WaitLockable, ex.message
  end
  alias_method :write_nonblock, :send_nonblock

  ##
  # @endgroup

  ##
  # @group Read methods

  ##
  # Performs a blocking read
  #
  # @raise [IOError]
  #  When the channel is closed.
  #
  # @return [Object]
  #  Returns an object from the channel.
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
  # Performs a non-blocking read
  #
  # @raise [IOError]
  #  When the channel is closed.
  #
  # @raise [Chan::WaitReadable]
  #  When a read from the underlying IO blocks.
  #
  # @raise [Chan::WaitLockable]
  #  When a read blocks because of a lock held by another process.
  #
  # @return [Object]
  #  Returns an object from the channel.
  def recv_nonblock
    @lock.obtain_nonblock
    raise IOError, "closed channel" if closed?
    len = @buffer.shift
    obj = deserialize(@reader.read_nonblock(len.zero? ? 1 : len))
    obj.tap { @lock.release }
  rescue IOError => ex
    @lock.release
    raise(ex)
  rescue IO::WaitReadable => ex
    @buffer.unshift(len)
    @lock.release
    raise Chan::WaitReadable, ex.message
  rescue Errno::EAGAIN => ex
    raise Chan::WaitLockable, ex.message
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
  #  Returns the consumed contents of the channel.
  def to_a
    lock do
      [].tap { _1.push(recv) until empty? }
    end
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is empty.
  def empty?
    return true if closed?
    lock { size.zero? }
  end

  ##
  # @group Size methods

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to the channel.
  def bytes_sent
    lock { @buffer.bytes_written }
  end
  alias_method :bytes_written, :bytes_sent

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from the channel.
  def bytes_received
    lock { @buffer.bytes_read }
  end
  alias_method :bytes_read, :bytes_received

  ##
  # @return [Integer]
  #  Returns the number of objects waiting to be read.
  def size
    lock { @buffer.size }
  end

  ##
  # @endgroup

  ##
  # @group Wait methods

  ##
  # Waits for the channel to become readable.
  #
  # @param [Float, Integer, nil] s
  #  The number of seconds to wait. Waits indefinitely when "nil".
  #
  # @return [Chan::UNIXSocket, nil]
  #  Returns self when the channel is readable, otherwise returns nil.
  def wait_readable(s = nil)
    @reader.wait_readable(s) and self
  end

  ##
  # Waits for the channel to become writable.
  #
  # @param [Float, Integer, nil] s
  #  The number of seconds to wait. Waits indefinitely when "nil".
  #
  # @return [Chan::UNIXSocket, nil]
  #  Returns self when the channel is writable, otherwise returns nil.
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

  def serialize(obj)
    @serializer.dump(obj)
  end

  def deserialize(str)
    @serializer.load(str)
  end
end
