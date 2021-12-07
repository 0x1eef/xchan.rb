require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan
ch.send({msg: "Serialized by Marshal"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel uses JSON to serialize objects.
require "json"
ch = xchan(JSON)
ch.send({msg: "Serialized by JSON"})
Process.wait fork { print "Received message: ", ch.recv["msg"], "\n" }
ch.close

##
# This channel uses YAML to serialize objects.
require "yaml"
ch = xchan(YAML)
ch.send({msg: "Serialized by YAML"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close
