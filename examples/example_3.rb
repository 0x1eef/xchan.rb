require "xchan"
ch = xchan
ch.send "foo"
ch.send "bar"
ch.send "foobar"
print "Last written message: ", ch.recv_last, "\n"
ch.close
