ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libgeneral
LIBGENERAL_VERSION := 31
DEB_LIBGENERAL_V   ?= $(LIBGENERAL_VERSION)

libgeneral-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/libgeneral/archive/$(LIBGENERAL_VERSION).tar.gz
	$(call EXTRACT_TAR,$(LIBGENERAL_VERSION).tar.gz,libgeneral-$(LIBGENERAL_VERSION),libgeneral)

ifneq ($(wildcard $(BUILD_WORK)/libgeneral/.build_complete),)
libgeneral:
	@echo "Using previously built libgeneral."
else
libgeneral: libgeneral-setup
	cd $(BUILD_WORK)/libgeneral && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking  
	+$(MAKE) -C $(BUILD_WORK)/libgeneral
	+$(MAKE) -C $(BUILD_WORK)/libgeneral install \
		DESTDIR="$(BUILD_STAGE)/libgeneral"
	+$(MAKE) -C $(BUILD_WORK)/libgeneral install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgeneral/.build_complete
endif

libgeneral-package: libgeneral-stage
	# libgeneral.mk Package Structure
	rm -rf $(BUILD_DIST)/libgeneral
	mkdir -p $(BUILD_DIST)/libgeneral
	
	# libgeneral.mk Prep libgeneral
	cp -a $(BUILD_STAGE)/libgeneral/usr $(BUILD_DIST)/libgeneral
	
	# libgeneral.mk Sign
	$(call SIGN,libgeneral,general.xml)
	
	# libgeneral.mk Make .debs
	$(call PACK,libgeneral,DEB_LIBGENERAL_V)
	
	# libgeneral.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgeneral

.PHONY: libgeneral libgeneral-package
