ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tcpdump
TCPDUMP_VERSION := 4.99.0
DEB_TCPDUMP_V   ?= $(TCPDUMP_VERSION)

tcpdump-setup: setup
	$(call GITHUB_ARCHIVE,the-tcpdump-group,tcpdump,$(TCPDUMP_VERSION),tcpdump-$(TCPDUMP_VERSION))
	$(call EXTRACT_TAR,tcpdump-$(TCPDUMP_VERSION).tar.gz,tcpdump-$(TCPDUMP_VERSION),tcpdump)
	$(call DO_PATCH,tcpdump,tcpdump,-p1)

ifneq ($(wildcard $(BUILD_WORK)/tcpdump/.build_complete),)
tcpdump:
	@echo "Using previously built tcpdump."
else
tcpdump: tcpdump-setup
	cd $(BUILD_WORK)/tcpdump && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/tcpdump
	+$(MAKE) -C $(BUILD_WORK)/tcpdump install \
		DESTDIR=$(BUILD_STAGE)/tcpdump
	touch $(BUILD_WORK)/tcpdump/.build_complete
endif

tcpdump-package: tcpdump-stage
	# tcpdump.mk Package Structure
	rm -rf $(BUILD_DIST)/tcpdump
	mkdir -p $(BUILD_DIST)/tcpdump
	
	# tcpdump.mk Prep tcpdump
	cp -a $(BUILD_STAGE)/tcpdump $(BUILD_DIST)
	
	# tcpdump.mk Sign
	$(call SIGN,tcpdump,general.xml)
	
	# tcpdump.mk Make .debs
	$(call PACK,tcpdump,DEB_TCPDUMP_V)
	
	# tcpdump.mk Build cleanup
	rm -rf $(BUILD_DIST)/tcpdump

.PHONY: tcpdump tcpdump-package
