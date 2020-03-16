ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ($(wildcard $(BUILD_WORK)/libksba/.build_complete),)
libksba:
	@echo "Using previously built libksba."
else
libksba: setup libgpg-error
	cd $(BUILD_WORK)/libksba && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr
	$(MAKE) -C $(BUILD_WORK)/libksba
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libksba install \
		DESTDIR=$(BUILD_STAGE)/libksba
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libksba install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libksba/.build_complete
endif

.PHONY: libksba
