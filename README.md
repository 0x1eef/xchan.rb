# xchannel.rb

1. <a href="#introduction">Introduction</a>
2. <a href="#examples">Examples</a>
3. <a href="#requirements">Requirements</a>
4. <a href="#install">Install</a>
5. <a href="#license">License</a>
6. <a href="#changelog">Changelog</a>

## <a id="introduction">Introduction</a>

xchannel.rb is an easy to use library for sharing Ruby objects between Ruby
processes who have a parent-child relationship. It is implemented by serializing
a Ruby object and then writing the serialized data to a unix socket. On the other
side of the unix socket, in another process the serialized data is transformed
back to a Ruby object.

## <a id="examples">Examples</a>

__1.__

The examples mostly explain themselves because they are simple. The first argument given
to `XChannel.from_unix_socket` is a serializer, it is a required argument, and it can be any
object that implements the `dump` and `load` methods. If you are unsure about what
serializer to use, use `Marshal`, because it can serialize the most Ruby objects.

```ruby
ch = XChannel.from_unix_socket Marshal
Process.wait fork { ch.send "Hi dad!" }
puts ch.recv
Process.wait fork { ch.send "Bye dad!" }
puts ch.recv
ch.close
```

__2.__

The second example is similar to the first except it uses `JSON` to serialize objects.
You could also use YAML or MessagePack as serializers.

```ruby
require 'json'
ch = XChannel.from_unix_socket JSON
Process.wait fork { ch.send "Hi mom!" }
puts ch.recv
ch.close
```

__3.__

The third example sends a message from the parent process to the child process,
unlike the other examples that have sent a message from the child process to the
parent process.

```ruby
ch = XChannel.from_unix_socket Marshal
pid = fork { puts ch.recv }
ch.send "Hi son!"
ch.close
Process.wait(pid)
```

__4.__

The fourth example demos how messages are queued until read.

```ru
ch = XChannel.from_unix_socket Marshal
ch.send 'h'
ch.send 'i'
Process.wait fork {
  msg = ''
  msg << ch.recv
  msg << ch.recv
  puts msg
}
ch.close
```

## <a id="requirements"> Requirements </a>

xchannel doesn't depend on libraries outside Ruby's standard library.
Ruby2 or later is recommended. Earlier versions _might_ work.

## <a id="install">Install</a>

As a RubyGem:

    gem install xchannel.rb

As a bundled gem, in your Gemfile:

```ruby
gem "xchannel.rb", "~> 2.0"
```

## <a id="license"> License </a>

This project uses the MIT license, see [LICENSE.txt](./LICENSE.txt) for details.


## <a id="changelog">Changelog</a>

* __v2.0.0__

  * Rename `XChannel.unix()` to `XChannel.from_unix_socket()`.
  * Improve README and API documentation.

* __v1.0.0__

  * First stable release.
