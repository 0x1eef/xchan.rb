require "xchan"
ch = xchan
pid = fork do
  sleep 3
  ch.send(1)
  ch.send(2)
end
print "Received message: ", ch.recv, "\n"
print "Received message: ", ch.recv, "\n"
ch.close
Process.wait(pid)
