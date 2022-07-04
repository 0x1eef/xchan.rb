require_relative "setup"
require "xchan"

ch = xchan
1.upto(5) { ch.send(_1) }
print "read from populated channel ", ch.to_a, "\n"
print "read from empty channel ", " " * 4, ch.to_a, "\n"
