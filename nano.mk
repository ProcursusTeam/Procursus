ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nano
NANO_VERSION := 4.9.3
DEB_NANO_V   ?= $(NANO_VERSION)-1

nano-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/nano/nano-$(NANO_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,nano-$(NANO_VERSION).tar.xz)
	$(call EXTRACT_TAR,nano-$(NANO_VERSION).tar.xz,nano-$(NANO_VERSION),nano)

ifneq ($(wildcard $(BUILD_WORK)/nano/.build_complete),)
nano:
	@echo "Using previously built nano."
else
nano: nano-setup ncurses gettext
	cd $(BUILD_WORK)/nano && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--sysconfdir=/etc \
		--disable-dependency-tracking \
		--enable-color \
		--enable-extra \
		--enable-nanorc \
		--enable-utf8 \
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
