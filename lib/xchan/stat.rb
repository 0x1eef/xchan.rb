##
# The {Chan::Stat Chan::Stat} class provides statistics
# (eg number of bytes read, number of bytes written) for
# a given channel.
class Chan::Stat
  require "tempfile"
  require "json"

  ##
  # @param tmp_dir (see Chan::UNIXSocket#initialize)
  # @return [Chan::Stat]
  def initialize(tmp_dir)
    @serializer = JSON
    @io = Tempfile.new("xchan-stat", tmp_dir).tap(&:unlink)
    write(@io, {"bytes_read" => 0, "bytes_written" => 0})
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes written to a channel.
  def bytes_written
    read(@io).fetch("bytes_written")
  end

  ##
  # @return [Integer]
  #  Returns the number of bytes read from a channel.
  def bytes_read
    read(@io).fetch("bytes_read")
  end

  ##
  # @param [Hash] new_stat
  # @return [void]
  # @private
  def store(new_stat)
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
    @serializer.dump(bytes)
  end

  def deserialize(bytes)
    @serializer.load(bytes)
  end
end
