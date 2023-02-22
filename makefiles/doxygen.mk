ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += doxygen
DOXYGEN_VERSION := 1.9.5
DEB_DOXYGEN_V   ?= $(DOXYGEN_VERSION)

doxygen-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://doxygen.nl/files/doxygen-$(DOXYGEN_VERSION).src.tar.gz)
	$(call EXTRACT_TAR,doxygen-$(DOXYGEN_VERSION).src.tar.gz,doxygen-$(DOXYGEN_VERSION),doxygen)
	sed -i -e 's/-mmacosx-version-min=\$${MACOS_VERSION_MIN}//' -e '/CMAKE_OSX_DEPLOYMENT_TARGET/d' $(BUILD_WORK)/doxygen/CMakeLists.txt

ifneq ($(wildcard $(BUILD_WORK)/doxygen/.build_complete),)
doxygen:
	@echo "Using previously built doxygen."
else
doxygen: doxygen-setup gettext
	cd $(BUILD_WORK)/doxygen && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DFLEX_EXECUTABLE="$(shell which flex)"
	+$(MAKE) -C $(BUILD_WORK)/doxygen
	+$(MAKE) -C $(BUILD_WORK)/doxygen install \
		DESTDIR=$(BUILD_STAGE)/doxygen
	$(call AFTER_BUILD)
endif

doxygen-package: doxygen-stage
	# doxygen.mk Package Structure
	rm -rf $(BUILD_DIST)/doxygen

	# doxygen.mk Prep doxygen
	cp -a $(BUILD_STAGE)/doxygen $(BUILD_DIST)

	# doxygen.mk Sign
	$(call SIGN,doxygen,general.xml)

	# doxygen.mk Make .debs
	$(call PACK,doxygen,DEB_DOXYGEN_V)

	# doxygen.mk Build cleanup
	rm -rf $(BUILD_DIST)/doxygen

.PHONY: doxygen doxygen-package
