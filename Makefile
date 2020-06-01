CC := gcc
PARSE := parse
CRC := crc

all: $(PARSE).o $(CRC).o token_helper.h

atom_helper.h: parse_header.h
	./helper_gen.rb atom

token_helper.h: parse.h
	./helper_gen.rb token

build_so: lib$(PARSE).so lib$(CRC).so

$(PARSE).o: $(PARSE).c atom_helper.h 
	$(CC) $(CFLAGS) $(LEMON_MACRO) $(LDFLAGS) -c -o $(PARSE).o $(PARSE).c

lib$(PARSE).so: $(PARSE).c
	$(CC) $(CFLAGS) $(LEMON_MACRO) -fPIC -shared $(LDFLAGS) -o lib$(PARSE).so $(PARSE).c

$(PARSE).c: $(PARSE).y lemon/lemon
	./lemon.rb $(LEMON_MACRO)

lemon/lemon:
	cd lemon ; $(MAKE) all CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)"

$(CRC).o:
	$(CC) $(CFLAGS) $(LDFLAGS) -c -o $(CRC).o $(CRC).c

lib$(CRC).so: $(CRC).c
	$(CC) $(CFLAGS) -fPIC -shared $(LDFLAGS) -o lib$(CRC).so $(CRC).c

clean:
	cd lemon ; $(MAKE) clean
	rm -f $(PARSE).c lib$(PARSE).so $(PARSE).h $(PARSE).out $(PARSE).o lib$(CRC).so $(CRC).o \
	  *_helper.h
