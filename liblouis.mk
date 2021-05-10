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
liblouis: liblouis-setup libyaml
	cd $(BUILD_WORK)/liblouis && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-ucs4
	+$(MAKE) -C $(BUILD_WORK)/liblouis all
	+$(MAKE) -C $(BUILD_WORK)/liblouis install \
		DESTDIR=$(BUILD_STAGE)/liblouis
	+$(MAKE) -C $(BUILD_WORK)/liblouis install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/liblouis/.build_complete
endif
liblouis-package: liblouis-stage
	# liblouis.mk Package Structure
	rm -rf $(BUILD_DIST)/liblouis{20,-dev,-data,-bin}
	mkdir -p $(BUILD_DIST)/liblouis{20,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/liblouis-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/liblouis-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tables

	# liblouis.mk Prep liblouis20
	cp -a $(BUILD_STAGE)/liblouis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblouis.20.dylib $(BUILD_DIST)/liblouis20/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liblouis.mk Prep liblouis-dev
	cp -a $(BUILD_STAGE)/liblouis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(liblouis.20.dylib) $(BUILD_DIST)/liblouis-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/liblouis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liblouis-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# liblouis.mk Prep liblouis-bin
	cp -a $(BUILD_STAGE)/liblouis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* $(BUILD_DIST)/liblouis-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# liblouis.mk Prep liblouis-data
	cp -a $(BUILD_STAGE)/liblouis/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/liblouis/tables $(BUILD_DIST)/liblouis-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tables
	# liblouis.mk Sign
	$(call SIGN,liblouis20,general.xml)
	
	# liblouis.mk Make .debs
	$(call PACK,liblouis20,DEB_LIBLOUIS_V)
	$(call PACK,liblouis-dev,DEB_LIBLOUIS_V)
	$(call PACK,liblouis-bin,DEB_LIBLOUIS_V)
	$(call PACK,liblouis-data,DEB_LIBLOUIS_V)

	# liblouis.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblouis{20,-dev,-bin,-data}

.PHONY: liblouis liblouis-package
