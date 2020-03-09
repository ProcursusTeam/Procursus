ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

zlib: setup
	cd $(BUILD_WORK)/zlib && ./configure \
		--prefix=/usr
	$(MAKE) -C $(BUILD_WORK)/zlib
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/zlib install \
		DESTDIR=$(BUILD_STAGE)/zlib

.PHONY: zlib
