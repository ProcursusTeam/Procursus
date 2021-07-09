ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tcpdump
TCPDUMP_VERSION := 4.99.1
DEB_TCPDUMP_V   ?= $(TCPDUMP_VERSION)

tcpdump-setup: setup
	$(call GITHUB_ARCHIVE,the-tcpdump-group,tcpdump,$(TCPDUMP_VERSION),tcpdump-$(TCPDUMP_VERSION))
	$(call EXTRACT_TAR,tcpdump-$(TCPDUMP_VERSION).tar.gz,tcpdump-tcpdump-$(TCPDUMP_VERSION),tcpdump)
	sed -i '1s/^/\#include \<sys\/_endian\.h\>/' $(BUILD_WORK)/tcpdump/*.c
	mkdir -p $(BUILD_WORK)/tcpdump/build

ifneq ($(wildcard $(BUILD_WORK)/tcpdump/.build_complete),)
tcpdump:
	@echo "Using previously built tcpdump."
else
tcpdump: tcpdump-setup
	cd $(BUILD_WORK)/tcpdump/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DENABLE_SMB=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/tcpdump/build
	+$(MAKE) -C $(BUILD_WORK)/tcpdump/build install \
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
