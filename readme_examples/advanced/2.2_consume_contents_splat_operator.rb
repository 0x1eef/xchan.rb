require_relative "../setup"
require "xchan"

def sum(a, b, c, d)
  [a,b,c,d].sum
end

ch = xchan
1.upto(4) { ch.send(_1) }
print "Sum: ", sum(*ch), "\n"
ch.close
