ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += ldns
LDNS_VERSION := 1.7.1
DEB_LDNS_V   ?= $(LDNS_VERSION)

ldns-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://nlnetlabs.nl/downloads/ldns/ldns-$(LDNS_VERSION).tar.gz
	$(call EXTRACT_TAR,ldns-$(LDNS_VERSION).tar.gz,ldns-release-$(LDNS_VERSION),ldns)

ifneq ($(wildcard $(BUILD_WORK)/ldns/.build_complete),)
ldns:
	@echo "Using previously built ldns."
else
ldns: ldns-setup
	cd $(BUILD_WORK)/ldns && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-drill \
		--with-examples \
		--with-ssl \
		--with-pyldns \
		--disable-dane-verify
	+$(MAKE) -C $(BUILD_WORK)/ldns
	+$(MAKE) -C $(BUILD_WORK)/ldns install \
		DESTDIR=$(BUILD_STAGE)/ldns
	$(call AFTER_BUILD)
endif

ldns-package: ldns-stage
	# ldns.mk Package Structure
	rm -rf $(BUILD_DIST)/ldns

	# ldns.mk Prep ldns
	cp -a $(BUILD_STAGE)/ldns $(BUILD_DIST)

	# ldns.mk Sign
	$(call SIGN,ldns,general.xml)

	# ldns.mk Make .debs
	$(call PACK,ldns,DEB_LDNS_V)

	# ldns.mk Build cleanup
	rm -rf $(BUILD_DIST)/ldns

.PHONY: ldns ldns-package
