ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += tsschecker
TSSCHECKER_VERSION := 333
TSSCHECKER_COMMIT  := 6904e4a220358fd1fbaa134b0301ed2fc2e77130
DEB_TSSCHECKER_V   ?= $(TSSCHECKER_VERSION)

tsschecker-setup: setup
	$(call GITHUB_ARCHIVE,1Conan,tsschecker,$(TSSCHECKER_COMMIT),$(TSSCHECKER_COMMIT))
	$(call GITHUB_ARCHIVE,tihmstar,jssy,master,master)
	$(call EXTRACT_TAR,tsschecker-$(TSSCHECKER_COMMIT).tar.gz,tsschecker-$(TSSCHECKER_COMMIT),tsschecker)
	# so EXTRACT_TAR wont fail
	-rmdir $(BUILD_WORK)/tsschecker/external/jssy
	$(call EXTRACT_TAR,jssy-master.tar.gz,jssy-master,tsschecker/external/jssy)

	$(SED) -i 's/git rev\-list \-\-count HEAD/printf ${TSSCHECKER_VERSION}/g' $(BUILD_WORK)/tsschecker/configure.ac
	$(SED) -i 's/git rev\-parse HEAD/printf ${TSSCHECKER_COMMIT}/g' $(BUILD_WORK)/tsschecker/configure.ac


ifneq ($(wildcard $(BUILD_WORK)/tsschecker/.build_complete),)
tsschecker:
	@echo "Using previously built tsschecker."
else
tsschecker: tsschecker-setup libfragmentzip libplist curl libirecovery
	cd $(BUILD_WORK)/tsschecker && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/tsschecker
	+$(MAKE) -C $(BUILD_WORK)/tsschecker install \
		DESTDIR="$(BUILD_STAGE)/tsschecker"
	touch $(BUILD_WORK)/tsschecker/.build_complete
endif

tsschecker-package: tsschecker-stage
	# tsschecker.mk Package Structure
	rm -rf $(BUILD_DIST)/tsschecker

	# tsschecker.mk Prep tsschecker
	cp -a $(BUILD_STAGE)/tsschecker $(BUILD_DIST)

	# tsschecker.mk Sign
	$(call SIGN,tsschecker,general.xml)

	# tsschecker.mk Make .debs
	$(call PACK,tsschecker,DEB_TSSCHECKER_V)

	# tsschecker.mk Build cleanup
	rm -rf $(BUILD_DIST)/tsschecker

.PHONY: tsschecker tsschecker-package
