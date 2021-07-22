ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += swig
SWIG_VERSION := 4.0.2
DEB_SWIG_V   ?= $(SWIG_VERSION)

swig-setup: setup
	$(call GITHUB_ARCHIVE,swig,swig,$(SWIG_VERSION),v$(SWIG_VERSION))
	$(call EXTRACT_TAR,swig-$(SWIG_VERSION).tar.gz,swig-$(SWIG_VERSION),swig)

ifneq ($(wildcard $(BUILD_WORK)/swig/.build_complete),)
swig:
	@echo "Using previously built swig."
else
swig: swig-setup
	cd $(BUILD_WORK)/swig && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-ccache
	+$(MAKE) -C $(BUILD_WORK)/swig
	+$(MAKE) -C $(BUILD_WORK)/swig install \
		DESTDIR=$(BUILD_STAGE)/swig4.0
	touch $(BUILD_WORK)/swig/.build_complete
endif

swig-package: swig-stage
	# swig.mk Package Structure
	rm -rf $(BUILD_DIST)/swig4.0
	mkdir -p $(BUILD_DIST)/swig4.0$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share}

	# swig.mk Prep swig
	cp -a $(BUILD_STAGE)/swig4.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/swig4.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# swig.mk Sign
	$(call SIGN,swig4.0,general.xml)

	# swig.mk Make .debs
	$(call PACK,swig4.0,DEB_SWIG_V)

	# swig.mk Build cleanup
	rm -rf $(BUILD_DIST)/swig

.PHONY: swig swig-package
