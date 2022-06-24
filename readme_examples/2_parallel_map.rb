require "xchan"

def p_map(enum)
  ch = xchan
  enum.map
      .with_index { |e, i| fork { sleep(e); ch.send yield([e * 2, i]) } }
      .each { Process.wait(_1) }
  enum.map  { ch.recv }
      .sort { _1.pop  }
      .map  { _1[0]   }
end

t = Time.now
print p_map([3, 2, 1]) { _1 * 2 }, "\n"
print "Duration: #{Time.now - t}", "\n"

# == Output
# [6, 4, 2]
# Duration: 3.00XXX
