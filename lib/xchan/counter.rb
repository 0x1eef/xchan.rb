# frozen_string_literal: true

##
# {Chan::Counter Chan::Counter} provides a counter
# for the number of written and received bytes on a
# given channel.
class Chan::Counter
  require "json"

  ##
  # @param [String] tmpdir
  #  Directory where temporary files are stored
  #
  # @return [Chan::Counter]
  def initialize(tmpdir)
    @io = Chan.temporary_file("xchan.counter", tmpdir:)
    write(@io, {"bytes_read" => 0, "bytes_written" => 0})
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes written to a channel
  def bytes_written
    read(@io).fetch("bytes_written")
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes read from a channel
  def bytes_read
    read(@io).fetch("bytes_read")
  end

  ##
  # @param [Hash] new_stat
  # @return [void]
  # @private
  def increment!(new_stat)
    stat = read(@io)
    new_stat.each { stat[_1.to_s] += _2 }
    write(@io, stat)
  end

  private

  def write(io, o)
    io.truncate(0)
    io.write(serialize(o)).tap { io.rewind }
  end

  def read(io)
    deserialize(io.read).tap { io.rewind }
  end

  def serialize(bytes)
    JSON.dump(bytes)
  end

  def deserialize(bytes)
    JSON.load(bytes)
  end
end
