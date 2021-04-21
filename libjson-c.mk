ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libjson-c
JSON-C_VERSION   := 0.15
DEB_JSON-C_V     ?= $(JSON-C_VERSION)

libjson-c-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://s3.amazonaws.com/json-c_releases/releases/json-c-$(JSON-C_VERSION).tar.gz
	$(call EXTRACT_TAR,json-c-$(JSON-C_VERSION).tar.gz,json-c-$(JSON-C_VERSION),libjson-c)

ifneq ($(wildcard $(BUILD_WORK)/libjson-c/.build_complete),)
libjson-c:
	@echo "Using previously built libjson-c."
else
libjson-c: libjson-c-setup
	cd $(BUILD_WORK)/libjson-c && cmake \
		$(DEFAULT_CMAKE_FLAGS)
		.
	+$(MAKE) -C $(BUILD_WORK)/libjson-c install \
		DESTDIR=$(BUILD_STAGE)/libjson-c
	+$(MAKE) -C $(BUILD_WORK)/libjson-c install \
		DESTDIR=$(BUILD_BASE)
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjson-c.5.dylib $(BUILD_STAGE)/libjson-c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjson-c.5.dylib
	$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjson-c.5.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjson-c.5.dylib
	touch $(BUILD_WORK)/libjson-c/.build_complete
endif

libjson-c-package: libjson-c-stage
	# json-c.mk Package Structure
	rm -rf $(BUILD_DIST)/libjson-c{-dev,5}
	mkdir -p \
		$(BUILD_DIST)/libjson-c{-dev,5}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libjson-c.mk Prep libjson-c5
	cp -a $(BUILD_STAGE)/libjson-c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjson-c.5*.dylib  $(BUILD_DIST)/libjson-c5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libjson-c.mk Prep libjson-c-dev
	cp -a $(BUILD_STAGE)/libjson-c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{cmake,pkgconfig}  $(BUILD_DIST)/libjson-c-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libjson-c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjson-c.{dylib,a}  $(BUILD_DIST)/libjson-c-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libjson-c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libjson-c-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# libjson-c.mk Sign
	$(call SIGN,libjson-c5,general.xml)

	# libjson-c.mk Make .debs
	$(call PACK,libjson-c5,DEB_JSON-C_V)
	$(call PACK,libjson-c-dev,DEB_JSON-C_V)

	# libjson-c.mk Build cleanup
	rm -rf $(BUILD_DIST)/libjson-c{-dev,5}

.PHONY: libjson-c libjson-c-package
