LDID           ?= ldid
SED            ?= sed
DEB_MAINTAINER ?= absidue
ifeq ($(DEBUG),1)
CFLAGS += -DDEBUG
endif

all: sw_vers firmware

sw_vers: sw_vers.c
	$(CC) $(CFLAGS) sw_vers.c -o sw_vers -framework CoreFoundation -O3
	$(STRIP) sw_vers
	$(LDID) -S sw_vers

firmware: main.m Firmware.m DeviceInfo.m
	$(CC) $(CFLAGS) -fobjc-arc -DMAINTAINER='@"$(DEB_MAINTAINER)"' main.m Firmware.m DeviceInfo.m -o firmware -I. -framework Foundation -O3
	$(STRIP) firmware
	$(LDID) -S firmware

clean:
	rm sw_vers firmware
