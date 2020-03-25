require 'xchan'
ch = xchan Marshal
ch.send "ab"
ch.send "abc"
ch.send "abcd"
puts ch.recv_last # => "abcd"
