ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += meson
MESON_VERSION := 0.58.0
DEB_MESON_V   ?= $(MESON_VERSION)

meson-setup: setup
	$(call GITHUB_ARCHIVE,mesonbuild,meson,$(MESON_VERSION),$(MESON_VERSION))
	$(call EXTRACT_TAR,meson-$(MESON_VERSION).tar.gz,meson-$(MESON_VERSION),meson)

ifneq ($(wildcard $(BUILD_WORK)/meson/.build_complete),)
meson:
	@echo "Using previously built meson."
else
meson: meson-setup python3 ninja
	cd $(BUILD_WORK)/meson && python$(PYTHON3_MAJOR_V) ./setup.py \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/meson"
	# Do some pre-preparation stuff
	mkdir -p $(BUILD_STAGE)/meson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/
	rm -rf $(BUILD_STAGE)/meson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/site-packages/mesonbuild/__pycache__
	mv $(BUILD_STAGE)/meson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/site-packages \
		$(BUILD_STAGE)/meson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages
	rm -rf $(BUILD_STAGE)/meson/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)
	touch $(BUILD_WORK)/meson/.build_complete
endif

meson-package: meson-stage
	# meson.mk Package Structure
	cp -a $(BUILD_STAGE)/meson $(BUILD_DIST)

	# meson.mk Sign
	$(call SIGN,meson,general.xml)

	# meson.mk Make .debs
	$(call PACK,meson,DEB_MESON_V)

	# meson.mk Build Cleanup
	rm -rf $(BUILD_DIST)/meson

.PHONY: meson meson-package
