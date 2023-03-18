# frozen_string_literal: true

require_relative "../setup"
require "xchan"

def read(ch)
  ch.recv_nonblock
rescue Chan::WaitReadable
  print "Wait 1 second for channel to be readable", "\n"
  ch.wait_readable(1)
  retry
rescue Chan::WaitLockable
  sleep 0.01
  retry
end
trap("SIGINT") { exit(1) }
read(xchan)
