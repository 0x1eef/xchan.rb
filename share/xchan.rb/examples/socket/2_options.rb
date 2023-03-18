require "xchan"
ch = xchan(:marshal)

##
# Print the value of SO_RCVBUF
rcvbuf = ch.getsockopt(:reader, Socket::SOL_SOCKET, Socket::SO_RCVBUF)
print "The read buffer can contain a maximum of: ", rcvbuf.int, " bytes.\n"

##
# Print the value of SO_SNDBUF
sndbuf = ch.getsockopt(:writer, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
print "The maximum size of a single message is: ", sndbuf.int, " bytes.\n"
