ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LIBASSUAN_VERSION := 2.5.3

ifneq ($(wildcard $(BUILD_WORK)/libassuan/.build_complete),)
libassuan:
	@echo "Using previously built libassuan."
else
libassuan: setup libgpg-error
	cd $(BUILD_WORK)/libassuan && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-gpg-error-prefix=$(BUILD_BASE)/usr
	$(MAKE) -C $(BUILD_WORK)/libassuan
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libassuan install \
		DESTDIR=$(BUILD_STAGE)/libassuan
	$(FAKEROOT) $(MAKE) -C $(BUILD_WORK)/libassuan install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libassuan/.build_complete
endif

.PHONY: libassuan
