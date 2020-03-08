# CHANGELOG

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
