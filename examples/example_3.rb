#
# Example that demonstrates sending and receiving messages with a time out.
require 'xchan'
ch = xchan Marshal
ch.timed_send("Hello parent", 0.5) ? puts("message sent") : puts("send timed out")
(message = ch.timed_recv 0.5) ? puts(message) : puts("read timed out")
ch.close
