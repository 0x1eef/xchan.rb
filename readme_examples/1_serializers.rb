require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan
ch.send({msg: "Serialized by Marshal"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel also uses Marshal to serialize objects.
ch = xchan(:marshal)
ch.send({msg: "Serialized by Marshal"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel uses JSON to serialize objects.
ch = xchan(:json)
ch.send({msg: "Serialized by JSON"})
Process.wait fork { print "Received message: ", ch.recv["msg"], "\n" }
ch.close

##
# This channel uses YAML to serialize objects.
ch = xchan(:yaml)
ch.send({msg: "Serialized by YAML"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close
