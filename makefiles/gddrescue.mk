ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += gddrescue
GDDRESCUE_VERSION := 1.25
DEB_GDDRESCUE_V   ?= $(GDDRESCUE_VERSION)

gddrescue-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://mirror.keystealth.org/gnu/ddrescue/ddrescue-$(GDDRESCUE_VERSION).tar.lz{$(comma).sig})
	$(call PGP_VERIFY,ddrescue-$(GDDRESCUE_VERSION).tar.lz)
	$(call EXTRACT_TAR,ddrescue-$(GDDRESCUE_VERSION).tar.lz,ddrescue-$(GDDRESCUE_VERSION),gddrescue)

ifneq ($(wildcard $(BUILD_WORK)/gddrescue/.build_complete),)
gddrescue:
	@echo "Using previously built gddrescue."
else
gddrescue: gddrescue-setup
	cd $(BUILD_WORK)/gddrescue && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CXX="$(CXX)" \
		CPPFLAGS="$(CPPFLAGS)" \
		CXXFLAGS="$(CXXFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/gddrescue
	+$(MAKE) -C $(BUILD_WORK)/gddrescue install \
		DESTDIR=$(BUILD_STAGE)/gddrescue
	$(call AFTER_BUILD)
endif

gddrescue-package: gddrescue-stage
	# gddrescue.mk Package Structure
	rm -rf $(BUILD_DIST)/gddrescue

	# gddrescue.mk Prep gddrescue
	cp -a $(BUILD_STAGE)/gddrescue $(BUILD_DIST)

	# gddrescue.mk Sign
	$(call SIGN,gddrescue,general.xml)

	# gddrescue.mk Make .debs
	$(call PACK,gddrescue,DEB_GDDRESCUE_V)

	# gddrescue.mk Build cleanup
	rm -rf $(BUILD_DIST)/gddrescue

.PHONY: gddrescue gddrescue-package
