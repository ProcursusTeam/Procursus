ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libsixel
LIBSIXEL_VERSION := 1.8.6
DEB_LIBSIXEL_V   ?= $(LIBSIXEL_VERSION)

libsixel-setup: setup
	$(call GITHUB_ARCHIVE,saitoha,libsixel,$(LIBSIXEL_VERSION),v$(LIBSIXEL_VERSION))
	$(call EXTRACT_TAR,libsixel-$(LIBSIXEL_VERSION).tar.gz,libsixel-$(LIBSIXEL_VERSION),libsixel)
	$(SED) -i 's/x$$build = x$$host/x$$build/' $(BUILD_WORK)/libsixel/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libsixel/.build_complete),)
libsixel:
	@echo "Using previously built libsixel."
else
libsixel: libsixel-setup libpng16 libjpeg-turbo curl libgd
	cd $(BUILD_WORK)/libsixel && autoreconf -fi
	cd $(BUILD_WORK)/libsixel && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-python=no \
		--with-libcurl \
		--with-gd \
		--with-jpeg \
		--with-png
	+$(MAKE) -C $(BUILD_WORK)/libsixel
	+$(MAKE) -C $(BUILD_WORK)/libsixel install \
		DESTDIR="$(BUILD_STAGE)/libsixel"
	+$(MAKE) -C $(BUILD_WORK)/libsixel install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libsixel/.build_complete
endif

libsixel-package: libsixel-stage
	# libsixel.mk Package Structure
	rm -rf $(BUILD_DIST)/libsixel{1,-dev,-bin}
	mkdir -p $(BUILD_DIST)/libsixel{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libsixel-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libsixel.mk Prep libsixel1
	cp -a $(BUILD_STAGE)/libsixel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsixel.1.dylib $(BUILD_DIST)/libsixel1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libsixel.mk Prep libsixel-dev
	cp -a $(BUILD_STAGE)/libsixel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libsixel.1.dylib) $(BUILD_DIST)/libsixel-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libsixel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libsixel-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsixel.mk Prep libsixel-bin
	cp -a $(BUILD_STAGE)/libsixel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libsixel-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libsixel/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/libsixel-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libsixel.mk Sign
	$(call SIGN,libsixel1,general.xml)
	$(call SIGN,libsixel-bin,general.xml)

	# libsixel.mk Make .debs
	$(call PACK,libsixel1,DEB_LIBSIXEL_V)
	$(call PACK,libsixel-dev,DEB_LIBSIXEL_V)
	$(call PACK,libsixel-bin,DEB_LIBSIXEL_V)

	# libsixel.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsixel{1,-dev,-bin}

.PHONY: libsixel libsixel-package
