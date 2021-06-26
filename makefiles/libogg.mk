ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libogg
LIBOGG_VERSION := 1.3.4
DEB_LIBOGG_V   ?= $(LIBOGG_VERSION)

libogg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.xiph.org/releases/ogg/libogg-$(LIBOGG_VERSION).tar.xz
	$(call EXTRACT_TAR,libogg-$(LIBOGG_VERSION).tar.xz,libogg-$(LIBOGG_VERSION),libogg)

	# don't build the html docs
	$(SED) -ri 's/(SUBDIRS = .*)doc(.*)/\1 \2/' $(BUILD_WORK)/libogg/Makefile.in

	# Fix typedefs, remove in next version
	$(call DO_PATCH,libogg,libogg,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libogg/.build_complete),)
libogg:
	@echo "Using previously built libogg."
else
libogg: libogg-setup
	cd $(BUILD_WORK)/libogg && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/libogg
	+$(MAKE) -C $(BUILD_WORK)/libogg install \
		DESTDIR=$(BUILD_STAGE)/libogg
	+$(MAKE) -C $(BUILD_WORK)/libogg install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libogg/.build_complete
endif

libogg-package: libogg-stage
	# libogg.mk Package Structure
	rm -rf $(BUILD_DIST)/libogg{0,-dev}
	mkdir -p $(BUILD_DIST)/libogg{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libogg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libogg.mk Prep libogg0
	cp -a $(BUILD_STAGE)/libogg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libogg.0.dylib $(BUILD_DIST)/libogg0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libogg.mk Prep liblibogg-dev
	cp -a $(BUILD_STAGE)/libogg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libogg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libogg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libogg.{dylib,a} $(BUILD_DIST)/libogg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libogg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libogg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libogg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal $(BUILD_DIST)/libogg-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libogg.mk Sign
	$(call SIGN,libogg0,general.xml)

	# libogg.mk Make .debs
	$(call PACK,libogg0,DEB_LIBOGG_V)
	$(call PACK,libogg-dev,DEB_LIBOGG_V)

	# libogg.mk Build cleanup
	rm -rf $(BUILD_DIST)/libogg{0,-dev}

.PHONY: libogg libogg-package
