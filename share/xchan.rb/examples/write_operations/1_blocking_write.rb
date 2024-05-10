# frozen_string_literal: true

require_relative "../setup"
require "xchan"

ch = xchan(:marshal, sock_type: Socket::SOCK_STREAM)
sndbuf = ch.w.getsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  ch.send(1)
end
