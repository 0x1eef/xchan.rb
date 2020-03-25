require 'xchan'
ch = xchan Marshal
ch.send 1
ch.send 2
ch.send 3
puts ch.recv_last # => 3
