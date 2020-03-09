ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

bzip2:
	$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_STAGE)/bzip2/usr \
		CFLAGS="$(CFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_BASE)/usr \
		CFLAGS="$(CFLAGS)"

.PHONY: bzip2
