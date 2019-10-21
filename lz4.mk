ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

lz4:
	$(MAKE) -C lz4 install \
		PREFIX=/usr \
		DESTDIR="$(DESTDIR)" \
		CFLAGS="$(CFLAGS)"

.PHONY: lz4
