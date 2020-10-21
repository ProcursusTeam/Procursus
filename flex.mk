ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += flex
FLEX_VERSION := 2.6.4
DEB_FLEX_V   ?= $(FLEX_VERSION)

flex-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/westes/flex/releases/download/v$(FLEX_VERSION)/flex-$(FLEX_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,flex-$(FLEX_VERSION).tar.gz,sin)
	$(call EXTRACT_TAR,flex-$(FLEX_VERSION).tar.gz,flex-$(FLEX_VERSION),flex)

ifneq ($(wildcard $(BUILD_WORK)/flex/.build_complete),)
flex:
	@echo "Using previously built flex."
else
flex: flex-setup 
	cd $(BUILD_WORK)/flex && ./configure -C \
	--build=aarch64-apple-darwin \
		--host=aarch64-apple-darwin \
		--prefix=/usr 
		+$(MAKE) -C $(BUILD_WORK)/flex
	+$(MAKE) -C $(BUILD_WORK)/flex install \
		DESTDIR="$(BUILD_STAGE)/flex"
	+$(MAKE) -C $(BUILD_WORK)/flex install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/flex/.build_complete
endif

flex-package: flex-stage
	# flex.mk Package Structure
	rm -rf $(BUILD_DIST)/flex
	mkdir -p $(BUILD_DIST)/flex
	
	# flex.mk Prep flex
	cp -a $(BUILD_STAGE)/flex/usr $(BUILD_DIST)/flex
	
	# flex.mk Sign
	$(call SIGN,flex,general.xml)
	
	# flex.mk Make .debs
	$(call PACK,flex,DEB_FLEX_V)
	
	# flex.mk Build cleanup
	rm -rf $(BUILD_DIST)/flex
	
.PHONY: flex flex-package
