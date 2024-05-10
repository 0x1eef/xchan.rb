# frozen_string_literal: true

require_relative "../setup"
require "xchan"

##
# This channel uses Marshal to serialize objects
ch = xchan(:marshal)
Process.wait fork { ch.send(5) }
print "There are ", ch.recv + 7, " disciples and the same number of tribes", "\n"
ch.close

##
# There are 12 disciples and the same number of tribes
