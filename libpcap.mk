ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libpcap
LIBPCAP_VERSION := 1.10.0
DEB_LIBPCAP_V   ?= $(LIBPCAP_VERSION)

libpcap-setup: setup
	$(call GITHUB_ARCHIVE,the-tcpdump-group,libpcap,$(LIBPCAP_VERSION),libpcap-$(LIBPCAP_VERSION))
	$(call EXTRACT_TAR,libpcap-$(LIBPCAP_VERSION).tar.gz,libpcap-$(LIBPCAP_VERSION),libpcap)
	$(call DO_PATCH,libpcap,libpcap,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libpcap/.build_complete),)
libpcap:
	@echo "Using previously built libpcap."
else
libpcap: libpcap-setup
	cd $(BUILD_WORK)/libpcap && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libpcap
	+$(MAKE) -C $(BUILD_WORK)/libpcap install \
		DESTDIR=$(BUILD_STAGE)/libpcap
	touch $(BUILD_WORK)/libpcap/.build_complete
endif

libpcap-package: libpcap-stage
	# libpcap.mk Package Structure
	rm -rf $(BUILD_DIST)/libpcap
	mkdir -p $(BUILD_DIST)/libpcap
	
	# libpcap.mk Prep libpcap
	cp -a $(BUILD_STAGE)/libpcap $(BUILD_DIST)
	
	# libpcap.mk Sign
	$(call SIGN,libpcap,general.xml)
	
	# libpcap.mk Make .debs
	$(call PACK,libpcap,DEB_LIBPCAP_V)
	
	# libpcap.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpcap

.PHONY: libpcap libpcap-package
