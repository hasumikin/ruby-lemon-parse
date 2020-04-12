CC := gcc
PARSE := parse
CRC := crc

all: $(PARSE).o $(CRC).o

build_so: lib$(PARSE).so lib$(CRC).so

$(PARSE).o: $(PARSE).c
	$(CC) $(CFLAGS) $(LEMON_MACRO) $(LDFLAGS) -c -o $(PARSE).o $(PARSE).c

lib$(PARSE).so: $(PARSE).c
	$(CC) $(CFLAGS) $(LEMON_MACRO) -fPIC -shared $(LDFLAGS) -o lib$(PARSE).so $(PARSE).c

$(PARSE).c: $(PARSE).y lemon/lemon
	lemon/lemon -p $(LEMON_MACRO) ./$(PARSE).y

lemon/lemon:
	cd lemon ; $(MAKE) all CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"

$(CRC).o:
	$(CC) $(CFLAGS) $(LDFLAGS) -c -o $(CRC).o $(CRC).c

lib$(CRC).so: $(CRC).c
	$(CC) $(CFLAGS) -fPIC -shared $(LDFLAGS) -o lib$(CRC).so $(CRC).c

clean:
	cd lemon ; $(MAKE) clean
	rm -f $(PARSE).c lib$(PARSE).so $(PARSE).h $(PARSE).out $(PARSE).o lib$(CRC).so $(CRC).o
