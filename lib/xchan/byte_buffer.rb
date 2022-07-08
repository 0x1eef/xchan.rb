##
# The ByteBuffer class is responsible for storing the number
# of bytes used to store each object written to a channel,
# which in turn is used when reading an object from a channel.
class XChan::ByteBuffer
  require "tempfile"

  ##
  # @return [XChan::ByteBuffer]
  def initialize
    @serializer = Marshal
    @buffer = Tempfile.new("xchan-byte_buffer").tap(&:unlink)
    write({bytes_written: 0, bytes_read: 0, bytes: []})
  end

  ##
  # @param [Integer] byte_size
  #  The number of bytes written to a channel.
  #
  # @return [void]
  def push(byte_size)
    buffer = read
    buffer[:bytes].push(byte_size)
    byte_size.tap { write(buffer, bytes_written: byte_size) }
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes stored for an object
  #  written to a channel.
  def shift
    buffer = read
    buffer[:bytes].shift.tap { write(buffer, bytes_read: _1) }
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to the channel
  def bytes_written
    read[:bytes_written]
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from the channel
  def bytes_read
    read[:bytes_read]
  end

  ##
  # Close the buffer
  #
  # @return [void]
  def close
    @buffer.close
  end

  private

  def read
    retry_count = 0
    @buffer.flock(File::LOCK_SH)
    @serializer.load(@buffer.tap(&:rewind).read)
  rescue TypeError, ArgumentError => e
    ##
    # Handle a rare serialization failure that can sometimes occur
    # when running readme_examples/advanced/3_parallel_read_write.rb.
    # One retry is usually enough to fix it.
    raise(e) if retry_count > 3
    retry_count += 1
    retry
  ensure
    @buffer.flock(File::LOCK_UN)
  end

  def write(buffer, bytes_written: 0, bytes_read: 0)
    @buffer.flock(File::LOCK_SH)
    buffer[:bytes_written] += bytes_written
    buffer[:bytes_read] += bytes_read
    @buffer.tap(&:rewind).write(@serializer.dump(buffer))
  ensure
    @buffer.flock(File::LOCK_UN)
  end
end
