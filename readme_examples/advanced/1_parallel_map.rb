require_relative "setup"
require "xchan"

def p_map(enum)
  ch = xchan
  enum.map
      .with_index { |e, i| fork { ch.send [yield(e), i] } }
      .each { Process.wait(_1) }
  enum.map { ch.recv }
      .tap { ch.close }
      .sort_by(&:pop)
      .map(&:pop)
end

t = Time.now
print p_map([3, 2, 1]) { |e| sleep(e); e * 2 }, "\n"
print "Duration: #{Time.now - t}", "\n"

##
# == Output
# [6, 4, 2]
# Duration: 3.00XXX
