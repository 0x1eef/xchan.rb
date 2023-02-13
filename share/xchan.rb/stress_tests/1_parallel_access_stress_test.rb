# frozen_string_literal: true

require_relative "../setup"
require "xchan"

pids = []
ch = xchan
pids.concat 50.times.map { fork { ch.send(["a" * rand(200)]) } }
pids.concat 50.times.map { fork { print "PID: ", Process.pid, ", buf size:", ch.recv[0].size, "\n" } }
pids.each { Process.wait(_1) }
