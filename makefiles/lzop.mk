ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += lzop
LZOP_VERSION := 1.04
DEB_LZOP_V   ?= $(LZOP_VERSION)

lzop-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.lzop.org/download/lzop-$(LZOP_VERSION).tar.gz
	$(call EXTRACT_TAR,lzop-$(LZOP_VERSION).tar.gz,lzop-$(LZOP_VERSION),lzop)

ifneq ($(wildcard $(BUILD_WORK)/lzop/.build_complete),)
lzop:
	@echo "Using previously built lzop."
else
lzop: lzop-setup liblzo2
	cd $(BUILD_WORK)/lzop && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/lzop
	+$(MAKE) -C $(BUILD_WORK)/lzop install \
		DESTDIR=$(BUILD_STAGE)/lzop
	touch $(BUILD_WORK)/lzop/.build_complete
endif

lzop-package: lzop-stage
	# lzop.mk Package Structure
	rm -rf $(BUILD_DIST)/lzop

	# lzop.mk Prep lzop
	cp -a $(BUILD_STAGE)/lzop $(BUILD_DIST)

	# lzop.mk Sign
	$(call SIGN,lzop,general.xml)

	# lzop.mk Make .debs
	$(call PACK,lzop,DEB_LZOP_V)

	# lzop.mk Build cleanup
	rm -rf $(BUILD_DIST)/lzop

.PHONY: lzop lzop-package
