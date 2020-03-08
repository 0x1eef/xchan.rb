# Example that demonstrates sending messages from a child process to a parent
# process.
require 'xchan'

ch = xchan Marshal
Process.wait fork {
  ch.send "Hi parent"
  ch.send "Bye parent"
}
puts ch.recv
puts ch.recv
ch.close
