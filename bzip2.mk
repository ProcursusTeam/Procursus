ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

BZIP2_VERSION := 1.0.8

ifneq ($(wildcard $(BUILD_WORK)/bzip2/.build_complete),)
bzip2:
	@echo "Using previously built bzip2."
else
bzip2: setup
	$(SED) -i '/-shared -Wl/c\\	$$(CC) -dynamiclib $$(OBJS) -o libbz2.$(BZIP2_VERSION).dylib -install_name $$(PREFIX)/lib/libbz2.1.0.dylib -compatibility_version 1.0 -current_version $(BZIP2_VERSION)' $(BUILD_WORK)/bzip2/Makefile-libbz2_so
	$(SED) -i '/-o bzip2-shared/c\\	$(CC) $(CFLAGS) -o bzip2-shared bzip2.c libbz2.$(BZIP2_VERSION).dylib' $(BUILD_WORK)/bzip2/Makefile-libbz2_so
	$(SED) -i '/rm -f libbz2/c\\	rm -f libbz2.1.0.dylib' $(BUILD_WORK)/bzip2/Makefile-libbz2_so
	$(SED) -i '/ln -s/c\\	ln -s libbz2.1.0.8.dylib libbz2.1.0.dylib' $(BUILD_WORK)/bzip2/Makefile-libbz2_so
	$(MAKE) -C $(BUILD_WORK)/bzip2 -f Makefile-libbz2_so \
		PREFIX=/usr \
		CC=$(CC) \
		CFLAGS="$(CFLAGS)"
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
	cp -f $(BUILD_WORK)/bzip2/bzip2-shared $(BUILD_STAGE)/bzip2/usr/bin/bzip2
	cp -f $(BUILD_WORK)/bzip2/bzip2-shared $(BUILD_BASE)/usr/bin/bzip2
	cp -af $(BUILD_WORK)/bzip2/libbz2.*.dylib $(BUILD_STAGE)/bzip2/usr/lib
	cp -af $(BUILD_WORK)/bzip2/libbz2.*.dylib $(BUILD_BASE)/usr/lib
	cd $(BUILD_STAGE)/bzip2/usr/lib && ln -s libbz2.1.0.dylib libbz2.dylib
	cd $(BUILD_BASE)/usr/lib && ln -s libbz2.1.0.dylib libbz2.dylib
	touch $(BUILD_WORK)/bzip2/.build_complete
endif

.PHONY: bzip2
