## About

xchan.rb is an easy to use library for InterProcess Communication (IPC). The
library provides a channel that can send Ruby objects between Ruby processes
who have a parent &lt;=&gt; child relationship.

The channel is implemented with an unnamed
<code><a href=https://rubydoc.info/stdlib/socket/UNIXSocket.pair>UNIXSocket</a></code>,
and serialization. There are multiple serializers to choose from.
[`Marshal`](https://www.rubydoc.info/stdlib/core/Marshal)
is the default. Safety from race conditions is provided by an advisory lock that
allows only one process to read from, or write to a channel at a given time.

## Examples

### Serialization

#### Options

When a channel is written to or read from, a Ruby object is serialized (on write)
or deserialized (on read). There are a number of serializers to choose from:
`xchan(:marshal)`, `xchan(:json)`,  and `xchan(:yaml)`. The example uses
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

The `ch.recv` method performs a read that can block. A read might block because
of a lock held by another process, or because a read from the underlying UNIX socket
would block. The example performs a read that blocks in a child process until the
parent process writes to the channel:

```ruby
require "xchan"

ch = xchan
pid = fork do
  print "Received a random number (child process): ", ch.recv, "\n"
end
# Delay for a second to let a process fork, and call "ch.recv"
sleep(1)
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
Process.wait(pid)
ch.close

##
# Send a random number (from parent process)
# Received random number (child process): XX
```

#### `#recv_nonblock`

The non-blocking counterpart to `#recv` is `#recv_nonblock`. The `#recv_nonblock` method
raises `Chan::WaitReadable` when a read from the underlying UNIX socket would block, and
it raises `Chan::WaitLockable` when a read would block because of a lock held by another
process. The example performs a read that will raise `Chan::WaitReadable`:

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

The `#send` method performs a blocking write. The `#send` method might block when a
channel's send buffer is full, or when a lock is held by another process. The
example performs a write that will block when the send buffer becomes full:


```ruby
require "xchan"

ch = xchan
500.times { ch.send("a" * 500) }
```

#### `#send_nonblock`

The non-blocking counterpart to `#send` is `#send_nonblock`. The `#send_nonblock`
method raises `Chan::WaitWritable` when a write to the underlying UNIX socket would block,
and it raises `Chan::WaitLockable` when a lock held by another process. The example
builds on the last example by freeing space on the send buffer when a write is found
to block:

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

#### FIFO

The order in which messages are read from a channel follows
[First In, First out (FIFO)](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics)).
The example reads messages in the order they were sent (1 first, then 2, and finally 3):

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

## Sources

* [Source code (GitHub)](https://github.com/0x1eef/xchan.rb#readme)
* [Source code (GitLab)](https://gitlab.com/0x1eef/xchan.rb#about)

## Install

xchan.rb is distributed as a RubyGem through its git repositories. <br>
[GitHub](https://github.com/0x1eef/xchan.rb),
and
[GitLab](https://gitlab.com/0x1eef/xchan.rb)
are available as sources.

**Gemfile**

```ruby
gem "xchan.rb", github: "0x1eef/xchan.rb", tag: "v0.9.13"
gem "lockf.rb", github: "0x1eef/lockf.rb", tag: "v0.5.1"
```

## <a id="license"> License </a>

This project is released under the terms of the MIT license. <br>
See [LICENSE.txt](./LICENSE.txt) for details.
