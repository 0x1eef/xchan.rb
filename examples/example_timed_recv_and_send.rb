#
# Example that demonstrates sending and receiving messages with a time out.

require 'xchan'

def send_ch(ch, message, timeout)
  ch.timed_send message, timeout
rescue XChan::TimeoutError
  # Handle timeout here
end

def recv_ch(ch, timeout)
  ch.timed_recv timeout
rescue XChan::TimeoutError
  # Handle timeout here
end

ch = xchan Marshal
Process.wait fork { send_ch ch, 'Hi parent', 0.5 }
puts recv_ch(ch, 0.5)
ch.close
