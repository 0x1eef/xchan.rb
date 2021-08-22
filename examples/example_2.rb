require "xchan"
ch = xchan
if ch.timed_send("Hello", 0.5)
  puts "message sent"
else
  puts "send timeout"
end
if (message = ch.timed_recv(0.5))
  puts "got message: #{message}"
else
  puts "read timeout"
end
ch.close
