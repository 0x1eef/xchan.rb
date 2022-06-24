require "xchan"

def p_map(enum)
  ch = xchan
  enum.map { |e| Process.fork { ch.send yield(e) } }
      .each { Process.wait(_1) }
  enum.map  { ch.recv }
end

p p_map([1,2,3]) { _1 * 2 }
