ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif
SUBPROJECTS   += cups
CUPS_VERSION := 2.3.3op2
DEB_CUPS_V   ?= $(CUPS_VERSION)
cups-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/OpenPrinting/cups/releases/download/v$(CUPS_VERSION)/cups-$(CUPS_VERSION)-source.tar.gz{,.sig}
	$(call PGP_VERIFY,cups-$(CUPS_VERSION)-source.tar.gz)
	$(call EXTRACT_TAR,cups-$(CUPS_VERSION)-source.tar.gz,cups-$(CUPS_VERSION),cups)
        
ifneq ($(wildcard $(BUILD_WORK)/cups/.build_complete),)
cups:
	@echo "Using previously built cups."
else
cups: cups-setup
	cd $(BUILD_WORK)/cups && ./configure -C \
	$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-libusb \
			--enable-launchd \
				--disable-dbus \
				--with-components=core \
				--disable-debug
	+$(MAKE) -C $(BUILD_WORK)/cups/cups
	cd $(BUILD_WORK)/cups/locale && $(CC) checkpo.c -c -I.. -w
	cd $(BUILD_WORK)/cups/locale && $(CC) po2strings.c -c -I.. -w
	cd $(BUILD_WORK)/cups/locale && $(CC) -lcups -L../cups po2strings.o -o po2strings -I.. 
	cd $(BUILD_WORK)/cups/locale && $(CC) -lcups -L../cups checkpo.o -o checkpo -I..
	+$(MAKE) -C $(BUILD_WORK)/cups
	+$(MAKE) -C $(BUILD_WORK)/cups install \
		DESTDIR=$(BUILD_STAGE)/cups
	touch $(BUILD_WORK)/cups/.build_complete
endif
cups-package: cups-stage
	# cups.mk Package Structure
	rm -rf $(BUILD_DIST)/cups
	mkdir -p $(BUILD_DIST)/cups
	# cups.mk Prep cups
	cp -a $(BUILD_STAGE)/cups $(BUILD_DIST)
	# cups.mk Sign
	$(call SIGN,cups,general.xml)
	# cups.mk Make .debs
	$(call PACK,cups,DEB_CUPS_V)
	# cups.mk Build cleanup
	rm -rf $(BUILD_DIST)/cups
	.PHONY: cups cups-package
