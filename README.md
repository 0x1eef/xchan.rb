# xchan.rb

* <a href="#introduction">Introduction</a>
* <a href="#examples">Examples</a>
* <a href="#install">Install</a>
* <a href="#license">License</a>

## <a id="introduction">Introduction</a>

xchan.rb is a small and easy to use library for sharing Ruby objects between
Ruby processes who have a parent-child relationship.

## <a id="examples">Examples</a>

__1.__

The first example introduces you to the `xchan` method, it is implemented as
`Object#xchan` and returns an instance of `XChan::UNIXSocket`. The first argument
to `xchan` is an object that can serialize Ruby objects, in this case `Marshal`,
it could also be `YAML`, `JSON`, `MessagePack`, and any other object that
serializes Ruby objects through the `dump` and `load` methods:

```ruby
require 'xchan'
ch = xchan Marshal
Process.wait fork {
  ch.send "Hi parent"
  ch.send "Bye parent"
}
puts ch.recv
puts ch.recv
ch.close
```

__2.__

The following example sends a message from the parent process to the child process,
unlike the first example that sent messages from the child process to the
parent process:

```ruby
require 'xchan'
ch = xchan Marshal
pid = fork { puts ch.recv }
ch.send "Hi child"
Process.wait(pid)
ch.close
```

__3.__

The following example demonstrates how to send and receive messages within a
0.5 second timeout, using the `#timed_send` and `#timed_recv` methods.
`nil` is returned when either method times out:

```ruby
require 'xchan'
ch = xchan Marshal
ch.timed_send("Hello parent", 0.5) ? puts("message sent") : puts("send timed out")
(message = ch.timed_recv 0.5) ? puts(message) : puts("read timed out")
ch.close
```

__`examples/` directory__

The [examples/](examples/) directory contains the above examples, to run them:

    ruby -Ilib examples/example_X.rb

## <a id="install">Install</a>

Rubygems:

    gem install xchan.rb

Bundler:

```ruby
gem "xchan.rb", "~> 0.2.0"
```

## <a id="license"> License </a>

The MIT license, check out [LICENSE.txt](./LICENSE.txt) for details.
