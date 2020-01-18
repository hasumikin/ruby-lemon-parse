CFLAGS += -Wall -Wpointer-arith -std=c99 -pedantic# -pedantic-errors
CC = gcc
PARSE = parse
CRC = crc

all: $(PARSE).o lib$(PARSE).so $(CRC).o lib$(CRC).so

$(PARSE).o: $(PARSE).c
	$(CC) $(CFLAGS) -c -o $(PARSE).o $(PARSE).c

lib$(PARSE).so: $(PARSE).c
	$(CC) $(CFLAGS) -fPIC -shared -o lib$(PARSE).so $(PARSE).c

$(PARSE).c: lemon/lemon
	lemon/lemon -p ./$(PARSE).y

lemon/lemon:
	cd lemon ; $(MAKE) all

$(CRC).o:
	$(CC) $(CFLAGS) -c -o $(CRC).o $(CRC).c

lib$(CRC).so: $(CRC).c
	$(CC) $(CFLAGS) -fPIC -shared -o lib$(CRC).so $(CRC).c

clean:
	cd lemon ; $(MAKE) clean
	rm -f $(PARSE).c lib$(PARSE).so $(PARSE).h $(PARSE).out $(PARSE).o lib$(CRC).so $(CRC).o
