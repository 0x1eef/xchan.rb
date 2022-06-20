require_relative "setup"
require "xchan"

ch = xchan(:marshal)
pid = fork do
  print "Received magic number (child process): ", ch.recv, "\n"
end
print "Sending a magic number (from parent process)\n"
ch.send(rand(21))
Process.wait(pid)
ch.close