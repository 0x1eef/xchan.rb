require "xchan"
ch = xchan
2.times { ch.send %w[0x1eef] }
print "Bytes written: ", ch.bytes_written, "\n"
2.times { ch.recv }
print "Bytes read: ", ch.bytes_read, "\n"
