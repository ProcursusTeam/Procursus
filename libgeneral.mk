ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libgeneral
LIBGENERAL_VERSION := 32
DEB_LIBGENERAL_V   ?= $(LIBGENERAL_VERSION)-1

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
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/libgeneral
	+$(MAKE) -C $(BUILD_WORK)/libgeneral install \
		DESTDIR="$(BUILD_STAGE)/libgeneral"
	+$(MAKE) -C $(BUILD_WORK)/libgeneral install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgeneral/.build_complete
endif

libgeneral-package: libgeneral-stage
	# libgeneral.mk Package Structure
	rm -rf $(BUILD_DIST)/libgeneral{0,-dev}
	mkdir -p $(BUILD_DIST)/libgeneral{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libgeneral.mk Prep libgeneral0
	cp -a $(BUILD_STAGE)/libgeneral/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgeneral.0.dylib $(BUILD_DIST)/libgeneral0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libgeneral.mk Prep libgeneral-dev
	cp -a $(BUILD_STAGE)/libgeneral/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libgeneral.0.dylib) $(BUILD_DIST)/libgeneral-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgeneral/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgeneral-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libgeneral.mk Sign
	$(call SIGN,libgeneral0,general.xml)
	
	# libgeneral.mk Make .debs
	$(call PACK,libgeneral0,DEB_LIBGENERAL_V)
	$(call PACK,libgeneral-dev,DEB_LIBGENERAL_V)
	
	# libgeneral.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgeneral{0,-dev}

.PHONY: libgeneral libgeneral-package
