# frozen_string_literal: true

##
# {Chan::Counter Chan::Counter} provides a counter
# for the number of written and received bytes on a
# given channel.
class Chan::Counter
  ##
  # @param [String] tmpdir
  #  Directory where temporary files are stored
  # @return [Chan::Counter]
  def initialize(tmpdir)
    @io = Chan.temporary_file(%w[counter .bin], tmpdir:)
    @io.binmode
    @io.sync = true
    write(@io, 0, 0)
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes written to a channel
  def bytes_written
    _, bytes = read(@io)
    bytes
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes read from a channel
  def bytes_read
    bytes, _ = read(@io)
    bytes
  end

  ##
  # @param [Integer] bytes_read
  #  Number of bytes read to increment the counter by
  # @param [Integer] bytes_written
  #  Number of bytes written to increment the counter by
  # @return [void]
  # @private
  def increment!(bytes_read: 0, bytes_written: 0)
    bytes_in, bytes_out = read(@io)
    bytes_in += bytes_read
    bytes_out += bytes_written
    write(@io, bytes_in, bytes_out)
  end

  ##
  # Close the counter
  # @return [void]
  def close
    @io.close
  end

  private

  def write(io, bytes_read, bytes_written)
    io.rewind
    io.truncate(0)
    io.write(serialize(bytes_read, bytes_written))
    io.rewind
  end

  def read(io)
    deserialize(io.read).tap { io.rewind }
  end

  def serialize(bytes_read, bytes_written)
    [bytes_read, bytes_written].pack("Q>Q>")
  end

  def deserialize(payload)
    payload.unpack("Q>Q>")
  end
end
