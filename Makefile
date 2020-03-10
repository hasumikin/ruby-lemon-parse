CC = gcc
PARSE = parse
CRC = crc

all: $(PARSE).o lib$(PARSE).so $(CRC).o lib$(CRC).so

$(PARSE).o: $(PARSE).c
	$(CC) $(CFLAGS) $(LEMON_MACRO) -c -o $(PARSE).o $(PARSE).c

lib$(PARSE).so: $(PARSE).c
	$(CC) $(CFLAGS) $(LEMON_MACRO) -fPIC -shared -o lib$(PARSE).so $(PARSE).c

$(PARSE).c: $(PARSE).y lemon/lemon
	lemon/lemon -p $(LEMON_MACRO) ./$(PARSE).y

lemon/lemon:
	cd lemon ; CFLAGS="$(CFLAGS)" $(MAKE) all

$(CRC).o:
	$(CC) $(CFLAGS) -c -o $(CRC).o $(CRC).c

lib$(CRC).so: $(CRC).c
	$(CC) $(CFLAGS) -fPIC -shared -o lib$(CRC).so $(CRC).c

clean:
	cd lemon ; $(MAKE) clean
	rm -f $(PARSE).c lib$(PARSE).so $(PARSE).h $(PARSE).out $(PARSE).o lib$(CRC).so $(CRC).o
