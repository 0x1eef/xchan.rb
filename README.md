# xchannel.rb

1. <a href="#introduction">Introduction</a>
2. <a href="#examples">Examples</a>
3. <a href="#requirements">Requirements</a>
4. <a href="#install">Install</a>
5. <a href="#license">License</a>


## <a id="introduction">Introduction</a>

xchannel.rb provides an easy to use abstraction for sharing Ruby objects 
between Ruby processes who share a parent-child relationship.

Under the hood, xchannel.rb uses a method of transport (eg, a UNIXSocket)
and a serializer (eg: Marshal) to send and receive objects.

## <a id="examples">Examples</a>

__1.__

Marshal is the serializer who can serialize the most Ruby objects, although
it cannot serialize Proc and a few other objects. 

Marshal is apart of Ruby's core library, so you will be glad to know there is 
nothing extra to require. :) Marshal does not have to be provided as an explicit
argument (it is the default argument) but for the sake of the example it is.

```ruby
ch = XChannel.unix Marshal
Process.wait fork { ch.send "Hello, world!" }
ch.recv # => "Hello, world!"
Process.wait fork { ch.send "Bye, world!" }
ch.recv # => "Bye, world!"
ch.close
```

__2.__

JSON can act as a serializer as well, because any object that implements the dump and load 
methods can act as a serializer. What it can serialize is limited when compared with the 
Marshal module, though.

```ruby
require 'json'
ch = XChannel.unix JSON
Process.wait fork { ch.send [1,2,3] }
ch.recv # => [1,2,3]
ch.close
```

__3.__

You might want to use YAML as a serializer, that works too. 

```ruby
require 'yaml'
ch = XChannel.unix YAML
Process.wait fork { ch.send [1,2,3] }
ch.recv # => [1,2,3]
ch.close
```

## <a id="requirements"> Requirements </a>

* Ruby 2.1+

## <a id="install">Install</a>

As a RubyGem:

    git clone https://github.com/r-obert/xchannel.rb.git
    cd xchannel.rb/
    git checkout origin/v1.0.0
    gem build *.gemspec
    gem install *.gem

As a bundled gem:

    gem "xchannel.rb", github: "r-obert/xchannel.rb", tag: "v1.0.0" 

## <a id="license"> License </a>

This project uses the MIT license, see [LICENSE.txt](./LICENSE.txt) for details.
