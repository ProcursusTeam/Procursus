ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libvidstab
LIBVIDSTAB_VERSION := 1.1.0
DEB_LIBVIDSTAB_V   ?= $(LIBVIDSTAB_VERSION)

libvidstab-setup: setup
	$(call GITHUB_ARCHIVE,georgmartius,vid.stab,$(LIBVIDSTAB_VERSION),v$(LIBVIDSTAB_VERSION))
	$(call EXTRACT_TAR,vid.stab-$(LIBVIDSTAB_VERSION).tar.gz,vid.stab-$(LIBVIDSTAB_VERSION),libvidstab)
	$(call DO_PATCH,libvidstab,libvidstab,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libvidstab/.build_complete),)
libvidstab:
	@echo "Using previously built libvidstab."
else
libvidstab: libvidstab-setup
	cd $(BUILD_WORK)/libvidstab && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DUSE_OMP=OFF \
		-DSSE2_FOUND=FALSE
	+$(MAKE) -C $(BUILD_WORK)/libvidstab
	+$(MAKE) -C $(BUILD_WORK)/libvidstab install \
		DESTDIR=$(BUILD_STAGE)/libvidstab
	+$(MAKE) -C $(BUILD_WORK)/libvidstab install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libvidstab/.build_complete
endif

libvidstab-package: libvidstab-stage
	# libvidstab.mk Package Structure
	rm -rf $(BUILD_DIST)/libvidstab{1.1,-dev}
	mkdir -p $(BUILD_DIST)/libvidstab{1.1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libvidstab.mk Prep libvidstab1.1
	cp -a $(BUILD_STAGE)/libvidstab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvidstab.1.1.dylib $(BUILD_DIST)/libvidstab1.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libvidstab.mk Prep libvidstab-dev
	cp -a $(BUILD_STAGE)/libvidstab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libvidstab.1.1.dylib) $(BUILD_DIST)/libvidstab-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libvidstab/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libvidstab-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libvidstab.mk Sign
	$(call SIGN,libvidstab1.1,general.xml)

	# libvidstab.mk Make .debs
	$(call PACK,libvidstab1.1,DEB_LIBVIDSTAB_V)
	$(call PACK,libvidstab-dev,DEB_LIBVIDSTAB_V)

	# libvidstab.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvidstab{1.1,-dev}

.PHONY: libvidstab libvidstab-package
