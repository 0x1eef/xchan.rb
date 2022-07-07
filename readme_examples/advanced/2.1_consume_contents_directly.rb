require_relative "../setup"
require "xchan"

ch = xchan
1.upto(5) { ch.send(_1) }
print "Read from populated channel ", ch.to_a, "\n"
print "Read from empty channel ", " " * 4, ch.to_a, "\n"
ch.close
