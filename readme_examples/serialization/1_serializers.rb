# frozen_string_literal: true

require_relative "../setup"
require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan
pid = fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.send(msg: "serialized by Marshal")
ch.close
Process.wait(pid)

##
# This channel also uses Marshal to serialize objects.
ch = xchan(:marshal)
pid = fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.send(msg: "serialized by Marshal")
ch.close
Process.wait(pid)
