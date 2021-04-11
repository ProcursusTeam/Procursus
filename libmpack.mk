ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libmpack
LIBMPACK_VERSION := 1.0.5
DEB_LIBMPACK_V   ?= $(LIBMPACK_VERSION)

libmpack-setup: setup
	$(call GITHUB_ARCHIVE,libmpack,libmpack,$(LIBMPACK_VERSION),$(LIBMPACK_VERSION))
	$(call EXTRACT_TAR,libmpack-$(LIBMPACK_VERSION).tar.gz,libmpack-$(LIBMPACK_VERSION),libmpack)

ifneq ($(wildcard $(BUILD_WORK)/libmpack/.build_complete),)
libmpack:
	@echo "Using previously built libmpack."
else
libmpack: libmpack-setup
	+$(MAKE) -C $(BUILD_WORK)/libmpack install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/libmpack
	+$(MAKE) -C $(BUILD_WORK)/libmpack install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libmpack/.build_complete
endif

libmpack-package: libmpack-stage
	# libmpack.mk Package Structure
	rm -rf $(BUILD_DIST)/libmpack{0,-dev}
	mkdir -p $(BUILD_DIST)/libmpack{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmpack.mk Prep libmpack2
	cp -a $(BUILD_STAGE)/libmpack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmpack.0.dylib $(BUILD_DIST)/libmpack0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libmpack.mk Prep libmpack-dev
	cp -a $(BUILD_STAGE)/libmpack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmpack.{dylib,a} $(BUILD_DIST)/libmpack-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libmpack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmpack-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libmpack.mk Sign
	$(call SIGN,libmpack0,general.xml)

	# libmpack.mk Make .debs
	$(call PACK,libmpack0,DEB_LIBMPACK_V)
	$(call PACK,libmpack-dev,DEB_LIBMPACK_V)

	# libmpack.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmpack{0,-dev}

.PHONY: libmpack libmpack-package
