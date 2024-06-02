## About

xchan.rb is an easy to use library for InterProcess
Communication (IPC). The library provides a channel
that can transfer Ruby objects between Ruby processes
with a parent &lt;=&gt; child relationship.

## Examples

### Serialization

#### Options

The first argument given to xchan is the serializer
that it should use. A channel that will communicate
in pure strings (ie with no serialization) is
available as `xchan(:pure)`.

Otherwise, when a channel is written to or read from,
a Ruby object is serialized (on write) or deserialized
(on read). The serializers available to choose from
are `xchan(:marshal)`, `xchan(:json)`, and `xchan(:yaml)`.
The example uses
[`Marshal`](https://www.rubydoc.info/stdlib/core/Marshal):

```ruby
require "xchan"

##
# This channel uses Marshal to serialize objects
ch = xchan(:marshal)
Process.wait fork { ch.send(5) }
print "There are ", ch.recv + 7, " disciples and the same number of tribes", "\n"
ch.close

##
# There are 12 disciples and the same number of tribes
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

ch = xchan(:marshal)
fork do
  print "Received a random number (child process): ", ch.recv, "\n"
end
sleep(1)
print "Send a random number (from parent process)", "\n"
ch.send(rand(21))
ch.close
Process.wait

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
read(xchan(:marshal))

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
sndbuf = ch.w.getsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF)
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
sndbuf = ch.w.getsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF)
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
