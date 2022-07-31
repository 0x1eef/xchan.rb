# frozen_string_literal: true

require_relative "../setup"
require "xchan"

ch = xchan
3.times do |i|
  Process.wait fork { ch.send([i]) }
end
3.times do
  print "channel size: ", ch.size, "\n"
  print "read: ", ch.recv, "\n"
end
print "channel size: ", ch.size, "\n"
ch.close
