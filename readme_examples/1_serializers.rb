require_relative "setup"
require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan
ch.send(msg: "serialized by Marshal")
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel also uses Marshal to serialize objects.
ch = xchan(:marshal)
ch.send(msg: "serialized by Marshal")
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# == Output
# Received message: serialized by Marshal
# Received message: serialized by Marshal
