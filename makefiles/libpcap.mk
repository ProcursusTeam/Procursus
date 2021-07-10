ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libpcap
LIBPCAP_VERSION := 1.10.1
DEB_LIBPCAP_V   ?= $(LIBPCAP_VERSION)

libpcap-setup: setup
	$(call GITHUB_ARCHIVE,the-tcpdump-group,libpcap,$(LIBPCAP_VERSION),libpcap-$(LIBPCAP_VERSION))
	$(call EXTRACT_TAR,libpcap-$(LIBPCAP_VERSION).tar.gz,libpcap-libpcap-$(LIBPCAP_VERSION),libpcap)
	mkdir -p $(BUILD_WORK)/libpcap/build
	sed -i '1s/^/\#include \<sys\/_endian\.h\>/' $(BUILD_WORK)/libpcap/*.c

ifneq ($(wildcard $(BUILD_WORK)/libpcap/.build_complete),)
libpcap:
	@echo "Using previously built libpcap."
else
libpcap: libpcap-setup openssl
	cd $(BUILD_WORK)/libpcap/build && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DINET6=ON \
		-DPCAP_TYPE=bpf \
		..
	+$(MAKE) -C $(BUILD_WORK)/libpcap/build
	+$(MAKE) -C $(BUILD_WORK)/libpcap/build install \
		DESTDIR=$(BUILD_STAGE)/libpcap
	+$(MAKE) -C $(BUILD_WORK)/libpcap/build install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libpcap/.build_complete
endif

libpcap-package: libpcap-stage
	# libpcap.mk Package Structure
	rm -rf $(BUILD_DIST)/{libpcap0.8{,-dev}
	mkdir -p $(BUILD_DIST)/libpcap0.8{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	
	# libpcap.mk Prep libpcap0.8
	cp -a $(BUILD_STAGE)/libpcap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpcap.*.dylib $(BUILD_DIST)/libpcap0.8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	
	# libpcap.mk Prep libpcap0.8-dev
	cp -a $(BUILD_STAGE)/libpcap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include} $(BUILD_DIST)/libpcap0.8-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libpcap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/!(libpcap.*.dylib) $(BUILD_DIST)/libpcap0.8-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libpcap.mk Sign
	$(call SIGN,libpcap0.8,general.xml)
	$(call SIGN,libpcap0.8-dev,general.xml)
	
	# libpcap.mk Make .debs
	$(call PACK,libpcap0.8,DEB_LIBPCAP_V)
	$(call PACK,libpcap0.8-dev,DEB_LIBPCAP_V)
	
	# libpcap.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libpcap0.8{,-dev}

.PHONY: libpcap libpcap-package
