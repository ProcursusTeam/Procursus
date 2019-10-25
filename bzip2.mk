ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

bzip2:
	$(MAKE) -C bzip2 install \
		PREFIX=$(DESTDIR)/usr \
		CFLAGS="$(CFLAGS)"

.PHONY: bzip2
