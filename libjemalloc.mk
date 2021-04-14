ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libjemalloc
LIBJEMALLOC_VERSION := 5.2.1
DEB_LIBJEMALLOC_V  	?= $(LIBJEMALLOC_VERSION)-2

libjemalloc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/jemalloc/jemalloc/releases/download/$(LIBJEMALLOC_VERSION)/jemalloc-$(LIBJEMALLOC_VERSION).tar.bz2
	$(call EXTRACT_TAR,jemalloc-$(LIBJEMALLOC_VERSION).tar.bz2,jemalloc-$(LIBJEMALLOC_VERSION),libjemalloc)
	$(call DO_PATCH,jemalloc,libjemalloc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/libjemalloc/.build_complete),)
libjemalloc:
	@echo "Using previously built libjemalloc."
else
libjemalloc: libjemalloc-setup
	cd $(BUILD_WORK)/libjemalloc && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-lg-page=14 \
		--with-jemalloc-prefix=
		# The above system page size is specified because
		# iOS arm64 devices have a 16KB page size.
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
		$(BUILD_DIST)/libjemalloc2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libjemalloc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libjemalloc.mk Prep libjemalloc2
	cp -a $(BUILD_STAGE)/libjemalloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjemalloc.2.dylib $(BUILD_DIST)/libjemalloc2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libjemalloc.mk Prep libjemalloc-dev
	cp -a $(BUILD_STAGE)/libjemalloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libjemalloc{_pic.a,.a,.dylib}} $(BUILD_DIST)/libjemalloc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libjemalloc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,share} $(BUILD_DIST)/libjemalloc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)


	# libjemalloc.mk Sign
	$(call SIGN,libjemalloc2,general.xml)

	# libjemalloc.mk Make .debs
	$(call PACK,libjemalloc2,DEB_LIBJEMALLOC_V)
	$(call PACK,libjemalloc-dev,DEB_LIBJEMALLOC_V)

	# libjemalloc.mk Build cleanup
	rm -rf $(BUILD_DIST)/libjemalloc{2,-dev}

.PHONY: libjemalloc libjemalloc-package
