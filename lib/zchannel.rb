module XChannel
  TimeoutError = Class.new(StandardError)
  require_relative "XChannel/unix_socket"

  #
  # @param
  #   (see UNIXSocket#initialize).
  #
  # @return
  #   (see UNIXSocket#initialize)
  #
  def self.unix(serializer)
    UNIXSocket.new(serializer)
  end
end
