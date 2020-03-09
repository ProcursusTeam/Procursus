ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

lz4:
	$(MAKE) -C $(BUILD_WORK)/lz4 install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/lz4 \
		CFLAGS="$(CFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/lz4 install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE) \
		CFLAGS="$(CFLAGS)"

.PHONY: lz4
