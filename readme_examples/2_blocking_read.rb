# frozen_string_literal: true

require_relative "setup"
require "xchan"

ch = xchan
pid = fork do
  print "Received random number (child process): ", ch.recv, "\n"
end
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
Process.wait(pid)
ch.close
