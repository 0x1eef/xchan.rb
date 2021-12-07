# xchan.rb

xchan.rb is a small library that implements a channel on top of a UNIXSocket,
where Ruby objects can be easily sent between parent and child Ruby processes.
  
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

**Queue messages for a parent process**

This example forks a child process, sleeps for a short period, then 
writes two messages to the channel. While the child process is sleeping,
the parent process continues and calls "ch.recv". This method blocks until
the child process wakes up and sends a message to the channel, at which time 
the parent process receives two messages from the channel.

```ruby
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
```

**Tracking bytes in, bytes out**

This example demonstrates how the number of bytes read and written to a channel
can be tracked by using the "#bytes_written" and "#bytes_read" methods.

```ruby
require "xchan"

ch = xchan
ch.send %w(0x1eef)
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
