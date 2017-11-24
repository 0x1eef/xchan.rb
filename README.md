Mirrors:

* [Github](https://github.rom/0x1eef/zchannel.rb)
* [Gitlab](https://gitlab.com/0x1eef/zchannel.rb)

### zchannel

Provides an easy to use abstraction for sharing Ruby objects between Ruby
processes who share a parent-child relationship. The implementation uses
an unbound UNIXSocket, and a serializer of your choice, for sending Ruby
objects between processes.

### Examples

__1.__

Marshal is the serializer that can serialize the most Ruby objects, although
Proc and other objects cannot be serialized. It is apart of Ruby's core library,
so no require is needed:

```ruby
ch = ZChannel.unix Marshal
Process.wait fork { ch.send "Hello, world!" }
ch.recv # => "Hello, world!"
```

__2.__

JSON can be used as a serializer but what it can serialize is less than what
Marshal can serialize. Which could be a good or bad thing, depending on what
you want to do:

```ruby
require 'json'
ch = ZChannel.unix JSON
Process.wait fork { ch.send [1,2,3] }
ch.recv # => [1,2,3]
```

__3.__

Any serializer that implements "dump", & "load" is supported though, so YAML also works
out of the box:

```ruby
require 'yaml'
ch = ZChannel.unix YAML
Process.wait fork { ch.send [1,2,3] }
ch.recv # => [1,2,3]
```

__Install__

Rubygems:

	$ gem install zchannel.rb

Bundler:

    gem "zchannel.rb", git: "https://github.com/0x1eef/zchannel.rb"


Build gem from source:

    git clone https://github.com/0x1eef/zchannel.rb
    cd zchannel
    gem build zchannel.gemspec
    gem install zchannel*.gem

### License

[MIT](./LICENSE.txt)
