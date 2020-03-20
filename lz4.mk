ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LZ4_VERSION := 1.9.2

ifneq ($(wildcard $(BUILD_WORK)/lz4/.build_complete),)
lz4:
	@echo "Using previously built lz4."
else
lz4: setup
	TARGET_OS=Darwin \
		$(MAKE) -C $(BUILD_WORK)/lz4 install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/lz4 \
		CFLAGS="$(CFLAGS)"
	TARGET_OS=Darwin \
		$(MAKE) -C $(BUILD_WORK)/lz4 install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE) \
		CFLAGS="$(CFLAGS)"
	touch $(BUILD_WORK)/lz4/.build_complete
endif

.PHONY: lz4
