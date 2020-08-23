# xchan.rb

**Table of contents**

* <a href="#introduction">Introduction</a>
* <a href="#examples">Examples</a>
* <a href="#documentation">Documentation</a>
* <a href="#install">Install</a>
* <a href="#license">License</a>

## <a id="introduction">Introduction</a>

xchan.rb is a small and easy to use library for sharing Ruby objects between
Ruby processes who have a parent-child relationship. Behind the scenes,
xchan.rb is using a UNIX socket.

## <a id="examples">Examples</a>

**#1**

The first example introduces you to the `xchan` method, it is implemented as
`Object#xchan` and returns an instance of `XChan::UNIXSocket`.

The first (optional) argument to `xchan` is an object who can dump an object
to text and from that text create the same object once again in memory. xchan.rb
defaults to `Marshal` without an argument, depending on your needs you could
choose from YAML, JSON, and MessagePack - to name a few.


```ruby
require 'xchan'
ch = xchan
Process.wait fork {
  ch.send "Hi parent"
  ch.send "Bye parent"
}
puts ch.recv
puts ch.recv
ch.close
```

**#2**

The following example demonstrates how to send and receive objects within a
0.5 second timeout, using the `#timed_send` and `#timed_recv` methods.
`nil` is returned when either method times out.

```ruby
require 'xchan'
ch = xchan
ch.timed_send("Hello parent", 0.5) ? puts("message sent") : puts("send timed out")
(message = ch.timed_recv 0.5) ? puts(message) : puts("read timed out")
ch.close
```

**#3**

The following example demonstrates the `#recv_last` method, it reads the last
object written to a channel and discards older writes in the process ("ab" and
"abc" in this example).

```ruby
require 'xchan'
ch = xchan
ch.send "ab"
ch.send "abc"
ch.send "abcd"
puts ch.recv_last # => "abcd"
```

__`examples/` directory__

The [examples/](examples/) directory contains the above examples, try them by running:

    ruby -Ilib examples/example_X.rb

## <a id="documentation">Documentation</a>

API documentation coverage for xchan.rb is at over 60%, and as of this writing all methods
are documented. The documentation is written with [YARD](https://github.com/lsegal/yard).

* [rubydoc.info/gems/xchan.rb](https://rubydoc.info/gems/xchan.rb)


## <a id="install">Install</a>

    gem install xchan.rb

## <a id="license"> License </a>

The MIT license, see [LICENSE.txt](./LICENSE.txt) for details.
