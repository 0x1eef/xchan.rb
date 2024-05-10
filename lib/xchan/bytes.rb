# frozen_string_literal: true

##
# {Chan::Bytes Chan::Bytes} represents a collection
# of byte counts for each object stored on a channel.
# When an object is written to a channel, the collection
# increases in size, and when an object is read from
# a channel, the collection decreases in size.
class Chan::Bytes
  require "json"
  require_relative "counter"

  ##
  # @param [String] tmpdir
  #  Directory where temporary files are stored
  #
  # @return [Chan::Bytes]
  def initialize(tmpdir)
    @io = Chan.temporary_file("xchan.bytes", tmpdir:)
    @io.sync = true
    write(@io, [])
  end

  ##
  # Adds a count to the start of the collection
  #
  # @param [Integer] len
  #  The bytesize of an object
  #
  # @return [void]
  def unshift(len)
    return 0 if len.nil? || len.zero?
    bytes = read(@io)
    bytes.unshift(len)
    write(@io, bytes)
    len
  end

  ##
  # Adds a count to the end of the collection
  #
  # @param [Integer] len
  #  The bytesize of an object
  #
  # @return [void]
  def push(len)
    return 0 if len.nil? || len.zero?
    bytes = read(@io)
    bytes.push(len)
    write(@io, bytes)
    len
  end

  ##
  # Removes a count from the start of the collection
  #
  # @return [Integer]
  #  Returns the removed byte count
  def shift
    bytes = read(@io)
    return 0 if bytes.size.zero?
    len = bytes.shift
    write(@io, bytes)
    len
  end

  ##
  # @return [Integer]
  #  Returns the number of objects in the collection
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
    JSON.dump(bytes)
  end

  def deserialize(bytes)
    JSON.load(bytes)
  end
end
