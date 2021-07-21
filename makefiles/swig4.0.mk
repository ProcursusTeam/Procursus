ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   	+= swig4.0
SWIG4.0_VERSION := 4.0.2
DEB_SWIG4.0_V   ?= $(SWIG4.0_VERSION)

swig4.0-setup: setup
	$(call GITHUB_ARCHIVE,swig,swig,$(SWIG4.0_VERSION),v$(SWIG4.0_VERSION))
	$(call EXTRACT_TAR,swig-$(SWIG4.0_VERSION).tar.gz,swig-$(SWIG4.0_VERSION),swig)

ifneq ($(wildcard $(BUILD_WORK)/swig/.build_complete),)
swig4.0:
	@echo "Using previously built swig4.0."
else
swig4.0: swig4.0-setup
	cd $(BUILD_WORK)/swig && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-ccache
	+$(MAKE) -C $(BUILD_WORK)/swig
	+$(MAKE) -C $(BUILD_WORK)/swig install \
		DESTDIR=$(BUILD_STAGE)/swig4.0
	touch $(BUILD_WORK)/swig/.build_complete
endif

swig4.0-package: swig4.0-stage
	# swig4.0.mk Package Structure
	rm -rf $(BUILD_DIST)/swig4.0

	# swig4.0.mk Prep swig4.0
	cp -a $(BUILD_STAGE)/swig4.0 $(BUILD_DIST)

	# swig4.0.mk Sign
	$(call SIGN,swig4.0,general.xml)

	# swig4.0.mk Make .debs
	$(call PACK,swig4.0,DEB_SWIG4.0_V)

	# swig4.0.mk Build cleanup
	rm -rf $(BUILD_DIST)/swig4.0

.PHONY: swig4.0 swig4.0-package
