ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += zlib
ZLIB_VERSION := 1.2.11
DEB_ZLIB_V   ?= $(ZLIB_VERSION)

zlib-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://zlib.net/zlib-$(ZLIB_VERSION).tar.gz
	$(call EXTRACT_TAR,zlib-$(ZLIB_VERSION).tar.gz,zlib-$(ZLIB_VERSION),zlib)

ifneq ($(wildcard $(BUILD_WORK)/zlib/.build_complete),)
zlib:
	@echo "Using previously built zlib."
else
zlib: zlib-setup openssl zstd bzip2 xz
	cd $(BUILD_WORK)/zlib && ./configure \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/zlib
	+$(MAKE) -C $(BUILD_WORK)/zlib install \
		DESTDIR=$(BUILD_STAGE)/zlib
	+$(MAKE) -C $(BUILD_WORK)/zlib install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/zlib/.build_complete
endif

zlib-package: zlib-stage
	# rsync.mk Package Structure
	rm -rf $(BUILD_DIST)/zlib
	mkdir -p $(BUILD_DIST)/zlib
	
	# rsync.mk Prep rsync
	cp -a $(BUILD_STAGE)/zlib/usr $(BUILD_DIST)/zlib
	
	# rsync.mk Sign
	$(call SIGN,zlib,general.xml)
	
	# rsync.mk Make .debs
	$(call PACK,zlib,DEB_ZLIB_V)
	
	# rsync.mk Build cleanup
	rm -rf $(BUILD_DIST)/zlib

.PHONY: zlib zlib-package
