LDID ?= ldid

all: sw_vers

sw_vers: sw_vers.c
	$(CC) $(CFLAGS) sw_vers.c -o sw_vers -framework CoreFoundation -O3
	$(STRIP) sw_vers
	$(LDID) -S sw_vers

clean:
	rm sw_vers
