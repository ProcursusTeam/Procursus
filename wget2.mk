ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += wget2
WGET2_VERSION := 1.99.2
DEB_WGET2_V   ?= $(WGET2_VERSION)-2

wget2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/wget/wget2-$(WGET2_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,wget2-$(WGET2_VERSION).tar.gz)
	$(call EXTRACT_TAR,wget2-$(WGET2_VERSION).tar.gz,wget2-$(WGET2_VERSION),wget2)

ifneq ($(wildcard $(BUILD_WORK)/wget2/.build_complete),)
wget2:
	@echo "Using previously built wget2."
else
wget2: wget2-setup openssl pcre2 xz zstd nghttp2 libidn2 gettext
	cd $(BUILD_WORK)/wget2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		--sysconfdir=/etc \
		--with-ssl=openssl \
		--with-openssl \
		--without-libpsl
	+$(MAKE) -C $(BUILD_WORK)/wget2
	+$(MAKE) -C $(BUILD_WORK)/wget2 install \
		DESTDIR="$(BUILD_STAGE)/wget2"
	touch $(BUILD_WORK)/wget2/.build_complete
endif

wget2-package: wget2-stage
	# wget2.mk Package Structure
	rm -rf $(BUILD_DIST)/wget2
	mkdir -p $(BUILD_DIST)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/{include,lib,bin,share/man/man1}
	
	# wget2.mk Prep wget2
	cp -a $(BUILD_STAGE)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/ $(BUILD_DIST)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/include/ $(BUILD_DIST)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/ $(BUILD_DIST)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/wget2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share
	
	# wget2.mk Sign
	$(call SIGN,wget2,general.xml)
	
	# wget2.mk Make .debs
	$(call PACK,wget2,DEB_WGET2_V)
	
	# wget2.mk Build cleanup
	rm -rf $(BUILD_DIST)/wget2

.PHONY: wget2 wget2-package
