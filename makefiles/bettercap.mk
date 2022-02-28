ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += bettercap
BETTERCAP_VERSION  := 2.32.0
DEB_BETTERCAP_V    ?= $(BETTERCAP_VERSION)

bettercap-setup: setup
	$(call GITHUB_ARCHIVE,bettercap,bettercap,$(BETTERCAP_VERSION),v$(BETTERCAP_VERSION),bettercap)
	$(call EXTRACT_TAR,bettercap-$(BETTERCAP_VERSION).tar.gz,bettercap-$(BETTERCAP_VERSION),bettercap)
	mkdir -p $(BUILD_STAGE)/bettercap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifeq (,$(shell which go))
bettercap:
	@echo "go needs to be installed in order to compile bettercap. Please install go and try again."
else ifneq ($(wildcard $(BUILD_WORK)/bettercap/.build_complete),)
bettercap:
	@echo "Using previously built bettercap."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
bettercap: bettercap-setup libusb
else
bettercap: bettercap-setup libusb libpcap
endif
	$(MAKE) -C $(BUILD_WORK)/bettercap build \
		$(DEFAULT_GOLANG_FLAGS)

	$(MAKE) -C $(BUILD_WORK)/bettercap install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/bettercap

	$(call AFTER_BUILD)

endif

bettercap-package: bettercap-stage
	# bettercap.mk Package Structure
	rm -rf $(BUILD_DIST)/bettercap
	mkdir -p $(BUILD_DIST)/bettercap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bettercap.mk Prep bettercap
	cp -a $(BUILD_STAGE)/bettercap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/bettercap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bettercap.mk Sign
	$(call SIGN,bettercap,general.xml)

	# bettercap.mk Make .debs
	$(call PACK,bettercap,DEB_BETTERCAP_V)

	# bettercap.mk Build cleanup
	rm -rf $(BUILD_DIST)/bettercap

.PHONY: bettercap bettercap-package
