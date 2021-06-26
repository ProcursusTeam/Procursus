ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libao
LIBAO_VERSION := 1.2.2
DEB_LIBAO_V   ?= $(LIBAO_VERSION)

libao-setup: setup
	$(call GITHUB_ARCHIVE,xiph,libao,$(LIBAO_VERSION),$(LIBAO_VERSION))
	$(call EXTRACT_TAR,libao-$(LIBAO_VERSION).tar.gz,libao-$(LIBAO_VERSION),libao)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,libao-ios,libao,-p1)
endif

ifneq ($(wildcard $(BUILD_WORK)/libao/.build_complete),)
libao:
	@echo "Using previously built libao."
else
libao: libao-setup libsoundio
	cd $(BUILD_WORK)/libao && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	# fails on ios Otherwise
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's/-framework AudioUnit//' $(BUILD_WORK)/libao/src/plugins/macosx/Makefile
endif

	+$(MAKE) -C $(BUILD_WORK)/libao
	+$(MAKE) -C $(BUILD_WORK)/libao install \
		DESTDIR=$(BUILD_STAGE)/libao
	+$(MAKE) -C $(BUILD_WORK)/libao install \
		DESTDIR=$(BUILD_BASE)

	mkdir -p $(BUILD_STAGE)/libao/$(MEMO_PREFIX)/etc
	echo "default_driver=macosx\nquiet" > $(BUILD_STAGE)/libao/$(MEMO_PREFIX)/etc/libao.conf

	touch $(BUILD_WORK)/libao/.build_complete
endif

libao-package: libao-stage
	# libao.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libao{4,-{dev,common}}
	mkdir -p \
		$(BUILD_DIST)/libao{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libao-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libao.mk Prep libao4-common
	cp -a $(BUILD_STAGE)/libao/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libao-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libao/$(MEMO_PREFIX)/etc $(BUILD_DIST)/libao-common/$(MEMO_PREFIX)

	# libao.mk Prep libao4
	cp -a $(BUILD_STAGE)/libao/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libao.4.dylib,ao} $(BUILD_DIST)/libao4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# libao.mk Prep libao-dev
	cp -a $(BUILD_STAGE)/libao/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libao.dylib $(BUILD_DIST)/libao-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libao/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libao-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libao.mk Sign
	$(call SIGN,libao4,general.xml)

	# libao.mk Make .debs
	$(call PACK,libao4,DEB_LIBAO_V)
	$(call PACK,libao-dev,DEB_LIBAO_V)
	$(call PACK,libao-common,DEB_LIBAO_V)

	# libao.mk Build cleanup
	rm -rf $(BUILD_DIST)/libao{4,-{dev,common}}

.PHONY: libao libao-package
