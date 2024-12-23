# frozen_string_literal: true

##
# An easy-to-use InterProcess Communication (IPC) library
class Chan::UNIXSocket
  require "socket"
  require "lockf"
  require_relative "bytes"

  ##
  # @return [UNIXSocket]
  #  Returns a socket used for read operations
  attr_reader :r

  ##
  # @return [UNIXSocket]
  #  Returns a socket used for write operations
  attr_reader :w

  ##
  # @return [<#dump, #load>]
  #  Returns the serializer used by the channel
  attr_reader :s
  alias_method :serializer, :s

  ##
  # @example
  #   ch = Chan::UNIXSocket.new(:marshal)
  #   ch.send([1,2,3])
  #   ch.recv.pop # => 3
  #   ch.close
  # @param [Symbol, <#dump, #load>] serializer
  #  The name of a serializer
  # @param [Integer] sock
  #  Type of socket (eg `Socket::SOCK_STREAM`)
  # @param [String] tmpdir
  #  Directory where temporary files can be stored
  # @param [Lock::File, Chan::NullLock] lock
  #  An instance of `Lock::File`, or {Chan::NullLock Chan::NullLock}
  # @return [Chan::UNIXSocket]
  #  Returns an instance of {Chan::UNIXSocket Chan::UNIXSocket}
  def initialize(serializer, sock: Socket::SOCK_DGRAM, tmpdir: Dir.tmpdir, lock: lock_file(tmpdir:))
    @s = Chan.serializers[serializer]&.call || serializer
    @r, @w = ::UNIXSocket.pair(sock)
    @bytes = Chan::Bytes.new(tmpdir)
    @counter = Chan::Counter.new(tmpdir)
    @lockf = lock
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is closed
  def closed?
    @r.closed? and @w.closed?
  end

  ##
  # Closes the channel
  # @raise [IOError]
  #  When the channel is closed
  # @return [void]
  def close
    @lockf.lock
    raise IOError, "channel is closed" if closed?
    [@r, @w, @bytes, @lockf].each(&:close)
  rescue IOError => ex
    @lockf.release
    raise(ex)
  end

  ##
  # @group Write methods

  ##
  # Performs a blocking write
  # @param [Object] object
  #  An object
  # @raise [IOError]
  #  When the channel is closed
  # @return [Object]
  #  Returns the number of bytes written to the channel
  def send(object)
    send_nonblock(object)
  rescue Chan::WaitWritable, Chan::WaitLockable
    retry
  end
  alias_method :write, :send

  ##
  # Performs a non-blocking write
  # @param [Object] object
  #  An object
  # @raise [IOError]
  #  When the channel is closed
  # @raise [Chan::WaitWritable]
  #  When a write to {#w} blocks
  # @raise [Chan::WaitLockable]
  #  When a write blocks because of a lock held by another process
  # @return [Integer, nil]
  #  Returns the number of bytes written to the channel
  def send_nonblock(object)
    @lockf.lock_nonblock
    raise IOError, "channel closed" if closed?
    len = @w.write_nonblock(serialize(object))
    @bytes.push(len)
    @counter.increment!(bytes_written: len)
    len.tap { @lockf.release }
  rescue IOError, IO::WaitWritable, Errno::ENOBUFS => ex
    @lockf.release
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
  # @raise [IOError]
  #  When the channel is closed
  # @return [Object]
  #  Returns an object from the channel
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
  # @raise [IOError]
  #  When the channel is closed
  # @raise [Chan::WaitReadable]
  #  When a read from {#r} blocks
  # @raise [Chan::WaitLockable]
  #  When a read blocks because of a lock held by another process
  # @return [Object]
  #  Returns an object from the channel
  def recv_nonblock
    @lockf.lock_nonblock
    raise IOError, "closed channel" if closed?
    len = @bytes.shift
    obj = deserialize(@r.read_nonblock(len.zero? ? 1 : len))
    @counter.increment!(bytes_read: len)
    obj.tap { @lockf.release }
  rescue IOError => ex
    @lockf.release
    raise(ex)
  rescue IO::WaitReadable => ex
    @bytes.unshift(len)
    @lockf.release
    raise Chan::WaitReadable, ex.message
  rescue Errno::EAGAIN => ex
    raise Chan::WaitLockable, ex.message
  end
  alias_method :read_nonblock, :recv_nonblock

  ##
  # @endgroup

  ##
  # @example
  #   ch = xchan(:pure)
  #   1.upto(4) { ch.send(_1) }
  #   ch.to_a.last # => "4"
  # @return [Array<Object>]
  #  Returns the contents of the channel
  def to_a
    lock do
      [].tap { _1.push(recv) until empty? }
    end
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is empty
  def empty?
    return true if closed?
    lock { size.zero? }
  end

  ##
  # @group Stat methods

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to the channel
  def bytes_sent
    lock { @counter.bytes_written }
  end
  alias_method :bytes_written, :bytes_sent

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from the channel
  def bytes_received
    lock { @counter.bytes_read }
  end
  alias_method :bytes_read, :bytes_received

  ##
  # @return [Integer]
  #  Returns the number of objects waiting to be read
  def size
    lock { @bytes.size }
  end

  ##
  # @endgroup

  ##
  # @group Wait methods

  ##
  # Waits for the channel to become readable
  # @param [Float, Integer, nil] s
  #  The number of seconds to wait. Waits indefinitely with no arguments.
  # @return [Chan::UNIXSocket, nil]
  #  Returns self when the channel is readable, otherwise returns nil
  def wait_readable(s = nil)
    @r.wait_readable(s) and self
  end

  ##
  # Waits for the channel to become writable
  # @param [Float, Integer, nil] s
  #  The number of seconds to wait. Waits indefinitely with no arguments.
  # @return [Chan::UNIXSocket, nil]
  #  Returns self when the channel is writable, otherwise returns nil
  def wait_writable(s = nil)
    @w.wait_writable(s) and self
  end

  ##
  # @endgroup

  private

  def lock_file(tmpdir:)
    Lock::File.new Chan.temporary_file(%w[xchan .lock], tmpdir:)
  end

  def lock
    @lockf.lock
    yield
  ensure
    @lockf.release
  end

  def serialize(obj)
    @s.dump(obj)
  end

  def deserialize(str)
    @s.load(str)
  end
end
