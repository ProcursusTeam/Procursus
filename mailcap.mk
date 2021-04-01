ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += mailcap
MAILCAP_VERSION := 3.69
DEB_MAILCAP_V   ?= $(MAILCAP_VERSION)

mailcap-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/debian/mailcap/-/archive/$(MAILCAP_VERSION)/mailcap-$(MAILCAP_VERSION).tar.gz
	$(call EXTRACT_TAR,mailcap-$(MAILCAP_VERSION).tar.gz,mailcap-$(MAILCAP_VERSION),mailcap)
	$(call DO_PATCH,mailcap,mailcap,-p1)

ifneq ($(wildcard $(BUILD_WORK)/mailcap/.build_complete),)
mailcap:
	@echo "Using previously built mailcap."
else
mailcap: mailcap-setup
	+$(MAKE) -C $(BUILD_WORK)/mailcap install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		SYSCONFDIR=$(MEMO_PREFIX)/etc \
		DESTDIR=$(BUILD_STAGE)/mailcap
	touch $(BUILD_WORK)/mailcap/.build_complete
endif

mailcap-package: mailcap-stage
	# mailcap.mk Package Structure
	rm -rf $(BUILD_DIST)/mailcap
	mkdir -p $(BUILD_DIST)/mailcap
	
	# mailcap.mk Prep mailcap
	cp -a $(BUILD_STAGE)/mailcap $(BUILD_DIST)
	
	# mailcap.mk Make .debs
	$(call PACK,mailcap,DEB_MAILCAP_V)
	
	# mailcap.mk Build cleanup
	rm -rf $(BUILD_DIST)/mailcap

.PHONY: mailcap mailcap-package
