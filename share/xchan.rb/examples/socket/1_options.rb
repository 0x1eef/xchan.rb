#!/usr/bin/env ruby
# frozen_string_literal: true

require "xchan"
ch = xchan(:marshal)

##
# Print the value of SO_RCVBUF
rcvbuf = ch.r.getsockopt(Socket::SOL_SOCKET, Socket::SO_RCVBUF)
print "The read buffer can contain a maximum of: ", rcvbuf.int, " bytes.\n"

##
# Print the value of SO_SNDBUF
sndbuf = ch.w.getsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF)
print "The maximum size of a single message is: ", sndbuf.int, " bytes.\n"
