ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nano
DOWNLOAD     += https://ftp.gnu.org/gnu/nano/nano-$(NANO_VERSION).tar.xz{,.sig}
NANO_VERSION := 4.9.2
DEB_NANO_V   ?= $(NANO_VERSION)

nano-setup: setup
	$(call PGP_VERIFY,nano-$(NANO_VERSION).tar.xz)
	$(call EXTRACT_TAR,nano-$(NANO_VERSION).tar.xz,nano-$(NANO_VERSION),nano)

ifneq ($(wildcard $(BUILD_WORK)/nano/.build_complete),)
nano:
	@echo "Using previously built nano."
else
nano: nano-setup ncurses
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
	cp -a $(BUILD_STAGE)/nano/usr $(BUILD_DIST)/nano
	
	# nano.mk Sign
	$(call SIGN,nano,general.xml)
	
	# nano.mk Make .debs
	$(call PACK,nano,DEB_NANO_V)
	
	# nano.mk Build cleanup
	rm -rf $(BUILD_DIST)/nano

.PHONY: nano nano-package
