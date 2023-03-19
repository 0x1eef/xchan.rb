# frozen_string_literal: true

require_relative "../setup"
require "xchan"

ch = xchan(:marshal, socket_type: Socket::SOCK_STREAM)
sndbuf = ch.getsockopt(:reader, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  ch.send(1)
end
