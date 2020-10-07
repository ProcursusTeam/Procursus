ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += cpuminer
CPUMINER_VERSION := 2.5.1
DEB_CPUMINER_V   ?= $(CPUMINER_VERSION)

cpuminer-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/pooler/cpuminer/releases/download/v$(CPUMINER_VERSION)/pooler-cpuminer-$(CPUMINER_VERSION).tar.gz
	$(call EXTRACT_TAR,pooler-cpuminer-$(CPUMINER_VERSION).tar.gz,cpuminer-$(CPUMINER_VERSION),cpuminer)

	
ifneq ($(wildcard $(BUILD_WORK)/cpuminer/.build_complete),)
cpuminer:
	@echo "Using previously built cpuminer."
else
cpuminer: cpuminer-setup curl
	cd $(BUILD_WORK)/cpuminer && ./configure \
	--host=$(GNU_HOST_TRIPLE) \
	--prefix=/usr \
	--disable-assembly
	+$(MAKE) -C $(BUILD_WORK)/cpuminer install \
		DESTDIR="$(BUILD_STAGE)/cpuminer"
	+$(MAKE) -C $(BUILD_WORK)/cpuminer install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/cpuminer.build_complete
endif

cpuminer-package: cpuminer-stage
	# cpuminer.mk Package Structure
	rm -rf $(BUILD_DIST)/cpuminer
	mkdir -p $(BUILD_DIST)/cpuminer
	
	# cpuminer.mk Prep cpuminer
	cp -a $(BUILD_STAGE)/cpuminer/usr $(BUILD_DIST)/cpuminer
	
	# cpuminer.mk Sign
	$(call SIGN,cpuminer,general.xml)
	
	# cpuminer.mk Make .debs
	$(call PACK,cpuminer,DEB_CPUMINER_V)
	
	# libgeneral.mk Build cleanup
	rm -rf $(BUILD_DIST)/cpuminer

	.PHONY: cpuminer cpuminer-package
