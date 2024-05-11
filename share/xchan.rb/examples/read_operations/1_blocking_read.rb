# frozen_string_literal: true

require_relative "../setup"
require "xchan"

$stdout.sync = true
ch = xchan(:marshal)
fork do
  print "Received random number (child process): ", ch.recv, "\n"
end
sleep(1)
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
ch.close
Process.wait

##
# Send a random number (from parent process)
# Received random number (child process): XX
