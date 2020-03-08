#
# Example that demonstrates sending and receiving messages with a time out.
require 'xchan'

ch = xchan Marshal
if ! ch.timed_send("Hello parent", 0.5)
  # handle time out
end
if message = ch.timed_recv(0.5)
  puts message
else
  # handle time out
end
ch.close
