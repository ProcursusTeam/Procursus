ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

bzip2: setup
	$(MAKE) -C bzip2 install \
		PREFIX=$(DESTDIR)/usr \
		CC=$(TRIPLE)clang \
		AR=$(TRIPLE)ar \
		RANLIB=$(TRIPLE)ranlib \
		CFLAGS="$(CFLAGS)"

.PHONY: bzip2
