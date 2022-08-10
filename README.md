## About

xchan.rb is a library for sending Ruby objects
between Ruby processes who have a parent &lt;=&gt; child relationship. The
implementation currently uses an unnamed <code><a href=https://rubydoc.info/stdlib/socket/UNIXSocket.pair>UNIXSocket</a></code>
and offers a number of serialization options - the default is [`Marshal`](https://www.rubydoc.info/stdlib/core/Marshal).

xchan.rb makes a concentrated effort to be safe from race conditions when used across processes
by using a record lock that is implemented on top of fcntl - at any given time, only one process
can hold a lock on a channel and other processes must wait until the lock is released.

## Examples

The examples cover quite a lot - but not everything. The [API documentation](https://0x1eef.github.io/x/xchan.rb)
is available as a complete reference - and covers parts of the interface not
covered by the examples.

### Serialization

#### Available options

When a channel is written to and read from, a Ruby object is serialized (on write)
and deserialized (on read). The form of serialization used can be customized by
the first argument given to `xchan()`. For instance any of the following could be
used: `xchan(:marshal)`, `xchan(:json)`, or `xchan(:yaml)`. The example uses
[`Marshal`](https://www.rubydoc.info/stdlib/core/Marshal):

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
# Received message: serialized by Marshal
# Received message: serialized by Marshal
```

### Read operations

#### `#recv`

The following example demonstrates how to send a Ruby object from a parent process
to a child process. `ch.recv` performs a read that can block - either because a
channel is locked by another process, or because a read from the underlying IO would
block. The example demonstrates a read that blocks until the parent process writes
to the channel:

```ruby
require "xchan"

ch = xchan
pid = fork do
  print "Received a random number (child process): ", ch.recv, "\n"
end
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
Process.wait(pid)
ch.close

##
# Send a random number (from parent process)
# Received random number (child process): XX
```

#### `#recv_nonblock`

The following example demonstrates the non-blocking counterpart to `#recv`:
`#recv_nonblock`. The `#recv_nonblock` method raises `Chan::WaitReadable`
when reading from the underlying IO would block, and it raises `Chan::WaitLockable`
when a read would block because of a lock held by another process:

```ruby
require "xchan"

def read(ch)
  ch.recv_nonblock
rescue Chan::WaitReadable
  print "Wait 1 second for channel to be readable", "\n"
  ch.wait_readable(1)
  retry
rescue Chan::WaitLockable
  sleep 0.01
  retry
end
trap("SIGINT") { exit(1) }
read(xchan)

##
# Wait 1 second for channel to be readable
# Wait 1 second for channel to be readable
# ^C
```

### Write operations

#### `#send`

The following example (and previous examples) introduced the `#send` method -
a method that performs a blocking write. The `#send` method might block when a
channel's send buffer is full, or when a lock is held by another process. The
following example demonstrates a write that will eventually block - due to the send
buffer being full:


```ruby
require "xchan"

ch = xchan
500.times { ch.send("a" * 500) }
```

#### `#send_nonblock`

The following example demonstrates the non-blocking counterpart to
`#send`: `#send_nonblock`. The `#send_nonblock` method raises `Chan::WaitWritable`
when writing to the underlying IO would block, and it raises `Chan::WaitLockable`
when a write would block because of a lock held by another process. The following
example builds upon the last example by freeing space on the send buffer when a write
is found to block:

```ruby
require "xchan"

def send_nonblock(ch, buf)
  ch.send_nonblock(buf)
rescue Chan::WaitWritable
  print "Blocked - free send buffer", "\n"
  ch.recv
  retry
rescue Chan::WaitLockable
  sleep 0.01
  retry
end

ch = xchan
170.times { send_nonblock(ch, "a" * 500) }

##
# Blocked - free send buffer
# Blocked - free send buffer
# Blocked - free send buffer
```

### Queue

#### Queue messages

The following example demonstrates how a channel can queue messages that
can later be read one by one. The order in which the messages
are read from the channel follows the
[First In, First out (FIFO)](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))
methodology. In other words the example will read messages in the
order they were sent: 1 first, then 2, and finally 3:

```ruby
require "xchan"

ch = xchan
Process.wait fork {
  print "Queue messages (from child process)", "\n"
  ch.send(1)
  ch.send(2)
  ch.send(3)
}
3.times { print "Received (parent process): ", ch.recv, "\n" }
ch.close

##
# Queue messages (from child process)
# Received (parent process): 1
# Received (parent process): 2
# Received (parent process): 3
```

### Parallelism

#### Parallel map

The following example demonstrates a method by the name `p_map` -
implemented in 10 LOC - that runs a map operation in parallel.
There is a slight overhead - less than a tenth of a second - for
an operation that would otherwise take 6 seconds to execute sequentially:

```ruby
require "xchan"

def p_map(enum)
  ch = xchan
  enum.map
      .with_index { |e, i| fork { ch.send [yield(e), i] } }
      .each { Process.wait(_1) }
  enum.map { ch.recv }
      .tap { ch.close }
      .sort_by(&:pop)
      .map(&:pop)
end

t = Time.now
print p_map([3, 2, 1]) { |e| sleep(e).then { e * 2 } }, "\n"
print format("Duration: %.2f", Time.now - t), "\n"

##
# == Output
# [6, 4, 2]
# Duration: 3.01
```

## Resources

* [Source code (GitHub)](https://github.com/0x1eef/xchan.rb)
* [Documentation](https://0x1eef.github.io/x/xchan.rb)

## Install

xchan.rb is available as a RubyGem:

    gem install xchan.rb

## <a id="license"> License </a>

This project is released under the terms of the MIT license.
See [LICENSE.txt](./LICENSE.txt) for details.
