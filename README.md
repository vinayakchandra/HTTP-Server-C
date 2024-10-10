### High level design

The server listens for incoming connections on a port 8080. and processes client requests in separate threads. This
allows the server to handle multiple concurrent connections.

Upon receiving a client request, the server checks if it is a valid GET request and extracts the requested file name. It
then decodes the URL-encoded file name and determines the file's extension to identify the appropriate MIME type for the
response.

Using a case-insensitive file search, the server checks if the requested file exists in the current directory. If it
does, the server constructs an HTTP response with the appropriate headers, including the determined MIME type, and sends
the file's contents to the client. If the file is not found, the server sends a 404 Not Found response.

The server continues to accept and process incoming connections until it is manually terminated.

### Problems encountered

1. After re-compiling and restarting server after every change, I got error `bind failed: address already in use`. I was
   confused because I've already killed every process that uses port 8080. After
   some [research](https://stackoverflow.com/questions/15198834/bind-failed-address-already-in-use), I found out that "
   the server still owns the socket when it starts and terminates quickly". So I add `SO_REUSEADDR` to the socket
   config, which "tells the server that even if this port is busy, go ahead and reuse it anyway".

2. After increasing buffer to 10MiB, I got error `bus error` every time I started the server. After some research, I
   found out that the stack memory allocated for each thread is usually limited. So I allocate the buffers on the heap
   instead of the stack by using `malloc()` and `free()`.

---

# Multi-threaded HTTP Server in C

This project is a multi-threaded HTTP server in C that uses socket programming, multi-threading with `pthread`, and file
handling to serve files over HTTP. It implements several key operating system concepts, such as process management (
through threads), memory management (through dynamic allocation), and resource handling (sockets and files).

## Features

- **Multi-threading**: Handles each client request in a separate thread using `pthread`.
- **Socket Programming**: Uses low-level socket programming to manage client connections.
- **File Handling**: Serves files to clients and handles file I/O using system calls.
- **Memory Management**: Dynamically allocates memory for buffers and cleans up after use.
- **HTTP Response Generation**: Serves files with appropriate MIME types based on their extensions.

## How It Works

### 1. Server Initialization

#### Socket Creation:

```c
server_fd = socket(AF_INET, SOCK_STREAM, 0);
```

This line creates a TCP socket using the IPv4 protocol.

Socket Binding:

```c
server_addr.sin_family = AF_INET;
server_addr.sin_addr.s_addr = INADDR_ANY;
server_addr.sin_port = htons(PORT);
bind(server_fd, (struct sockaddr *) &server_addr, sizeof(server_addr));
```

Here, the server binds the socket to a specific port (8080) and listens for incoming connections. The INADDR_ANY allows
the server to listen on any available network interface.

Listening for Connections:

```c
listen(server_fd, 10);
```

The server listens for incoming connections with a maximum backlog of 10 connections.

### 2. Handling Client Requests (Thread Creation)

Client Connection:

```c
client_fd = malloc(sizeof(int));
*client_fd = accept(server_fd, (struct sockaddr *) &client_addr, &client_addr_len);
```

The server accepts incoming client connections. Once a connection is accepted, a new thread is created using
pthread_create() to handle the client’s request.

Thread Handling:

```c
pthread_t thread_id;
pthread_create(&thread_id, NULL, handle_client, (void *) client_fd);
pthread_detach(thread_id);
```

For each new connection, a thread is spawned to handle the client’s request concurrently. The pthread_detach() function
ensures that the thread is cleaned up once it completes its task.

3. Handling Client Requests (In the Thread)
   The handle_client() function processes the client's request and sends the appropriate response.

Receiving Client Request:

```c
bytes_received = recv(client_fd, buffer, BUFFER_SIZE, 0);
```

The server reads the client's HTTP request into a buffer using the recv() function.

Regex for Parsing GET Request:

```c
regcomp(&regex, "^GET /([^ ]*) HTTP/1", REG_EXTENDED);
regexec(&regex, buffer, 2, matches, 0);
```

A regular expression is used to extract the requested file path from the HTTP GET request.

URL Decoding:

```c
char *file_name = url_decode(url_encoded_file_name);
```

The server decodes any URL-encoded characters (like %20 for spaces) in the requested file name.

### 4. Building the HTTP Response

Determining the MIME Type:

```c

const char *mime_type = get_mime_type(file_ext);
```

The get_mime_type() function maps the file extension (e.g., .html, .jpg, .png) to the correct MIME type for the HTTP
response.

File Handling:

```c
int file_fd = open(file_name, O_RDONLY);
```

The server attempts to open the requested file. If the file does not exist, the server sends a 404 Not Found response.
If the file is found, it reads the file content and sends it as part of the response.

Sending Response:

```c
send(client_fd, response, response_len, 0);
```

The server sends the complete HTTP response (header + file content) to the client.

### 5. Closing Connections and Cleaning Up

Closing Client Connection:

```c
close(client_fd);
```

Once the response is sent, the server closes the client connection and frees any dynamically allocated memory.

## Key OS Concepts

1. Multi-threading: Each client request is handled in a separate thread, demonstrating process/thread management in OS.
   This allows the server to handle multiple clients simultaneously.
2. Socket Programming: The server uses low-level socket programming to manage network communication. The socket(),
   bind(),
   listen(), accept(), and recv() system calls are used to manage connections.
3. File Handling: The server opens, reads, and serves files to clients. It uses the open(), read(), and close() system
   calls to interact with files.
4. Memory Management: The server dynamically allocates memory for buffers and socket descriptors using malloc() and
   frees
   the memory using free() after the request is processed.

Compile the server using `gcc`:

```bash
gcc -o server server.c
```

Run the server:

```bash
./server
```

Access the server from your browser at http://localhost:8080/ or by using a tool like curl:

```bash
curl http://localhost:8080/<your_file>
```