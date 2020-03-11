ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# TODO: Check if we can use --enable-jit

ifneq ($(wildcard $(BUILD_WORK)/pcre/.build_complete),)
pcre:
	@echo "Using previously built pcre."
else
pcre: setup bzip2 zlib
	cd $(BUILD_WORK)/pcre && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-utf8 \
		--enable-pcre8 \
		--enable-pcre16 \
		--enable-pcre32 \
		--enable-unicode-properties \
		--enable-pcregrep-libz \
		--enable-pcregrep-libbz2
	$(MAKE) -C $(BUILD_WORK)/pcre
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/pcre install \
		DESTDIR=$(BUILD_STAGE)/pcre
	$(MAKE) -C $(BUILD_WORK)/pcre install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/pcre/.build_complete
endif

.PHONY: pcre
