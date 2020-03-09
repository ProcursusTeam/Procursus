ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

nano:
	cd $(BUILD_WORK)/nano && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--disable-dependency-tracking \
		--enable-color \
		--enable-extra \
		--enable-multibuffer \
		--enable-nanorc
	$(MAKE) -C $(BUILD_WORK)/nano
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/nano install \
		DESTDIR=$(BUILD_STAGE)/nano

.PHONY: nano
