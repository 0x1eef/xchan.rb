#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../setup"
require "xchan"

##
# Marshal as the serializer
ch = xchan(:marshal)
Process.wait fork { ch.send(5) }
print "#{ch.recv} + 7 = 12", "\n"
ch.close

##
# 5 + 7 = 12
