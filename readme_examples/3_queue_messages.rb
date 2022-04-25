require_relative "setup"
require "xchan"

ch = xchan(:marshal)
Process.wait fork {
  print "Queueing messages (from child process)\n"
  ch.send(1)
  ch.send(2)
  ch.send(3)
}
3.times { print "Received (parent process): ", ch.recv, "\n" }
ch.close
