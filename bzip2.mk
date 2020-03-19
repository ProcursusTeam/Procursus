ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

BZIP2_VERSION := 1.0.8

ifneq ($(wildcard $(BUILD_WORK)/bzip2/.build_complete),)
bzip2:
	@echo "Using previously built bzip2."
else
bzip2: setup
	$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_STAGE)/bzip2/usr \
		CC=$(CC) \
		AR=$(AR) \
		RANLIB=$(RANLIB) \
		CFLAGS="$(CFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_BASE)/usr \
		CC=$(CC) \
		AR=$(AR) \
		RANLIB=$(RANLIB) \
		CFLAGS="$(CFLAGS)"
	touch $(BUILD_WORK)/bzip2/.build_complete
endif

.PHONY: bzip2
