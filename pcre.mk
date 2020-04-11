ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

PCRE_VERSION := 8.43
DEB_PCRE_V   ?= $(PCRE_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/pcre/.build_complete),)
pcre:
	@echo "Using previously built pcre."
else
pcre: setup
	cd $(BUILD_WORK)/pcre && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-utf8 \
		--enable-pcre8 \
		--enable-pcre16 \
		--enable-pcre32 \
		--enable-jit \
		--enable-unicode-properties \
		--enable-pcregrep-libz \
		--enable-pcregrep-libbz2
	+$(MAKE) -C $(BUILD_WORK)/pcre
	+$(MAKE) -C $(BUILD_WORK)/pcre install \
		DESTDIR=$(BUILD_STAGE)/pcre
	+$(MAKE) -C $(BUILD_WORK)/pcre install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/pcre/.build_complete
endif

pcre-package: pcre-stage
	# pcre.mk Package Structure
	rm -rf $(BUILD_DIST)/libpcre
	mkdir -p $(BUILD_DIST)/libpcre
	
	# pcre.mk Prep pcre
	$(FAKEROOT) cp -a $(BUILD_STAGE)/pcre/usr $(BUILD_DIST)/libpcre
	
	# pcre.mk Sign
	$(call SIGN,libpcre,general.xml)
	
	# pcre.mk Make .debs
	$(call PACK,libpcre,DEB_PCRE_V)
	
	# pcre.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpcre

.PHONY: pcre pcre-package