ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pcre2
DOWNLOAD      += https://ftp.pcre.org/pub/pcre/pcre2-$(PCRE2_VERSION).tar.bz2{,.sig}
PCRE2_VERSION := 10.34
DEB_PCRE2_V   ?= $(PCRE2_VERSION)

pcre2-setup: setup
	$(call PGP_VERIFY,pcre2-$(PCRE2_VERSION).tar.bz2)
	$(call EXTRACT_TAR,pcre2-$(PCRE2_VERSION).tar.bz2,pcre2-$(PCRE2_VERSION),pcre2)

ifneq ($(wildcard $(BUILD_WORK)/pcre2/.build_complete),)
pcre2:
	@echo "Using previously built pcre2."
else
pcre2: pcre2-setup
	cd $(BUILD_WORK)/pcre2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-pcre2-16 \
		--enable-pcre2-32 \
		--enable-jit \
		--enable-pcre2grep-libz \
		--enable-pcre2grep-libbz2
	+$(MAKE) -C $(BUILD_WORK)/pcre2
	+$(MAKE) -C $(BUILD_WORK)/pcre2 install \
		DESTDIR=$(BUILD_STAGE)/pcre2
	+$(MAKE) -C $(BUILD_WORK)/pcre2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/pcre2/.build_complete
endif

pcre2-package: pcre2-stage
	# pcre2.mk Package Structure
	rm -rf $(BUILD_DIST)/libpcre2
	mkdir -p $(BUILD_DIST)/libpcre2
	
	# pcre2.mk Prep pcre2
	cp -a $(BUILD_STAGE)/pcre2/usr $(BUILD_DIST)/libpcre2
	
	# pcre2.mk Sign
	$(call SIGN,libpcre2,general.xml)
	
	# pcre2.mk Make .debs
	$(call PACK,libpcre2,DEB_PCRE2_V)
	
	# pcre2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpcre2

.PHONY: pcre2 pcre2-package