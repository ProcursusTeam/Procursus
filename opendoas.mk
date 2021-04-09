ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += opendoas
OPENDOAS_VERSION := 6.8.1
DEB_OPENDOAS_V   ?= $(OPENDOAS_VERSION)-1

opendoas-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/OpenDoas-$(OPENDOAS_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/OpenDoas-$(OPENDOAS_VERSION).tar.gz \
			https://github.com/Duncaen/OpenDoas/archive/v$(OPENDOAS_VERSION).tar.gz
	$(call EXTRACT_TAR,OpenDoas-$(OPENDOAS_VERSION).tar.gz,OpenDoas-$(OPENDOAS_VERSION),opendoas)
	$(call DO_PATCH,opendoas,opendoas,-p1)

ifneq ($(wildcard $(BUILD_WORK)/opendoas/.build_complete),)
opendoas:
	@echo "Using previously built opendoas."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
opendoas: opendoas-setup openpam
else # (,$(findstring darwin,$(MEMO_TARGET)))
opendoas: opendoas-setup
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/opendoas && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-pam
	+$(MAKE) -C $(BUILD_WORK)/opendoas
	+$(MAKE) -C $(BUILD_WORK)/opendoas install \
		DESTDIR=$(BUILD_STAGE)/opendoas
	mkdir -p $(BUILD_STAGE)/opendoas/$(MEMO_PREFIX)/etc/pam.d
	cp -a $(BUILD_MISC)/pam/doas $(BUILD_STAGE)/opendoas/$(MEMO_PREFIX)/etc/pam.d
	cp -a $(BUILD_MISC)/doas.conf $(BUILD_STAGE)/opendoas/$(MEMO_PREFIX)/etc/
	touch $(BUILD_WORK)/opendoas/.build_complete
endif 

opendoas-package: opendoas-stage
	# opendoas.mk Package Structure
	rm -rf $(BUILD_DIST)/opendoas
	
	# opendoas.mk Prep opendoas
	cp -a $(BUILD_STAGE)/opendoas $(BUILD_DIST)/doas
	
	# opendoas.mk Sign
	$(call SIGN,doas,general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_INFO)/pam.xml $(BUILD_DIST)/doas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/doas
	find $(BUILD_DIST)/doas -name '.ldid*' -type f -delete
endif
	
	# opendoas.mk Permissions
	$(FAKEROOT) chmod 4755 $(BUILD_DIST)/doas/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/doas
	
	# opendoas.mk Make .debs
	$(call PACK,doas,DEB_OPENDOAS_V)
	
	# opendoas.mk Build cleanup
	rm -rf $(BUILD_DIST)/doas

.PHONY: opendoas opendoas-package
