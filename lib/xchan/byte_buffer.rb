# frozen_string_literal: true

##
# The {Chan::ByteBuffer} class is responsible for tracking the
# number of bytes used to store each object written to a channel.
# This class also tracks the total number of bytes read from and
# written to a channel. The information tracked by this class is
# utilized when reading an object from a channel.
class Chan::ByteBuffer
  require "tempfile"
  require "json"

  ##
  # @return [Chan::ByteBuffer]
  def initialize
    @serializer = JSON
    @buffer = Tempfile.new("xchan-byte_buffer").tap(&:unlink)
    @buffer.sync = true
    write({"bytes_written" => 0, "bytes_read" => 0, "bytes" => []})
  end

  ##
  # @param [Integer] byte_size
  #  The number of bytes written to a channel.
  #
  # @return [void]
  def push(byte_size)
    buffer = read
    buffer["bytes"].push(byte_size)
    byte_size.tap { write(buffer, bytes_written: _1) }
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes stored for an object
  #  written to a channel.
  def shift
    buffer = read
    buffer["bytes"].shift.tap { write(buffer, bytes_read: _1) }
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to a channel
  def bytes_written
    read["bytes_written"]
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from a channel
  def bytes_read
    read["bytes_read"]
  end

  ##
  # @return [Integer]
  #  Returns the number of objects waiting to be read from a channel
  def size
    read["bytes"].size
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

  def write(buffer, bytes_written: 0, bytes_read: 0)
    buffer["bytes_written"] += bytes_written
    buffer["bytes_read"] += bytes_read
    @buffer.truncate(0)
    @buffer.tap(&:rewind).write(@serializer.dump(buffer))
  end
end
