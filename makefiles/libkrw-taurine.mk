ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq ($(MEMO_TARGET),iphoneos-arm64)
ifeq ($(CFVER_WHOLE),1700)

SUBPROJECTS            += libkrw-taurine
LIBKRW_TAURINE_VERSION := 1.0
DEB_LIBKRW_TAURINE_V   ?= $(LIBKRW_TAURINE_VERSION)

libkrw-taurine-setup: setup
	$(call GITHUB_ARCHIVE,R00tFS,libkrw-taurine,$(LIBKRW_TAURINE_VERSION),$(LIBKRW_TAURINE_VERSION))
	$(call EXTRACT_TAR,libkrw-taurine-$(LIBKRW_TAURINE_VERSION).tar.gz,libkrw-taurine-$(LIBKRW_TAURINE_VERSION),libkrw-taurine)
	mkdir -p $(BUILD_STAGE)/libkrw-taurine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

ifneq ($(wildcard $(BUILD_WORK)/libkrw-taurine/.build_complete),)
libkrw-taurine:
	@echo "Using previously built libkrw-taurine."
else
libkrw-taurine: libkrw-taurine-setup
	$(CC) $(CFLAGS) $(LDFLAGS) -shared -install_name $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-taurine.dylib \
		-I$(BUILD_WORK)/libkrw-taurine/include -I$(BUILD_WORK)/libkrw-taurine/src/libkernrw \
		$(BUILD_WORK)/libkrw-taurine/src/{main,libkernrw/*}.c -fvisibility=hidden \
		-o $(BUILD_STAGE)/libkrw-taurine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-taurine.dylib
	$(call AFTER_BUILD)
endif

libkrw-taurine-package: libkrw-taurine-stage
	# libkrw-taurine.mk Package Structure
	rm -rf $(BUILD_DIST)/libkrw0-taurine

	# libkrw-taurine.mk Prep libkrw0-taurine
	cp -a $(BUILD_STAGE)/libkrw-taurine $(BUILD_DIST)/libkrw0-taurine

	# libkrw-taurine.mk Sign
	$(call SIGN,libkrw-taurine,general.xml)

	# libkrw-taurine.mk Make .debs
	$(call PACK,libkrw0-taurine,DEB_LIBKRW_TAURINE_V)

	# libkrw-taurine.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkrw0-taurine

.PHONY: libkrw-taurine libkrw-taurine-package

endif
endif
