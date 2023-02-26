ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += r2ghidra
R2GHIDRA_VERSION   := 5.8.2
R2GHIDRA_GHIDRA_V  := 0.2.5
DEB_R2GHIDRA_V     ?= $(R2GHIDRA_VERSION)

r2ghidra-setup: setup
	$(call GITHUB_ARCHIVE,radareorg,r2ghidra,$(R2GHIDRA_VERSION),$(R2GHIDRA_VERSION))
	$(call EXTRACT_TAR,r2ghidra-$(R2GHIDRA_VERSION).tar.gz,r2ghidra-$(R2GHIDRA_VERSION),r2ghidra)
	$(call DO_PATCH,r2ghidra,r2ghidra,-p1)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/radareorg/ghidra-native/releases/download/$(R2GHIDRA_GHIDRA_V)/ghidra-native-$(R2GHIDRA_GHIDRA_V).zip)
	if [ ! -d $(BUILD_WORK)/r2ghidra/ghidra-native ]; then \
		unzip -q $(BUILD_SOURCE)/ghidra-native-$(R2GHIDRA_GHIDRA_V).zip -d $(BUILD_WORK)/r2ghidra; \
		mv $(BUILD_WORK)/r2ghidra/ghidra-native-$(R2GHIDRA_GHIDRA_V) $(BUILD_WORK)/r2ghidra/ghidra-native; \
	fi

ifneq ($(wildcard $(BUILD_WORK)/r2ghidra/.build_complete),)
r2ghidra:
	@echo "Using previously built r2ghidra."
else
r2ghidra: r2ghidra-setup radare2 libpugixml
	cd $(BUILD_WORK)/r2ghidra && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		R2_PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		R2_LIBR_PLUGINS="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/radare2/$(RADARE2_VERSION)" \
		R2_USER_PLUGINS="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/radare2/$(RADARE2_VERSION)" \
		PKGCONFIG="$(BUILD_TOOLS)/cross-pkg-config"
	+$(MAKE) -C $(BUILD_WORK)/r2ghidra
	+$(MAKE) -C $(BUILD_WORK)/r2ghidra install \
		DESTDIR="$(BUILD_STAGE)/r2ghidra"
	$(call AFTER_BUILD)
endif

r2ghidra-package: r2ghidra-stage
	# r2ghidra.mk Package Structure
	rm -rf $(BUILD_DIST)/r2ghidra

	# r2ghidra.mk Prep r2ghidra
	cp -a $(BUILD_STAGE)/r2ghidra $(BUILD_DIST)

	# r2ghidra.mk Sign
	$(call SIGN,r2ghidra,general.xml)

	# r2ghidra.mk Make .debs
	$(call PACK,r2ghidra,DEB_R2GHIDRA_V)

	# r2ghidra.mk Build cleanup
	rm -rf $(BUILD_DIST)/r2ghidra

.PHONY: r2ghidra r2ghidra-package
