# Variables
CC = gcc          # Compiler to use
CFLAGS = -Wall    # Compilation flags (warnings)

# Target and dependencies
server: server.c
	$(CC) $(CFLAGS) -o server server.c

# Clean up generated files
clean:
	rm -f server
