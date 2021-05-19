ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += xtrace
XTRACE_VERSION := 1.4.0
DEB_XTRACE_V   ?= $(XTRACE_VERSION)

xtrace-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/debian/xtrace/-/archive/xtrace-$(XTRACE_VERSION)/xtrace-xtrace-$(XTRACE_VERSION).tar.gz
	$(call EXTRACT_TAR,xtrace-xtrace-$(XTRACE_VERSION).tar.gz,xtrace-xtrace-$(XTRACE_VERSION),xtrace)

ifneq ($(wildcard $(BUILD_WORK)/xtrace/.build_complete),)
xtrace:
	@echo "Using previously built xtrace."
else
xtrace: xtrace-setup
	cd $(BUILD_WORK)/xtrace && autoreconf -i
	cd $(BUILD_WORK)/xtrace && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/xtrace
	+$(MAKE) -C $(BUILD_WORK)/xtrace install \
		DESTDIR=$(BUILD_STAGE)/xtrace
	touch $(BUILD_WORK)/xtrace/.build_complete
endif

xtrace-package: xtrace-stage
# xtrace.mk Package Structure
	rm -rf $(BUILD_DIST)/xtrace
	
# xtrace.mk Prep xtrace
	cp -a $(BUILD_STAGE)/xtrace $(BUILD_DIST)
	
# xtrace.mk Sign
	$(call SIGN,xtrace,general.xml)
	
# xtrace.mk Make .debs
	$(call PACK,xtrace,DEB_XTRACE_V)
	
# xtrace.mk Build cleanup
	rm -rf $(BUILD_DIST)/xtrace

.PHONY: xtrace xtrace-package
