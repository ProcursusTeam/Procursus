ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libjemalloc
LIBJEMALLOC_VERSION := 5.2.1
DEB_LIBJEMALLOC_V  	?= $(LIBJEMALLOC_VERSION)

libjemalloc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/jemalloc/jemalloc/releases/download/$(LIBJEMALLOC_VERSION)/jemalloc-$(LIBJEMALLOC_VERSION).tar.bz2
	$(call EXTRACT_TAR,jemalloc-$(LIBJEMALLOC_VERSION).tar.bz2,jemalloc-$(LIBJEMALLOC_VERSION),libjemalloc)

ifneq ($(wildcard $(BUILD_WORK)/libjemalloc/.build_complete),)
libjemalloc:
	@echo "Using previously built libjemalloc."
else
libjemalloc: libjemalloc-setup
	cd $(BUILD_WORK)/libjemalloc && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libjemalloc
	+$(MAKE) -C $(BUILD_WORK)/libjemalloc install \
		DESTDIR=$(BUILD_STAGE)/libjemalloc
	+$(MAKE) -C $(BUILD_WORK)/libjemalloc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libjemalloc/.build_complete
endif

libjemalloc-package: libjemalloc-stage
	# libjemalloc.mk Package Structure
	rm -rf $(BUILD_DIST)/libjemalloc{2,-dev}
	mkdir -p \
		$(BUILD_DIST)/libjemalloc2/usr/lib \
		$(BUILD_DIST)/libjemalloc-dev/usr/lib

	# libjemalloc.mk Prep libjemalloc2
	cp -a $(BUILD_STAGE)/libjemalloc/usr/lib/libjemalloc.2.dylib $(BUILD_DIST)/libjemalloc2/usr/lib/

	# libjemalloc.mk Prep libjemalloc-dev
	cp -a $(BUILD_STAGE)/libjemalloc/usr/lib/{pkgconfig,libjemalloc{_pic.a,.a,.dylib}} $(BUILD_DIST)/libjemalloc-dev/usr/lib
	cp -a $(BUILD_STAGE)/libjemalloc/usr/{bin,include,share} $(BUILD_DIST)/libjemalloc-dev/usr


	# libjemalloc.mk Sign
	$(call SIGN,libjemalloc2,general.xml)

	# libjemalloc.mk Make .debs
	$(call PACK,libjemalloc2,DEB_LIBJEMALLOC_V)
	$(call PACK,libjemalloc-dev,DEB_LIBJEMALLOC_V)

	# libjemalloc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libjemalloc{2,-dev}

.PHONY: libjemalloc libjemalloc-package
