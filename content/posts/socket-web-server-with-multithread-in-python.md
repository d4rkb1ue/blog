---
title: "Socket Web Server With Multithread in Python"
date: 2020-07-19T03:25:38-07:00
tags: ['networking', 'linux', 'python', 'multithread']
---

## Socket in Unix/Linux

- `Socket` in Unix/Linux is just file descriptor, which means you can just treat it as file.
- `Socket` exists on the both ends of the communicators as the endpoints.
- `Socket` can be full duplex.
- Since `Socket` are inherently `file`, then it has its own **buffer** for both Reading and Writing. The communication process is like,
  - Reading data from its reading buffer and write data to its writing buffer
  - When the writing buffer is full(or call `flush`), the data will be passed to the peer's reading buffer
  - Peer will refuse to be inputed when full

## Socket Server/Client in Python

- Server's `serversocket.bind` is actaully to,
  - Start **a `Socket` for accepting new sockets request**
  - It's for Client applies a new connection with server - "I want to talk with you using my `Socket` at `IP:Port`"
  - It's NOT for really passing the message payload
- The `clientsocket` in `(clientsocket, address) = serversocket.accept()` is a new socket connected to client for payload communication.

BTW, 

- `nc(1)` is not a socket server like `socket.socket` in Python. Instead,
  - It just serves as a Server for the "socket application" initially for the very 1st connection. We can see it in `netstat -l`.
  - After being connected, the socket got closed or converted to a client mode socket, which can only be found in `netstat` without the `-l`(listening).

## Socket with Multiple Process/Threadings in Python 

Theading is a standard in Unix/Linux. Each thread has its own runtime context with register data, allowing it to know which line of code need to be run. While code is actually the shared data in the process's memory as multiple thread in a single process can share the memory.

- `serversocket.accept()` is a blocking process by default, which is thread-safe & process-safe. So the `serversocket` can be shared among multiple threads and/or processes.
- `Process` share socket by cloning the `fd`(file descriptor) when `fork`
- But ONLY ONE process can do the `bind` and `listen` as a `Socket` need to be binded with a specific process.
- Although you can still run `accept()` in multiple processes and also threads.


## Real Example

```py
'''python3'''
import socket
import threading
import time

response = 'HTTP/1.1 200 OK\r\nConnection: Close\r\nContent-Length: 11\r\n\r\nHello world'
server = socket.socket()
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', 1234))
server.listen(1234)

def handler():
    while True:
        client, _ = server.accept()
        request = client.recv(1024)
        # pretent to prepare
        time.sleep(2)
        client.send(b'Bye')
        client.close()

thread1 = threading.Thread(target=handler)
thread1.daemon = True
thread1.start()
thread2 = threading.Thread(target=handler)
thread2.daemon = True
thread2.start()

thread1.join() # wait threading return before exit
thread2.join()
```

Run by `python3 server.py`

Open another two windows to see the Sockets status,

* `watch -n1 netstat -lt` for only TCP server(listening) sockets
* `watch -n1 netstat -t`  for only TCP non-listening sockets

Use `telnet` as the client to connect to our Python server,

```sh
telnet localhost 1234
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
abc # random input
Bye # the response from server
Connection closed by foreign host.
```

`netstat -lt` is always showing:

```
tcp        0      0 *:1234                  *:*		LISTEN
```

But `netstat -t` is interesting:

```
Every 1.0s: netstat -t                                                  

Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 localhost:1234          localhost:50688         TIME_WAIT
tcp        0      0 localhost:1234          localhost:50690         TIME_WAIT
tcp        0      0 localhost:1234          localhost:50692         ESTABLISHED
tcp        0      0 localhost:50692         localhost:1234          ESTABLISHED
```

Since `Socket` is 5-tuple with 
1. source IP address
2. source port number
3. destination IP address
4. destination port number
5. protocol

So every line above is an independent socket, although there are multiple combo of `proto=tcp src=localhost:1234`.


`TIME_WAIT` are the legacies from closed Sockets. Disappeared a few seconds after the telnet client closed.

We can create multiple connection by start multiple telnet. Each client-server connection will create a pair of,
```
tcp localhost:<random_port_A>   localhost:1234              ESTABLISHED
tcp localhost:1234              localhost:<random_port_A>   ESTABLISHED
```

## Ref.

1. [linux - Can I call accept() for one socket from several threads simultaneously? - Stack Overflow](https://stackoverflow.com/questions/11488453/can-i-call-accept-for-one-socket-from-several-threads-simultaneously)
2. [Socket Programming HOWTO — Python 3.8.4 documentation](https://docs.python.org/3.8/howto/sockets.html)
3. [Understand web server concurrency  models with examples in Python | Junchao’s blog](https://franklingu.github.io/programming/2016/07/27/understand-python-web-server-models-with-examples/)
4. [concurrency - Is there a way for multiple processes to share a listening socket? - Stack Overflow](https://stackoverflow.com/questions/670891/is-there-a-way-for-multiple-processes-to-share-a-listening-socket)
5. [linux - Calling accept() from multiple threads - Stack Overflow](https://stackoverflow.com/questions/17630416/calling-accept-from-multiple-threads)
6. [socket(2) - Linux manual page](https://man7.org/linux/man-pages/man2/socket.2.html)
