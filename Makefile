CC = gcc
TARGET = libparse.so
PARSE = parse
CRC = crc

all: $(TARGET) lib$(CRC).so

libparse.so: $(PARSE).c
	$(CC) -std=c99 -Wall -c -fPIC $(OPT) -o $(PARSE).o $(PARSE).c
	$(CC) -shared -o $(TARGET) $(PARSE).o

$(PARSE).c: lemon/lemon
	lemon/lemon -p ./$(PARSE).y

lemon/lemon:
	cd lemon ; $(MAKE) all

libcrc.so: $(CRC).c
	$(CC) -c -fPIC $(OPT) -o $(CRC).o $(CRC).c
	$(CC) -shared -o lib$(CRC).so $(CRC).o

clean:
	cd lemon ; $(MAKE) clean
	rm -f $(PARSE).c $(TARGET) $(PARSE).h $(PARSE).out $(PARSE).o lib$(CRC).so $(CRC).o
