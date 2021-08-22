# xchan.rb

**Table of contents**

* <a href="#introduction">Introduction</a>
* <a href="#examples">Examples</a>
* *Documentation*
  * <a href='#limitations'>Docs: Limitations</a>
  * <a href='#kernelsend-xchan'>Docs: `Kernel#send` and xchan.rb</a>
  * <a href="#documentation">Docs: API reference</a>
* <a href="#install">Install</a>
* <a href="#license">License</a>

## <a id="introduction">Introduction</a>

xchan.rb is a light and easy to use InterProcess Communication (IPC) channel for 
sending Ruby objects between Ruby processes who have a parent-child relationship.

## <a id="examples">Examples</a>

**1.**

The `xchan` method is implemented as `Object#xchan` and returns an instance of 
`XChan::UNIXSocket`.

The first (optional) argument to `xchan` is an object who can dump an object
to text and from that text create the same object once again in memory. xchan.rb
defaults to Marshal without an argument. JSON, YAML, and any other serializer that 
implements `#dump` and `#load` could also be used.

Reads with the `#recv` method block until the underlying IO is readable and likewise 
writes with the `#send` method block until the underlying IO is writable.

```ruby
require 'xchan'
ch = xchan
Process.wait fork {
  ch.send({message: 1})
  ch.send({message: 2})
}
print "Received message: ", ch.recv, "\n"
print "Received message: ", ch.recv, "\n"
ch.close
```

**2.**

The `#timed_send` and `#timed_recv` methods can be used to send and receive
objects within a specified timeout. `nil` is returned when either method times out.

```ruby
require 'xchan'
ch = xchan
if ch.timed_send("Hello", 0.5)
  puts "message sent"
else
  puts "send timeout"
end
if (message = ch.timed_recv(0.5))
  puts "got message: #{message}"
else
  puts "read timeout"
end
ch.close
```

**3.**

The `#recv_last` method returns the last object written to the channel and 
discards older writes in the process - `foo` and `bar` in this example.

```ruby
require "xchan"
ch = xchan
ch.send "foo"
ch.send "bar"
ch.send "foobar"
print "Last written message: ", ch.recv_last, "\n"
ch.close
```

**4.**

The total number of bytes written to and read from the channel is tracked by 
the methods `#bytes_written` and `#bytes_read`.

```ruby
require "xchan"
ch = xchan
2.times { ch.send %w(0x1eef) }
print "Bytes written: ", ch.bytes_written, "\n"
2.times { ch.recv }
print "Bytes read: ", ch.bytes_read, "\n"
```

**`examples/` directory**

The [examples/](examples/) directory contains the above examples:

    ruby -Ilib examples/example_X.rb

## <a id='limitations'>Docs: Limitations </a>

Not all objects can be written to a channel, but a lot can. It depends on the serializer
you're using - the default, Marshal, can serialize most objects but not Procs, anonymous Modules, 
and a few other objects. JSON, on the other hand, can only serialize a few basic objects - Hash, 
Array, String, Boolean, `nil` (null) and Integer. 

It's not possible to write `nil` or `false` on its own to a channel, regardless of the 
serializer being used. In this example `#send` would raise an error (`XChan::NilError`):

```ruby
require 'xchan'
ch = xchan
xchan.send nil
```

That's because `nil` has special meaning to xchan.rb, it is returned by the `#timed_recv` 
and `#timed_send` methods to indicate a timeout.

## <a id='kernelsend-xchan'>Docs: `Kernel#send` and xchan.rb</a>

The `Kernel#send` method is often used for dynamic method dispatch in Ruby, where
a method can be called by name using a String or Symbol. It has an alias, `Kernel#__send__`,
that can be used in cases where an object has implemented its own `#send`.

In the case of xchan.rb, I found `#send` and `#recv` to be the best method names
for a channel object and I recommend using `Kernel#__send__` if you happen to be 
doing dynamic method dispatch using an xchan object. If `#send` and `#recv` is not 
to your taste, then there's also the aliases `#write` and `#read`.

This example shows how you would use `Kernel#__send__` with an xchan.rb channel object:

```ruby
require 'xchan'
ch = xchan
# Send a message to channel
ch.send "foo"
# Receive the message from channel
ch.__send__(:recv)
# Close the channel
ch.__send__(:close)
``` 

## <a id="documentation">Docs: API reference</a>

* [rubydoc.info/gems/xchan.rb (gem)](https://rubydoc.info/gems/xchan.rb)
* [rubydoc.info/github/0x1eef/xchan.rb/master](https://rubydoc.info/github/0x1eef/xchan.rb/master)

## <a id="install">Install</a>

    gem install xchan.rb

## <a id="license"> License </a>

The MIT license, see [LICENSE.txt](./LICENSE.txt) for details.
