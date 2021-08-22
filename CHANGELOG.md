# CHANGELOG

## HEAD

* Update API documentation

* Update gemspec description

* Update README.md description

## v0.3.5

* Update project description

## v0.3.4

* Update gemspec.

## v0.3.3

* Update gemspec email address.

## v0.3.2

* The `xchan` method can be called without an argument, defaulting to `Marshal`.

* Update API documentation.

## v0.3.1

* Update documentation files.

## v0.3.0

* Add `#recv_last` example to `README.md`.

* Add `XChan::UNIXSocket#read_last`, an alias for `#recv_last`.

* **Breaking change**
  Rename `XChan::UNIXSocket#last_msg` to `XChan::UNIXSocket#recv_last`.

* Update API docs

* Update `README.md`

## v0.2.0

**Enhancements**

* **Breaking change**
`write` and `timed_write` raise `XChan::NilError` when trying to write
`nil` or `false` to a channel.

* **Breaking change**
`timed_write` and `timed_read` return `nil` instead of raising an error when
they time out.

* **Breaking change**
Rename `send!` to `timed_send`, and rename `write!` to `timed_write`.

* **Breaking change**
Rename `recv!` to `timed_recv`, and rename `read!` to `timed_read`.

* Add an `examples/` directory that has copies of the `README` examples.

**Bug fixes**

None.

## v0.1.0

* First release of xchan.rb
