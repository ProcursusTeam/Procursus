ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lzfse
LZFSE_VERSION := 1.0
DEB_LZFSE_V   ?= $(LZFSE_VERSION)-1

lzfse-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/lzfse/lzfse/archive/lzfse-$(LZFSE_VERSION).tar.gz
	$(call EXTRACT_TAR,lzfse-$(LZFSE_VERSION).tar.gz,lzfse-lzfse-$(LZFSE_VERSION),lzfse)

ifneq ($(wildcard $(BUILD_WORK)/lzfse/.build_complete),)
lzfse:
	@echo "Using previously built lzfse."
else
lzfse: lzfse-setup
	cd $(BUILD_WORK)/lzfse && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_INSTALL_NAME_DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		-DCMAKE_INSTALL_RPATH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		.
	+$(MAKE) -C $(BUILD_WORK)/lzfse
	+$(MAKE) -C $(BUILD_WORK)/lzfse install \
		DESTDIR="$(BUILD_STAGE)/lzfse"
	+$(MAKE) -C $(BUILD_WORK)/lzfse install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/lzfse/.build_complete
endif

lzfse-package: lzfse-stage
	# lzfse.mk Package Structure
	rm -rf $(BUILD_DIST)/{liblzfse{,-dev},lzfse}
	mkdir -p $(BUILD_DIST)/{liblzfse{,-dev},lzfse}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# lzfse.mk Prep lzfse
	cp -a $(BUILD_STAGE)/lzfse/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/lzfse/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# lzfse.mk Prep liblzfse
	cp -a $(BUILD_STAGE)/lzfse/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib $(BUILD_DIST)/liblzfse/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# lzfse.mk Prep liblzfse-dev
	cp -a $(BUILD_STAGE)/lzfse/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liblzfse-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# lzfse.mk Sign
	$(call SIGN,lzfse,general.xml)
	$(call SIGN,liblzfse,general.xml)

	# lzfse.mk Make .debs
	$(call PACK,lzfse,DEB_LZFSE_V)
	$(call PACK,liblzfse,DEB_LZFSE_V)
	$(call PACK,liblzfse-dev,DEB_LZFSE_V)

	# lzfse.mk Build cleanup
	rm -rf $(BUILD_DIST)/{liblzfse{,-dev},lzfse}

.PHONY: lzfse lzfse-package
