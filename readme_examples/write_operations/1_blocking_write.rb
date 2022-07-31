# frozen_string_literal: true

require_relative "../setup"
require "xchan"

ch = xchan
500.times { ch.send("a" * 500) }
