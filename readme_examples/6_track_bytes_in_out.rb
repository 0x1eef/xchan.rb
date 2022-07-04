require_relative "setup"
require "xchan"

ch = xchan(:marshal)
ch.send %w[0x1eef]
print "Bytes written: ", ch.bytes_written, "\n"
ch.recv
print "Bytes read: ", ch.bytes_read, "\n"
