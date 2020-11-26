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
	cd $(BUILD_WORK)/graphite2 && cmake . -j$(shell $(GET_LOGICAL_CORES)) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
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
	mkdir -p $(BUILD_DIST)/libgraphite2-{3,dev}/usr/lib \
		$(BUILD_DIST)/libgraphite2-utils/usr
	
	# graphite2.mk Prep libgraphite2-3
	cp -a $(BUILD_STAGE)/graphite2/usr/lib/libgraphite2.3*.dylib $(BUILD_DIST)/libgraphite2-3/usr/lib

	# graphite2.mk Prep libgraphite2-utils
	cp -a $(BUILD_STAGE)/graphite2/usr/bin $(BUILD_DIST)/libgraphite2-utils/usr
	
	# graphite2.mk Prep libgraphite2-dev
	cp -a $(BUILD_STAGE)/graphite2/usr/lib/!(libgraphite2.3*.dylib) $(BUILD_DIST)/libgraphite2-dev/usr/lib
	cp -a $(BUILD_STAGE)/graphite2/usr/{include,share} $(BUILD_DIST)/libgraphite2-dev/usr
	
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
