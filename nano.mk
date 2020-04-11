ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

NANO_VERSION := 4.5
DEB_NANO_V   ?= $(NANO_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/nano/.build_complete),)
nano:
	@echo "Using previously built nano."
else
nano: setup ncurses
	cd $(BUILD_WORK)/nano && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--disable-dependency-tracking \
		--enable-color \
		--enable-extra \
		--enable-multibuffer \
		--enable-nanorc \
		NCURSESW_LIBS=$(BUILD_BASE)/usr/lib/libncursesw.dylib
	+$(MAKE) -C $(BUILD_WORK)/nano
	+$(MAKE) -C $(BUILD_WORK)/nano install \
		DESTDIR=$(BUILD_STAGE)/nano
	touch $(BUILD_WORK)/nano/.build_complete
endif

nano-package: nano-stage
	# nano.mk Package Structure
	rm -rf $(BUILD_DIST)/nano
	mkdir -p $(BUILD_DIST)/nano
	
	# nano.mk Prep nano
	$(FAKEROOT) cp -a $(BUILD_STAGE)/nano/usr $(BUILD_DIST)/nano
	
	# nano.mk Sign
	$(call SIGN,nano,general.xml)
	
	# nano.mk Make .debs
	$(call PACK,nano,DEB_NANO_V)
	
	# nano.mk Build cleanup
	rm -rf $(BUILD_DIST)/nano

.PHONY: nano nano-package
