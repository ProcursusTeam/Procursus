ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

# Not having well support for Darwin targets for now
# See https://github.com/Homebrew/homebrew-core/blob/77255105bc0a442af97d0872a1b01ec00bb587fe/Formula/mold.rb and https://github.com/rui314/mold/issues/189
SUBPROJECTS   += mold
MOLD_VERSION := 1.2.0
DEB_MOLD_V   ?= $(MOLD_VERSION)

mold-setup: setup
	$(call GITHUB_ARCHIVE,rui314,mold,$(MOLD_VERSION),v$(MOLD_VERSION))
	$(call EXTRACT_TAR,mold-$(MOLD_VERSION).tar.gz,mold-$(MOLD_VERSION),mold)

ifneq ($(shell [ "$(CFVER_WHOLE)" -ge 1600 ] && echo 1),1)
mold:
	@echo "Mold is unavailable with target CFVER $(CFVER_WHOLE)."
else
ifneq ($(wildcard $(BUILD_WORK)/mold/.build_complete),)
mold:
	@echo "Using previously built mold."
else
mold: mold-setup tbb
	+$(MAKE) -C $(BUILD_WORK)/mold install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		CC="$(CC)" \
		CXX="$(CXX)" \
		CFLAGS="$(CFLAGS) -I$(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		CXXFLAGS="$(CXXFLAGS) -I$(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		LDFLAGS="$(LDFLAGS) -L$(BUILD_STAGE)/tbb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		OS="Darwin" \
		ARCH="$(MEMO_ARCH)" \
		SYSTEM_TBB=1 \
		STRIP=true \
		DESTDIR=$(BUILD_STAGE)/mold
	$(call AFTER_BUILD)
endif
endif

mold-package: mold-stage
	# mold.mk Package Structure
	rm -rf $(BUILD_DIST)/mold

	# mold.mk Prep mold
	cp -a $(BUILD_STAGE)/mold $(BUILD_DIST)

	# mold.mk Sign
	$(call SIGN,mold,general.xml)

	# mold.mk Make .debs
	$(call PACK,mold,DEB_MOLD_V)

	# mold.mk Build cleanup
	rm -rf $(BUILD_DIST)/mold

.PHONY: mold mold-package
