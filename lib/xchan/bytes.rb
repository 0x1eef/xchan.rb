# frozen_string_literal: true

##
# The {Chan::Bytes Chan::Bytes} class is similar
# to an array, where each element represents the
# number of bytes used to store an object on a
# channel. When an object is written to a channel,
# the array increases in size, and when an object
# is read from a channel, the array decreases in
# size.
class Chan::Bytes
  require "json"
  require_relative "stat"

  ##
  # @return [Chan::Stat]
  attr_reader :stat

  ##
  # @param [String] tmpdir
  #  Path to a directory where temporary files will be stored.
  #
  # @return [Chan::Bytes]
  def initialize(tmpdir)
    @serializer = JSON
    @io = Chan.temporary_file("xchan.bytes", tmpdir:)
    @io.sync = true
    @stat = Chan::Stat.new(tmpdir)
    write(@io, [])
  end

  ##
  # Insert a byte count at the head of the array
  #
  # @param [Integer] len
  #  Number of bytes
  #
  # @return [void]
  def unshift(len)
    return 0 if len.nil? || len.zero?
    bytes = read(@io)
    bytes.unshift(len)
    write(@io, bytes)
    @stat.store(bytes_written: len)
    len
  end

  ##
  # Insert a byte count at the tail of the array
  #
  # @param [Integer] len
  #  Number of bytes
  #
  # @return [void]
  def push(len)
    return 0 if len.nil? || len.zero?
    bytes = read(@io)
    bytes.push(len)
    write(@io, bytes)
    @stat.store(bytes_written: len)
    len
  end

  ##
  # @return [Integer]
  #  Returns (and removes) a byte count from the head of the array
  def shift
    bytes = read(@io)
    return 0 if bytes.size.zero?
    len = bytes.shift
    write(@io, bytes)
    @stat.store(bytes_read: len)
    len
  end

  ##
  # @return [Integer]
  #  Returns the size of the array
  def size
    read(@io).size
  end

  ##
  # Close the underlying IO
  #
  # @return [void]
  def close
    @io.close
  end

  private

  def read(io)
    deserialize(io.read).tap { io.rewind }
  end

  def write(io, bytes)
    io.truncate(0)
    io.write(serialize(bytes)).tap { io.rewind }
  end

  def serialize(bytes)
    @serializer.dump(bytes)
  end

  def deserialize(bytes)
    @serializer.load(bytes)
  end
end
