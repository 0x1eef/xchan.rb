## About

xchan.rb is an easy to use library for InterProcess
Communication (IPC). The library provides a channel
that can transfer Ruby objects between Ruby processes
with a parent <-> child relationship.

## Examples

### Serialization

#### Options

When a channel is written to or read from, a Ruby object
is serialized (on write) or deserialized (on read). The
default serializers are available as `xchan(:marshal)`,
`xchan(:json)`, and `xchan(:yaml)`.

For situations where it is preferred to send and receive
plain strings, the "plain" serializer is available as
`xchan(:plain)`. The example uses
[`Marshal`](https://www.rubydoc.info/stdlib/core/Marshal):

```ruby
require "xchan"

##
# This channel uses Marshal to serialize objects.
ch = xchan
pid = fork { print "Received message: ", ch.recv[:msg], "\n" }
ch.send(msg: "serialized by Marshal")
ch.close
Process.wait(pid)

##
# This channel also uses Marshal to serialize objects.
ch = xchan(:marshal)
pid = fork { print "Received message: ", ch.recv[:msg], "\n"
ch.send(msg: "serialized by Marshal")
ch.close
Process.wait(pid)

##
# Received message: serialized by Marshal
# Received message: serialized by Marshal
```

### Read operations

#### `#recv`

The `ch.recv` method performs a blocking read. A read
can block when a lock is held by another process, or
when a read from
[Chan::UNIXSocket#r](https://0x1eef.github,io/x/xchan.rb/Chan/UNIXSocket.html#r-instance_method)
blocks. The example performs a read that blocks until
the parent process writes to the channel:

```ruby
require "xchan"

ch = xchan
Process.detach fork {
  print "Received a random number (child process): ", ch.recv, "\n"
}
sleep(1)
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
ch.close

##
# Send a random number (from parent process)
# Received random number (child process): XX
```

#### `#recv_nonblock`

The non-blocking counterpart to `#recv` is `#recv_nonblock`.
The `#recv_nonblock` method raises `Chan::WaitLockable` when
a read blocks because of a lock held by another process, and
the method raises `Chan::WaitReadable` when a read from
[Chan::UNIXSocket#r](https://0x1eef.github,io/x/xchan.rb/Chan/UNIXSocket.html#r-instance_method)
blocks:

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

The `ch.send` method performs a blocking write.
A write can block when a lock is held by another
process, or when a write to
[Chan::UNIXSocket#w](https://0x1eef.github,io/x/xchan.rb/Chan/UNIXSocket.html#w-instance_method)
blocks. The example fills the send buffer:

```ruby
require "xchan"

ch = xchan(:marshal, sock_type: Socket::SOCK_STREAM)
sndbuf = ch.getsockopt(:reader, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  ch.send(1)
end
```

#### `#send_nonblock`

The non-blocking counterpart to `#send` is
`#send_nonblock`. The `#send_nonblock` method raises
`Chan::WaitLockable` when a write blocks because of
a lock held by another process, and the method raises
`Chan::WaitWritable` when a write to
[Chan::UNIXSocket#w](https://0x1eef.github,io/x/xchan.rb/Chan/UNIXSocket.html#w-instance_method)
blocks. The example frees space on the send buffer:

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

ch = xchan(:marshal, sock_type: Socket::SOCK_STREAM)
sndbuf = ch.getsockopt(:writer, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  send_nonblock(ch, 1)
end

##
# Blocked - free send buffer
```

### Socket

#### Options

A channel has one socket for read operations and another
socket for write operations.
[Chan::UNIXSocket#r](https://0x1eef.github,io/x/xchan.rb/Chan/UNIXSocket.html#r-instance_method)
returns the socket used for read operations, and
[Chan::UNIXSocket#w](https://0x1eef.github,io/x/xchan.rb/Chan/UNIXSocket.html#w-instance_method)
returns the socket used for write operations:

```ruby
require "xchan"
ch = xchan(:marshal)

##
# Print the value of SO_RCVBUF
rcvbuf = ch.r.getsockopt(Socket::SOL_SOCKET, Socket::SO_RCVBUF)
print "The read buffer can contain a maximum of: ", rcvbuf.int, " bytes.\n"

##
# Print the value of SO_SNDBUF
sndbuf = ch.w.getsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF)
print "The maximum size of a single message is: ", sndbuf.int, " bytes.\n"

##
# The read buffer can contain a maximum of: 16384 bytes.
# The maximum size of a single message is: 2048 bytes.
```

## Documentation

A complete API reference is available at
[0x1eef.github.io/x/xchan.rb](https://0x1eef.github.io/x/xchan.rb/).

## Install

xchan.rb can be installed via rubygems.org:

    gem install xchan.rb

## Sources

* [Source code (GitHub)](https://github.com/0x1eef/xchan.rb#readme)
* [Source code (GitLab)](https://gitlab.com/0x1eef/xchan.rb#about)

## <a id="license"> License </a>

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/).
<br>
See [LICENSE](./LICENSE).
