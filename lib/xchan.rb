module XChan
  TimeoutError = Class.new(StandardError)
  require_relative "xchan/unix_socket"

  #
  # @param
  #   (see UNIXSocket#initialize).
  #
  # @return
  #   (see UNIXSocket#initialize)
  #
  def self.from_unix_socket(serializer)
    UNIXSocket.new(serializer)
  end
end
