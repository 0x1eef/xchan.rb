#
# Example that demonstrates sending a message from a parent process to a child
# process.
require 'xchan'

ch = xchan Marshal
pid = fork { puts ch.recv }
ch.send "Hi child"
Process.wait(pid)
ch.close
