require 'socket'
class ZChannel::UNIXSocket
  SEP = '_$_'
  if respond_to? :private_constant
    private_constant :SEP
  end

  #
  # @param [#dump,#load] serializer
  #   An object who implements `.dump` and `.load` methods
  #
  # @return [ZChannel::UNIXSocket]
  #
  def initialize(serializer = Marshal)
    @serializer = serializer
    @last_msg = nil
    @reader, @writer = ::UNIXSocket.pair :STREAM
  end

  #
  # @return [Boolean]
  #   Returns true when a channel is closed
  #
  def closed?
    @reader.closed? and @writer.closed?
  end

  #
  # Close the channel
  #
  # @raise [IOError]
  #   When a channel is already closed
  #
  # @return [Boolean]
  #   Returns true on success
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
  # @raise [IOError]
  #   (see #send!)
  #
  # @param [Object] object
  #   An object to add to a channel
  #
  def send(object)
    send!(object, nil)
  end

  #
  # @param
  #   (see ZChannel::UNIXSocket#send)
  #
  # @param [Fixnum] timeout
  #   Number of seconds to wait before raising an exception
  #
  # @raise [IOError]
  #   When channel is closed
  #
  # @raise [ZChannel::TimeoutError]
  #   When a write doesn't finish within the timeout
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
      raise ZChannel::TimeoutError, "timeout, waited #{timeout} seconds"
    end
  end

  #
  # Perform a blocking read 
  #
  # @raise
  #   (see ZChannel::UNIXSocket#recv) 
  #
  # @return [Object]
  #
  def recv
    recv!(nil)
  end

  #
  # Perform a read with a timeout
  #
  # @param [Fixnum] timeout
  #   Number of seconds to wait before raising an exception
  #
  # @raise [IOError]
  #   When channel is closed
  #
  # @raise [ZChannel::TimeoutError]
  #   When a read doesn't finish within the timeout
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
      raise ZChannel::TimeoutError, "timeout, waited #{timeout} seconds"
    end
  end

  #
  # @return [Object]
  #
  def last_msg
    while readable?
      @last_msg = recv
    end
    @last_msg
  end

  #
  # @return [Boolean]
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
