# xchan.rb

1. <a href="#introduction">Introduction</a>
2. <a href="#examples">Examples</a>
3. <a href="#requirements">Requirements</a>
4. <a href="#install">Install</a>
5. <a href="#license">License</a>
6. <a href="#changelog">Changelog</a>

## <a id="introduction">Introduction</a>

xchan.rb is a small and easy to use library for sharing Ruby objects between
Ruby processes who have a parent-child relationship.

## <a id="examples">Examples</a>

__1.__

Walking through the first example, you can see the first argument given
to `XChan.unix_socket` is a serializer, it is a required argument, and it
can be any object that implements the `dump` and `load` methods. If you are
unsure about what serializer to use, `Marshal` is usually a good choice and
it's available without calling `require`.


```ruby
require 'xchan'
ch = XChan.unix_socket Marshal
Process.wait fork { ch.send "Hi parent" }
puts ch.recv
Process.wait fork { ch.send "Bye parent" }
puts ch.recv
ch.close
```

__2.__

The second example is similar to the first except it uses `JSON` to serialize objects.
You could also use YAML or MessagePack as serializers.

```ruby
require 'xchan'
require 'json'
ch = XChan.unix_socket JSON
Process.wait fork { ch.send "Hi parent" }
puts ch.recv
ch.close
```

__3.__

The third example sends a message from the parent process to the child process,
unlike the other examples that have sent a message from the child process to the
parent process.

```ruby
require 'xchan'
ch = XChan.unix_socket Marshal
pid = fork { puts ch.recv }
ch.send "Hi child"
ch.close
Process.wait(pid)
```

__4.__

The fourth example demos how messages are queued until read.

```ruby
require 'xchan'
ch = XChan.unix_socket Marshal
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

## <a id="install">Install</a>

Gem:

    gem install xchan.rb

Bundler:

```ruby
gem "xchan.rb", "~> 2.0"
```

## <a id="license"> License </a>

This project uses the MIT license, check out [LICENSE.txt](./LICENSE.txt) for
details.

## <a id="changelog">Changelog</a>

* __v0.1.0__

  * Rename `XChan.from_unix_socket` to `XChan.unix_socket`.
  * Rename the project to `xchan.rb` (formerly xchannel.rb), reset version to
    `v0.1.0`.
  * Improvements to the README.
