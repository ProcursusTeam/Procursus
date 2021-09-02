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
	$(call AFTER_BUILD,copy)
endif

libpcap-package: libpcap-stage
	# libpcap.mk Package Structure
	rm -rf $(BUILD_DIST)/libpcapa{,-dev}
	mkdir -p $(BUILD_DIST)/libpcapa{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libpcap.mk Prep libpcapa
	cp -a $(BUILD_STAGE)/libpcap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpcap.*.dylib $(BUILD_DIST)/libpcapa/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	
	# libpcap.mk Prep libpcapa-dev
	cp -a $(BUILD_STAGE)/libpcap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,share} $(BUILD_DIST)/libpcapa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libpcap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libpcap.*.dylib) $(BUILD_DIST)/libpcapa-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libpcap.mk Sign
	$(call SIGN,libpcapa,general.xml)
	$(call SIGN,libpcapa-dev,general.xml)
	
	# libpcap.mk Make .debs
	$(call PACK,libpcapa,DEB_LIBPCAP_V)
	$(call PACK,libpcapa-dev,DEB_LIBPCAP_V)
	
	# libpcap.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpcapa{,-dev}

.PHONY: libpcap libpcap-package
