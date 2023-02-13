# frozen_string_literal: true

require_relative "../setup"
require "xchan"

ch = xchan
pid = fork do
  print "Received random number (child process): ", ch.recv, "\n"
end
# Delay for a second to let a process fork, and call "ch.recv"
sleep(1)
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
Process.wait(pid)
ch.close
