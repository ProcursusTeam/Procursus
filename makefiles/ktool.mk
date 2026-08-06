ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += ktool
KTOOL_VERSION := 1.4.0
KTOOL_COMMIT  := 596404b085af4f3c2406251ef3bbbc77b81a4981
DEB_KTOOL_V   ?= $(KTOOL_VERSION)

ktool-setup: setup
	$(call GITHUB_ARCHIVE,cxnder,ktool,$(KTOOL_COMMIT),$(KTOOL_COMMIT))
	$(call EXTRACT_TAR,ktool-$(KTOOL_COMMIT).tar.gz,ktool-$(KTOOL_COMMIT),ktool)
	$(call DO_PATCH,ktool,ktool,-p1)
	sed -i '9s|".*"|"$(DEB_KTOOL_V)"|' $(BUILD_WORK)/ktool/.legacy_setup.py
	sed -i "444s|@DEB_MAINTAINER@|$(DEB_MAINTAINER)|" $(BUILD_WORK)/ktool/src/ktool/ktool_script.py

ifneq ($(wildcard $(BUILD_WORK)/ktool/.build_complete),)
ktool:
	@echo "Using previously built ktool."
else
ktool: ktool-setup python3-kimg4 python3-pyaes pygments python3
	cd $(BUILD_WORK)/ktool && $(DEFAULT_SETUP_PY_ENV) python3 ./.legacy_setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/ktool" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	$(INSTALL) -Dm644 $(BUILD_MISC)/ktool/ktool.1 -t $(BUILD_STAGE)/ktool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	find $(BUILD_STAGE)/ktool -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

ktool-package: ktool-stage
	# ktool.mk Package Structure
	rm -rf $(BUILD_DIST)/ktool

	# ktool.mk Prep ktool
	cp -a $(BUILD_STAGE)/ktool $(BUILD_DIST)

	# ktool.mk Make .debs
	$(call PACK,ktool,DEB_KTOOL_V)

	# ktool.mk Build cleanup
	rm -rf $(BUILD_DIST)/ktool

.PHONY: ktool ktool-package
