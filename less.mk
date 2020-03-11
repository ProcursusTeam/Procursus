ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ($(wildcard $(BUILD_WORK)/less/.build_complete),)
less:
	@echo "Using previously built less."
else
less: setup
	cd $(BUILD_WORK)/less && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-regex=pcre \
		CFLAGS="$(CFLAGS) -Wno-implicit-function-declaration" \
		LDFLAGS="$(CFLAGS) $(LDFLAGS)"
	$(MAKE) -C $(BUILD_WORK)/less
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/less install \
		DESTDIR="$(BUILD_STAGE)/less"
	touch $(BUILD_WORK)/less/.build_complete
endif

.PHONY: less
