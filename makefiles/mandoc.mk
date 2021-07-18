ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mandoc
MANDOC_VERSION := 1.14.5
DEB_MANDOC_V   ?= $(MANDOC_VERSION)

mandoc-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://mandoc.bsd.lv/snapshots/mandoc-$(MANDOC_VERSION).tar.gz
	$(call EXTRACT_TAR,mandoc-$(MANDOC_VERSION).tar.gz,mandoc-$(MANDOC_VERSION),mandoc)
	echo -e "#!/bin/sh\n \
	PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"\n \
    INCLUDEDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include"\n \
    LIBDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib"\n \
    MANDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/man"\n \
    WWWPREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/var/www"\n \
    EXAMPLEDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/examples"\n" > $(BUILD_WORK)/mandoc/configure.local

ifneq ($(wildcard $(BUILD_WORK)/mandoc/.build_complete),)
mandoc:
	@echo "Using previously built mandoc."
else
mandoc: mandoc-setup
	cd $(BUILD_WORK)/mandoc && ./configure && ./configure.local -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/mandoc
	+$(MAKE) -C $(BUILD_WORK)/mandoc install \
		DESTDIR=$(BUILD_STAGE)/mandoc
	touch $(BUILD_WORK)/mandoc/.build_complete
endif

mandoc-package: mandoc-stage
	# mandoc.mk Package Structure
	rm -rf $(BUILD_DIST)/mandoc
	
	# mandoc.mk Prep mandoc
	cp -a $(BUILD_STAGE)/mandoc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/ $(BUILD_DIST)/mandoc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# mandoc.mk Sign
	$(call SIGN,mandoc,general.xml)
	
	# mandoc.mk Make .debs
	$(call PACK,mandoc,DEB_MANDOC_V)
	
	# mandoc.mk Build cleanup
	rm -rf $(BUILD_DIST)/mandoc

.PHONY: mandoc mandoc-package
