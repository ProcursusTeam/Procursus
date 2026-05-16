ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += openldap
OPENLDAP_VERSION := 2.4.58
DEB_OPENLDAP_V   ?= $(OPENLDAP_VERSION)

openldap-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-$(OPENLDAP_VERSION).tgz
	$(call EXTRACT_TAR,openldap-$(OPENLDAP_VERSION).tgz,openldap-$(OPENLDAP_VERSION),openldap)

ifneq ($(wildcard $(BUILD_WORK)/openldap/.build_complete),)
openldap:
	@echo "Using previously built openldap."
else
openldap: openldap-setup libtool openssl
	cd $(BUILD_WORK)/openldap && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--localstatedir=$(MEMO_PREFIX)/var \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--with-yielding_select=no \
		--disable-bdb \
		--disable-hdb \
		--disable-mdb
				+$(MAKE) -C $(BUILD_WORK)/openldap depend
		+$(MAKE) -C $(BUILD_WORK)/openldap
	+$(MAKE) -C $(BUILD_WORK)/openldap install \
		DESTDIR=$(BUILD_STAGE)/openldap
	touch $(BUILD_WORK)/openldap/.build_complete
endif

openldap-package: openldap-stage
	# openldap.mk Package Structure
	rm -rf $(BUILD_DIST)/openldap
	mkdir -p $(BUILD_DIST)/openldap
	
	# openldap.mk Prep openldap
	cp -a $(BUILD_STAGE)/openldap $(BUILD_DIST)
	
	# openldap.mk Sign
	$(call SIGN,openldap,general.xml)
	
	# openldap.mk Make .debs
	$(call PACK,openldap,DEB_OPENLDAP_V)
	
	# openldap.mk Build cleanup
	rm -rf $(BUILD_DIST)/openldap

.PHONY: openldap openldap-package
	
