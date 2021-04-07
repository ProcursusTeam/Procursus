ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += apr-util
APR-UTIL_VERSION  := 1.6.1
DEB_APR-UTIL_V    ?= $(APR-UTIL_VERSION)

apr-util-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.apache.org//apr/apr-util-$(APR-UTIL_VERSION).tar.bz2
	$(call EXTRACT_TAR,apr-util-$(APR-UTIL_VERSION).tar.bz2,apr-util-$(APR-UTIL_VERSION),apr-util)

ifneq ($(wildcard $(BUILD_WORK)/apr-util/.build_complete),)
apr-util:
	@echo "Using previously built apr-util."
else
apr-util: apr-util-setup apr
	cd $(BUILD_WORK)/apr-util && ./configure -C \
	--with-apr=$(BUILD_WORK)/apr \
			--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/apr-util
	+$(MAKE) -C $(BUILD_WORK)/apr-util install \
		DESTDIR=$(BUILD_BASE)
		+$(MAKE) -C $(BUILD_WORK)/apr-util install \
		DESTDIR=$(BUILD_STAGE)/apr-util
	+$(MAKE) -C $(BUILD_WORK)/apr-util install \
		DESTDIR="$(BUILD_BASE)"
	ln -s $(BUILD_STAGE)/apr-tuil/$MEMO_PREFIX)$MEMO_SUB_PREFIX)/apu-1-config $(BUILD_STAGE)/apr-util/$MEMO_PREFIX)$MEMO_SUB_PREFIX)/apu-config
	touch $(BUILD_WORK)/apr-util/.build_complete
endif
apr-util-package: apr-util-stage
	# apr-util.mk Package Structure
	rm -rf $(BUILD_DIST)/libaprutil1{,-dev}
	mkdir -p  $(BUILD_DIST)/libaprutil1{,-dev}
	
	# apr-util.mk Prep libaprutil1
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaprutil.1.dylib $(BUILD_DIST)/libaprutil1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# apr-util.mk Prep libaprutil1-dev
	cp -a $(BUILD_STAGE)/apr-util/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include} $(BUILD_DIST)/libaprutil1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	
	# apr-util.mk Sign
	$(call SIGN,libaprutil1,general.xml)
	
	# apr-util.mk Make .debs
	$(call PACK,libaprutil1,DEB_APR-UTIL_V)
	$(call PACK,libaprutil1-dev,DEB_APR-UTIL_V)
	
	# apr-util.mk Build cleanup
	rm -rf $(BUILD_DIST)/apr-util

	.PHONY: apr-util apr-util-package
