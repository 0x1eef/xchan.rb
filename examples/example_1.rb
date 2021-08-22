require "xchan"
ch = xchan
Process.wait fork {
  ch.send({message: 1})
  ch.send({message: 2})
}
print "Received message: ", ch.recv, "\n"
print "Received message: ", ch.recv, "\n"
ch.close
