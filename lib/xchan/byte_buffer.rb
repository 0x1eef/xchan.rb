##
# The ByteBuffer class is responsible for storing the number
# of bytes used to store each object written to a channel,
# which in turn is used when reading an object from a channel.
class XChan::ByteBuffer
  require 'tempfile'

  ##
  # @return [XChan::Buffer]
  def initialize
    @serializer = Marshal
    @buffer = Tempfile.new('xchan').tap(&:unlink)
    write([])
  end

  ##
  # @param [Integer] byte_size
  #  The number of bytes written to a channel.
  #
  # @return [void]
  def push(byte_size)
    buffer = read
    buffer.push(byte_size)
    byte_size.tap { write(buffer) }
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes stored for an object
  #  written to a channel.
  def shift
    buffer = read
    buffer.shift.tap { write(buffer) }
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
    retry_count = 1
    @buffer.flock(File::LOCK_SH)
    buffer = @serializer.load(@buffer.tap(&:rewind).read)
    @buffer.flock(File::LOCK_UN)
    buffer
  rescue TypeError, ArgumentError => e
    ##
    # Handle a rare serialization failure that can sometimes occur
    # when running readme_examples/advanced/3_parallel_read_write.rb.
    # One retry is usually enough to fix it.
    raise(e) if retry_count > 3
    retry_count += 1
    retry
  end

  def write(buffer)
    @buffer.flock(File::LOCK_SH)
    buffer = @buffer.tap(&:rewind).write(@serializer.dump(buffer))
    @buffer.flock(File::LOCK_UN)
    buffer
  end
end
