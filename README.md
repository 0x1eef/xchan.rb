## About

xchan.rb is an easy to use library that provides a channel for
InterProcess Communication (IPC) between a parent Ruby process,
and its child processes. The channel is implemented through both
serialization, and an unbound unix socket.

## Examples

### Serialization

#### Options

When a channel is written to or read from, a Ruby object is serialized
(on write) or deserialized (on read). The default serializers are available as
`xchan(:marshal)`, `xchan(:json)`, and `xchan(:yaml)`. For scenarios where it
is preferred to send and receive plain strings, the "plain" serializer is
available as `xchan(:plain)`. The following example uses
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

The `ch.recv` method performs a blocking read. A read can block when
a lock is held by another process, or when a read from the underlying
socket blocks. This example performs a read that blocks in a child
process until the parent process writes to the channel:

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

The non-blocking counterpart to `#recv` is `#recv_nonblock`. The `#recv_nonblock`
method raises `Chan::WaitLockable` when a read blocks because of a lock held by
another process, and the method raises `Chan::WaitReadable` when a read on the
underlying socket blocks. This example performs a read that will
raise `Chan::WaitReadable`:

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

The `ch.send` method performs a blocking write. A write can block when a lock
is held by another process, or when a write to the underlying socket blocks.
This example performs a write that will block when the send buffer becomes full:

```ruby
require "xchan"

ch = xchan(:marshal, socket: Socket::SOCK_STREAM)
sndbuf = ch.getsockopt(:reader, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  ch.send(1)
end
```

#### `#send_nonblock`

The non-blocking counterpart to `#send` is `#send_nonblock`. The `#send_nonblock`
method raises `Chan::WaitLockable` when a write blocks because of a lock held
by another process, and the method raises `Chan::WaitReadable` when a write to
the underlying socket blocks. This example builds on the previous example by
freeing space on the send buffer when a write is found to block:

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

ch = xchan(:marshal, socket: Socket::SOCK_STREAM)
sndbuf = ch.getsockopt(:writer, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
while ch.bytes_sent <= sndbuf.int
  send_nonblock(ch, 1)
end

##
# Blocked - free send buffer
```

### Socket

#### Types

A channel can be created with one of three sockets types:

* `Socket::SOCK_DGRAM`
* `Socket::SOCK_STREAM`
* `Socket::SOCK_SEQPACKET`

The default is `Socket::SOCK_DGRAM` because its default settings
provide the most buffer space. The socket type can be specified as
a keyword argument:

```ruby
require "xchan"
ch = xchan(:marshal, socket: Socket::SOCK_STREAM)
```

#### Options

A channel is composed of two sockets, one for reading and the other for writing.
Socket options can be read and set on either of the two sockets with the
`Chan::UNIXSocket#getsockopt`, and `Chan::UNIXSocket#setsockopt` methods.
Apart from the first argument (`:reader`, or `:writer`) the rest of the arguments
are identical to `Socket#{getsockopt,setsockopt}`. The following example has been
run on OpenBSD, the results might be different on other operating systems:

```ruby
require "xchan"
ch = xchan(:marshal)

##
# Print the value of SO_RCVBUF
rcvbuf = ch.getsockopt(:reader, Socket::SOL_SOCKET, Socket::SO_RCVBUF)
print "The read buffer can contain a maximum of: ", rcvbuf.int, " bytes.\n"

##
# Print the value of SO_SNDBUF
sndbuf = ch.getsockopt(:writer, Socket::SOL_SOCKET, Socket::SO_SNDBUF)
print "The maximum size of a single message is: ", sndbuf.int, " bytes.\n"

##
# The read buffer can contain a maximum of: 16384 bytes.
# The maximum size of a single message is: 2048 bytes.
```

### Temporary files

#### tmpdir

A single channel creates three temporary files that are removed
from the filesystem as soon as they are created. By default the
files are stored - for a very short time - in `Dir.tmpdir`. Read
and write permissions are reserved for the process that created
them, inclusive of its child processes.

The parent directory of the temporary files can be changed with the
`tmpdir` keyword argument:

```ruby
require "xchan"
ch = xchan(:marshal, tmpdir: Dir.home)
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
gem "xchan.rb", github: "0x1eef/xchan.rb", tag: "v0.16.3"
gem "lockf.rb", github: "0x1eef/lockf.rb", tag: "v0.10.6"
```

## <a id="license"> License </a>

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/).
<br>
See [LICENSE](./LICENSE).
