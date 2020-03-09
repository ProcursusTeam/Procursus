ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# TODO: Check if we can use --enable-jit

pcre: setup
	cd pcre && ./configure \
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
	$(MAKE) -C pcre
	$(FAKEROOT) $(MAKE) -C pcre install DESTDIR="$(DESTDIR)"

.PHONY: pcre
