#
# Example that demonstrates sending and receiving messages with a time out.

require 'xchan'

ch = xchan Marshal
Process.wait fork {
  # timed_send will return `nil` when it times out.
  if ! ch.timed_send("Hello parent", 0.5)
    # handle time out
  end
}

# timed_recv will return `nil` when it times out.
message = ch.timed_recv(0.5)
if message
  puts message
else
  # handle time out
end

ch.close
