ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += meson
MESON_VERSION := 0.61.2
DEB_MESON_V   ?= $(MESON_VERSION)

meson-setup: setup
	$(call GITHUB_ARCHIVE,mesonbuild,meson,$(MESON_VERSION),$(MESON_VERSION))
	$(call EXTRACT_TAR,meson-$(MESON_VERSION).tar.gz,meson-$(MESON_VERSION),meson)

ifneq ($(wildcard $(BUILD_WORK)/meson/.build_complete),)
meson:
	@echo "Using previously built meson."
else
meson: meson-setup python3 ninja
	cd $(BUILD_WORK)/meson && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/meson" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/meson -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

meson-package: meson-stage
	# meson.mk Package Structure
	rm -rf $(BUILD_DIST)/meson
	cp -a $(BUILD_STAGE)/meson $(BUILD_DIST)

	# meson.mk Sign
	$(call SIGN,meson,general.xml)

	# meson.mk Make .debs
	$(call PACK,meson,DEB_MESON_V)

	# meson.mk Build Cleanup
	rm -rf $(BUILD_DIST)/meson

.PHONY: meson meson-package
