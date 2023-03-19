# frozen_string_literal: true

require_relative "../setup"
require "xchan"

def send_nonblock(ch, buf)
  ch.send_nonblock(buf)
rescue Chan::WaitWritable
  print "Blocked - free send buffer", "\n"
  ch.recv
  retry
rescue Chan::WaitLockable
  sleep 0.01
  retry
end

ch = xchan(:marshal, socket_type: Socket::SOCK_STREAM)
sndbuf = ch.getsockopt(:writer, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  send_nonblock(ch, 1)
end

##
# Blocked - free send buffer
