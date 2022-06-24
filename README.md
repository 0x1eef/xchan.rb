# xchan.rb

xchan.rb is a library for sending Ruby objects
between Ruby processes who have a parent&lt;-&gt;child relationship. The
implementation uses a <code><a href=https://rubydoc.info/stdlib/socket/UNIXSocket.pair>UNIXSocket</a></code>,
and the serialization format of your choice - the default is [`Marshal`](https://www.rubydoc.info/stdlib/core/Marshal).


## Examples

**Serializers**

When a channel is written to and read from, a Ruby object is serialized (on write)
or deserialized (on read). The form of serialization used can be customized, the
example illustrates a few different options:

```ruby
require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan
ch.send(msg: "serialized by Marshal")
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel also uses Marshal to serialize objects.
ch = xchan(:marshal)
ch.send(msg: "serialized by Marshal")
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# This channel uses JSON to serialize objects.
ch = xchan(:json)
ch.send(msg: "serialized by JSON")
Process.wait fork { print "Received message: ", ch.recv["msg"], "\n" }
ch.close

##
# This channel uses YAML to serialize objects.
ch = xchan(:yaml)
ch.send(msg: "serialized by YAML")
Process.wait fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.close

##
# == Output
# Received message: serialized by Marshal
# Received message: serialized by Marshal
# Received message: serialized by JSON
# Received message: serialized by YAML

```

**Parallel map**

The following example demonstrates a short and sweet `p_map` method
that runs a map operation in parallel, with no more than 10 LOC:

```ruby
require "xchan"

def p_map(enum)
  ch = xchan
  enum.map { |e| Process.fork { ch.send yield(e) } }
      .each { Process.wait(_1) }
  enum.map  { ch.recv }
end

Kernel.p p_map([1,2,3]) { _1 * 2 }

##
# == Output
# [2, 4, 6]
```

**Send a Ruby object to a child process**

The following example shows how to send a Ruby object from a parent process
to a child process. `ch.recv` performs a blocking read until an object is sent
to the channel. In the example, the object being sent is an Integer:

```ruby
require "xchan"

ch = xchan(:marshal)
pid = fork do
  print "Received magic number (child process): ", ch.recv, "\n"
end
print "Sending a magic number (from parent process)", "\n"
ch.send(rand(21))
Process.wait(pid)
ch.close

##
# == Output
# Sending a magic number (from parent process)
# Received magic number (child process): XX
```

**Queue messages**

The following example shows how a channel can queue messages that
can later be read one by one. The order in which the messages
are read from the channel follows the
[First In, First out (FIFO)](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))
methodology. In other words the example will read messages in the
order they were sent: 1 first, then 2, and finally 3:

```ruby
require "xchan"

ch = xchan(:marshal)
Process.wait fork {
  print "Queueing messages (from child process)", "\n"
  ch.send(1)
  ch.send(2)
  ch.send(3)
}
3.times { print "Received (parent process): ", ch.recv, "\n" }
ch.close

##
# == Output
# Queueing messages (from child process)
# Received (parent process): 1
# Received (parent process): 2
# Received (parent process): 3
```

**Track bytes in, bytes out**

The following example shows how the number of bytes read from and written to
a channel can be tracked using the `#bytes_written` and `#bytes_read` methods:

```ruby
require "xchan"

ch = xchan(:marshal)
ch.send %w[0x1eef]
print "Bytes written: ", ch.bytes_written, "\n"
ch.recv
print "Bytes read: ", ch.bytes_read, "\n"

##
# == Output
# Bytes written: 25
# Bytes read: 25
```

## Resources

* [Homepage](https://0x1eef.github.io/x/xchan.rb)
* [Source code](https://github.com/0x1eef/xchan.rb)

## Install

xchan.rb is available as a RubyGem:

    gem install xchan.rb

## <a id="license"> License </a>

The MIT license, see [LICENSE.txt](./LICENSE.txt) for details.
