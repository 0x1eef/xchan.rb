# frozen_string_literal: true

require_relative "../setup"
require "xchan"

$stdout.sync = true
ch = xchan
Process.detach fork {
  print "Received random number (child process): ", ch.recv, "\n"
}
sleep(1)
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
ch.close

##
# Send a random number (from parent process)
# Received random number (child process): XX
