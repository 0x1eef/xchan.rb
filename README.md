# xchan.rb

xchan.rb is a small library that implements a channel through 
serialization and [`UNIXSocket.pair`](https://www.rubydoc.info/stdlib/socket/UNIXSocket.pair).
An xchan.rb channel allows for easily sending Ruby objects between parent and child Ruby processes.

## Demo

**Choose a serializer**

xchan.rb relies on serialization when writing and reading from 
a channel. By default the ["Marshal"](https://www.rubydoc.info/stdlib/core/Marshal)
module is used for serialization - multiple other options exist:

```ruby
require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan 
ch.send({msg: "Serialized by Marshal"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel uses JSON to serialize objects.
require "json"
ch = xchan(JSON)
ch.send({msg: "Serialized by JSON"})
Process.wait fork { print "Received message: ", ch.recv["msg"], "\n" }
ch.close

##
# This channel uses YAML to serialize objects.
require "yaml"
ch = xchan(YAML)
ch.send({msg: "Serialized by YAML"})
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close
```

**Send a message to a child process**

This example shows how to send a message from the parent process 
to a child process. Note that in this example, "ch.recv" performs 
a blocking read that blocks until there is a message to read.

```ruby
require "xchan"

ch = xchan
pid = fork do
  print "Received magic number (child process): ", ch.recv, "\n"
end
print "Sending a magic number (from parent process)\n"
ch.send(rand(21))
Process.wait(pid)
ch.close
```

**Queue messages for a parent process**

This example shows how a channel can queue messages that 
can later be read one by one. The order in which the messages 
are read from the channel follows the 
[First In, First out (FIFO)](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))
methodology. In other words this example will read messages in the 
order they were sent: 1 first, then 2, and finally 3.  

```ruby
require "xchan"

ch = xchan
Process.wait fork {
  print "Queueing messages (from child process)\n"
  ch.send(1)
  ch.send(2)
  ch.send(3)
}
3.times { print "Received (parent process): ", ch.recv, "\n" }
ch.close
```


**Track bytes in, bytes out**

This example shows how the number of bytes read from and written to 
a channel can be tracked using the "#bytes_written" and "#bytes_read" 
methods.

```ruby
require "xchan"

ch = xchan
ch.send %w[0x1eef]
print "Bytes written: ", ch.bytes_written, "\n"
ch.recv
print "Bytes read: ", ch.bytes_read, "\n"
```

## Further reading

* [API docs: rubydoc.info/gems/xchan.rb (gem)](https://rubydoc.info/gems/xchan.rb)
* [API docs: rubydoc.info/github/0x1eef/xchan.rb/master (git)](https://rubydoc.info/github/0x1eef/xchan.rb/master)


## Install

xchan.rb is available as a RubyGem:

    gem install xchan.rb

## <a id="license"> License </a>

The MIT license, see [LICENSE.txt](./LICENSE.txt) for details.
