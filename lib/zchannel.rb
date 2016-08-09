module ZChannel
  TimeoutError = Class.new(StandardError)
  require_relative "zchannel/unix_socket"

  #
  # @param 
  #   (see UNIXSocket#initialize).
  #
  # @return
  #   (see UNIXSocket#initialize)
  #
  def self.unix(serializer = Marshal)
    UNIXSocket.new(serializer)
  end
end
