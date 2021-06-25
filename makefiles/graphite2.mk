ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += graphite2
GRAPHITE2_VERSION := 1.3.14
DEB_GRAPHITE2_V   ?= $(GRAPHITE2_VERSION)

graphite2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/silnrsi/graphite/releases/download/$(GRAPHITE2_VERSION)/graphite2-$(GRAPHITE2_VERSION).tgz
	$(call EXTRACT_TAR,graphite2-$(GRAPHITE2_VERSION).tgz,graphite2-$(GRAPHITE2_VERSION),graphite2)

ifneq ($(wildcard $(BUILD_WORK)/graphite2/.build_complete),)
graphite2:
	@echo "Using previously built graphite2."
else
graphite2: graphite2-setup
	cd $(BUILD_WORK)/graphite2 && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/graphite2
	+$(MAKE) -C $(BUILD_WORK)/graphite2 install \
		DESTDIR=$(BUILD_STAGE)/graphite2
	+$(MAKE) -C $(BUILD_WORK)/graphite2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/graphite2/.build_complete
endif

graphite2-package: graphite2-stage
	# graphite2.mk Package Structure
	rm -rf $(BUILD_DIST)/libgraphite2-{3,utils,dev}
	mkdir -p $(BUILD_DIST)/libgraphite2-{3,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgraphite2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# graphite2.mk Prep libgraphite2-3
	cp -a $(BUILD_STAGE)/graphite2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgraphite2.3*.dylib $(BUILD_DIST)/libgraphite2-3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# graphite2.mk Prep libgraphite2-utils
	cp -a $(BUILD_STAGE)/graphite2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libgraphite2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# graphite2.mk Prep libgraphite2-dev
	cp -a $(BUILD_STAGE)/graphite2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libgraphite2.3*.dylib) $(BUILD_DIST)/libgraphite2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/graphite2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libgraphite2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# graphite2.mk Sign
	$(call SIGN,libgraphite2-3,general.xml)
	$(call SIGN,libgraphite2-utils,general.xml)

	# graphite2.mk Make .debs
	$(call PACK,libgraphite2-3,DEB_GRAPHITE2_V)
	$(call PACK,libgraphite2-utils,DEB_GRAPHITE2_V)
	$(call PACK,libgraphite2-dev,DEB_GRAPHITE2_V)

	# graphite2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgraphite2-{3,utils,dev}

.PHONY: graphite2 graphite2-package
