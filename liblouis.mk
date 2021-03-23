ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += liblouis
LIBLOUIS_VERSION  := 3.17.0
DEB_LIBLOUIS_V    ?= $(LIBLOUIS_VERSION)

liblouis-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/liblouis/liblouis/releases/download/v$(LIBLOUIS_VERSION)/liblouis-$(LIBLOUIS_VERSION).tar.gz
	$(call EXTRACT_TAR,liblouis-$(LIBLOUIS_VERSION).tar.gz,liblouis-$(LIBLOUIS_VERSION),liblouis)
ifneq ($(wildcard $(BUILD_WORK)/liblouis/.build_complete),)
liblouis:
	@echo "Using previously built liblouis."
else
liblouis: liblouis-setup
	cd $(BUILD_WORK)/liblouis && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/liblouis all
	+$(MAKE) -C $(BUILD_WORK)/liblouis install \
		DESTDIR=$(BUILD_STAGE)/liblouis
		touch $(BUILD_WORK)/liblouis/.build_complete
endif
liblouis-package: liblouis-stage
	# liblouis.mk Package Structure
	rm -rf $(BUILD_DIST)/liblouis
		rm -rf $(BUILD_DIST)/liblouis-dev
		mkdir -p  $(BUILD_DIST)/liblouis20/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		mkdir -p  $(BUILD_DIST)/liblouis-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		
	# liblouis.mk Prep liblouis
	cp -a $(BUILD_STAGE)/liblouis $(BUILD_DIST)/liblouis
	# liblouis.mk Sign
	$(call SIGN,liblouis,general.xml)
	
	# liblouis.mk Make .debs
	$(call PACK,liblouis,DEB_LIBLOUIS_V)
	
	# liblouis.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblouis

	.PHONY: liblouis liblouis-package
