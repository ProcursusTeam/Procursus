ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

bzip2: setup
	$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_STAGE)/bzip2/usr \
		CC=$(TRIPLE)clang \
		AR=$(TRIPLE)ar \
		RANLIB=$(TRIPLE)ranlib \
		CFLAGS="$(CFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_BASE)/usr \
		CC=$(TRIPLE)clang \
		AR=$(TRIPLE)ar \
		RANLIB=$(TRIPLE)ranlib \
		CFLAGS="$(CFLAGS)"

.PHONY: bzip2
