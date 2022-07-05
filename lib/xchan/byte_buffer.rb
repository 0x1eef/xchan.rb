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
    @serializer.load(@buffer.tap(&:rewind).read)
  end

  def write(buffer)
    @buffer.tap(&:rewind).write(@serializer.dump(buffer))
  end
end
