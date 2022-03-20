ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libfaketime
LIBFAKETIME_VERSION := 0.9.10
DEB_LIBFAKETIME_V   ?= $(LIBFAKETIME_VERSION)-1

libfaketime-setup: setup
	$(call GITHUB_ARCHIVE,wolfcw,libfaketime,$(LIBFAKETIME_VERSION),v$(LIBFAKETIME_VERSION))
	$(call EXTRACT_TAR,libfaketime-$(LIBFAKETIME_VERSION).tar.gz,libfaketime-$(LIBFAKETIME_VERSION),libfaketime)
	$(call DO_PATCH,libfaketime,libfaketime,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libfaketime/.build_complete),)
libfaketime:
	@echo "Using previously built libfaketime."
else
libfaketime: libfaketime-setup
	sed -i "s/LD_PRELOAD/DYLD_INSERT_LIBRARIES/g" $(BUILD_WORK)/libfaketime/man/faketime.1
	+$(MAKE) -C $(BUILD_WORK)/libfaketime install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		CC="$(CC) $(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		DESTDIR=$(BUILD_STAGE)/libfaketime
	$(call AFTER_BUILD)
endif

libfaketime-package: libfaketime-stage
	# libfaketime.mk Package Structure
	rm -rf $(BUILD_DIST)/{,lib}faketime
	mkdir -p $(BUILD_DIST)/{,lib}faketime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libfaketime.mk Prep faketime
	cp -a $(BUILD_STAGE)/libfaketime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/faketime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libfaketime.mk Prep libfaketime
	cp -a $(BUILD_STAGE)/libfaketime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/libfaketime/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libfaketime.mk Sign
	$(call SIGN,faketime,general.xml)
	$(call SIGN,libfaketime,general.xml)

	# libfaketime.mk Make .debs
	$(call PACK,faketime,DEB_LIBFAKETIME_V)
	$(call PACK,libfaketime,DEB_LIBFAKETIME_V)

	# libfaketime.mk Build cleanup
	rm -rf $(BUILD_DIST)/{,lib}faketime

.PHONY: libfaketime libfaketime-package
