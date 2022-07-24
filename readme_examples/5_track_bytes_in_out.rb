# frozen_string_literal: true

require_relative "setup"
require "xchan"

ch = xchan
Process.wait fork { ch.send %w[0x1eef] }
print "Bytes written: ", ch.bytes_written, "\n"
Process.wait fork { ch.recv }
print "Bytes read: ", ch.bytes_read, "\n"
ch.close
