ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += kakoune
KAKOUNE_VERSION := 2021.11.08
DEB_KAKOUNE_V   ?= $(KAKOUNE_VERSION)

kakoune-setup: setup
	$(call GITHUB_ARCHIVE,mawww,kakoune,$(KAKOUNE_VERSION),v$(KAKOUNE_VERSION))
	$(call EXTRACT_TAR,kakoune-$(KAKOUNE_VERSION).tar.gz,kakoune-$(KAKOUNE_VERSION),kakoune)

ifneq ($(wildcard $(BUILD_WORK)/kakoune/.build_complete),)
kakoune:
	@echo "Using previously built kakoune."
else
kakoune: kakoune-setup
	+$(MAKE) -C $(BUILD_WORK)/kakoune \
		CXX="$(CXX)" \
		LDFLAGS="$(patsubst -L/opt/local/lib,,$(LDFLAGS))"
	+$(MAKE) -C $(BUILD_WORK)/kakoune install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/kakoune"
	$(call AFTER_BUILD)
endif

kakoune-package: kakoune-stage
	# kakoune.mk Package Structure
	rm -rf $(BUILD_DIST)/kakoune

	# kakoune.mk Prep kakoune
	cp -a $(BUILD_STAGE)/kakoune $(BUILD_DIST)

	# kakoune.mk Sign
	$(call SIGN,kakoune,general.xml)

	# kakoune.mk Make .debs
	$(call PACK,kakoune,DEB_KAKOUNE_V)

	# kakoune.mk Build cleanup
	rm -rf $(BUILD_DIST)/kakoune

.PHONY: kakoune kakoune-package
