ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

less:
	cd $(BUILD_WORK)/less && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-regex=pcre \
		CFLAGS="$(CFLAGS) -Wno-implicit-function-declaration" \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/less
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/less install \
		DESTDIR="$(BUILD_STAGE)/less"

.PHONY: less
