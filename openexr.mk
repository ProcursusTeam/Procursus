ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += openexr
OPENEXR_VERSION := 2.5.3
DEB_OPENEXR_V   ?= $(OPENEXR_VERSION)-1

openexr-setup: setup
	$(call GITHUB_ARCHIVE,openexr,openexr,$(OPENEXR_VERSION),v$(OPENEXR_VERSION))
	$(call EXTRACT_TAR,openexr-$(OPENEXR_VERSION).tar.gz,openexr-$(OPENEXR_VERSION),openexr)
ifneq ($(wildcard $(BUILD_WORK)/openexr/.build_complete),)
openexr:
	@echo "Using previously built openexr."
else
openexr: openexr-setup
	cd $(BUILD_WORK)/openexr/IlmBase && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_TESTING=OFF \
		.
	+$(MAKE) -C $(BUILD_WORK)/openexr/IlmBase install \
		DESTDIR="$(BUILD_STAGE)/ilmbase"
	+$(MAKE) -C $(BUILD_WORK)/openexr/IlmBase install \
		DESTDIR="$(BUILD_BASE)"

	cd $(BUILD_WORK)/openexr/OpenEXR && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		.
	+$(MAKE) -C $(BUILD_WORK)/openexr/OpenEXR install \
		DESTDIR="$(BUILD_STAGE)/openexr"
	+$(MAKE) -C $(BUILD_WORK)/openexr/OpenEXR install \
		DESTDIR="$(BUILD_BASE)"

	touch $(BUILD_WORK)/openexr/.build_complete
endif

openexr-package: openexr-stage
	# openexr.mk Package Structure
	rm -rf $(BUILD_DIST)/openexr \
		$(BUILD_DIST)/lib{openexr,ilmbase}{-dev,25}
	mkdir -p $(BUILD_DIST)/openexr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/lib{openexr,ilmbase}{-dev,25}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openexr.mk Prep openexr
	cp -a $(BUILD_STAGE)/openexr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/openexr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# openexr.mk Prep libopenexr25
	cp -a $(BUILD_STAGE)/openexr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libIlmImf{,Util}-2_5.*.dylib $(BUILD_DIST)/libopenexr25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openexr.mk Prep libopenexr-dev
	cp -a $(BUILD_STAGE)/openexr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libIlmImf{,Util}{-2_5,}.dylib,pkgconfig,cmake} $(BUILD_DIST)/libopenexr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/openexr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libopenexr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# openexr.mk Prep libilmbase25
	cp -a $(BUILD_STAGE)/ilmbase/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib{Half,Iex,IexMath,IlmThread,Imath}-2_5.*.dylib $(BUILD_DIST)/libilmbase25/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# openexr.mk Prep libilmbase-dev
	cp -a $(BUILD_STAGE)/ilmbase/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{lib{Half,Iex,IexMath,IlmThread,Imath}{-2_5,}.dylib,pkgconfig,cmake} $(BUILD_DIST)/libilmbase-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/ilmbase/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libilmbase-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# openexr.mk Sign
	$(call SIGN,openexr,general.xml)
	$(call SIGN,libopenexr25,general.xml)
	$(call SIGN,libilmbase25,general.xml)

	# openexr.mk Make .debs
	$(call PACK,openexr,DEB_OPENEXR_V)
	$(call PACK,libopenexr25,DEB_OPENEXR_V)
	$(call PACK,libopenexr-dev,DEB_OPENEXR_V)
	$(call PACK,libilmbase25,DEB_OPENEXR_V)
	$(call PACK,libilmbase-dev,DEB_OPENEXR_V)

	# openexr.mk Build cleanup
	rm -rf $(BUILD_DIST)/openexr \
		$(BUILD_DIST)/lib{openexr,ilmbase}{-dev,25}

.PHONY: openexr openexr-package
