ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += cpuminer
CPUMINER_VERSION := 2.5.1
DEB_CPUMINER_V   ?= $(CPUMINER_VERSION)

cpuminer-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/pooler/cpuminer/releases/download/v$(CPUMINER_VERSION)/pooler-cpuminer-$(CPUMINER_VERSION).tar.gz
	$(call EXTRACT_TAR,pooler-cpuminer-$(CPUMINER_VERSION).tar.gz,cpuminer-$(CPUMINER_VERSION),cpuminer)

ifneq ($(wildcard $(BUILD_WORK)/cpuminer/.build_complete),)
cpuminer:
	@echo "Using previously built cpuminer."
else
cpuminer: cpuminer-setup curl jansson
	cd $(BUILD_WORK)/cpuminer && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-assembly
	+$(MAKE) -C $(BUILD_WORK)/cpuminer install \
		DESTDIR="$(BUILD_STAGE)/cpuminer"
	touch $(BUILD_WORK)/cpuminer/.build_complete
endif

cpuminer-package: cpuminer-stage
	# cpuminer.mk Package Structure
	rm -rf $(BUILD_DIST)/cpuminer

	# cpuminer.mk Prep cpuminer
	cp -a $(BUILD_STAGE)/cpuminer $(BUILD_DIST)

	# cpuminer.mk Sign
	$(call SIGN,cpuminer,general.xml)

	# cpuminer.mk Make .debs
	$(call PACK,cpuminer,DEB_CPUMINER_V)

	# libgeneral.mk Build cleanup
	rm -rf $(BUILD_DIST)/cpuminer

.PHONY: cpuminer cpuminer-package
