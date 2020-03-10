ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

xz: setup
	cd $(BUILD_WORK)/xz && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr/local \
		--disable-debug \
		--disable-dependency-tracking \
		--disable-silent-rules
	$(MAKE) -C $(BUILD_WORK)/xz
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_STAGE)/xz
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_BASE)

.PHONY: xz
