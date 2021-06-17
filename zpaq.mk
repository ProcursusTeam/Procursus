ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += zpaq
ZPAQ_VERSION := 7.15
DEB_ZPAQ_V   ?= $(ZPAQ_VERSION)

zpaq-setup: setup
	$(call GITHUB_ARCHIVE,zpaq,zpaq,$(ZPAQ_VERSION),$(ZPAQ_VERSION))
	$(call EXTRACT_TAR,zpaq-$(ZPAQ_VERSION).tar.gz,zpaq-$(ZPAQ_VERSION),zpaq)

ifneq ($(MEMO_ARCH),x86_64)
ZPAQ_CPPFLAGS := -DNOJIT
endif

ifneq ($(wildcard $(BUILD_WORK)/zpaq/.build_complete),)
zpaq:
	@echo "Using previously built zpaq."
else
zpaq: zpaq-setup
	+$(MAKE) -C $(BUILD_WORK)/zpaq \
		CXX=$(CXX) \
		CPPFLAGS="$(CPPFLAGS) -Dunix $(ZPAQ_CPPFLAGS)" \
		CXXFLAGS="$(CXXFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/zpaq install \
		PREFIX=$(BUILD_STAGE)/zpaq/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/zpaq install \
		PREFIX=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/zpaq/.build_complete
endif
zpaq-package: zpaq-stage
	# zpaq.mk Package Structure
	rm -rf $(BUILD_DIST)/zpaq
	
	# zpaq.mk Prep zpaq
	cp -a $(BUILD_STAGE)/zpaq $(BUILD_DIST)
	
	# zpaq.mk Sign
	$(call SIGN,zpaq,general.xml)
	
	# zpaq.mk Make .debs
	$(call PACK,zpaq,DEB_ZPAQ_V)
	
	# zpaq.mk Build cleanup
	rm -rf $(BUILD_DIST)/zpaq

.PHONY: zpaq zpaq-package
