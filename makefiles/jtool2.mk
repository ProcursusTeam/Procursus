ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += jtool2
JTOOL2_VERSION := 2020.12.21
DEB_JTOOL2_V   ?= $(JTOOL2_VERSION)

jtool2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://newosxbook.com/tools/jtool2.tgz
	rm -rf $(BUILD_WORK)/jtool2 && mkdir -p $(BUILD_WORK)/jtool2 && pushd $(BUILD_WORK)/jtool2 && $(TAR) -C . -xf $(BUILD_SOURCE)/jtool2.tgz && popd

ifneq ($(wildcard $(BUILD_WORK)/jtool2/.build_complete),)
jtool2:
	@echo "Using previously built jtool2."
else
jtool2: jtool2-setup
	-LIPO_OUTPUT_TARGET=""; \
	[[ $$(echo $(MEMO_TARGET) | cut -d- -f2) = "amd64" ]] && LIPO_OUTPUT_TARGET="x86_64" || LIPO_OUTPUT_TARGET="arm64"; \
	mkdir -p $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin; \
	$(LIPO) $(BUILD_WORK)/jtool2/jtool2 -thin $$LIPO_OUTPUT_TARGET -output $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/jtool2; \
	$(LIPO) $(BUILD_WORK)/jtool2/disarm -thin $$LIPO_OUTPUT_TARGET -output $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/disarm; \
	[ $(MEMO_TARGET) = "darwin-arm64" ] && \
		vtool -arch arm64 -remove-build-version ios -output $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/jtool2 $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/jtool2 && \
		vtool -arch arm64 -remove-build-version ios -output $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/disarm $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/disarm
	touch $(BUILD_WORK)/jtool2/.build_complete
endif

jtool2-package: jtool2-stage
	# jtool2.mk Package Structure
	mkdir -p $(BUILD_DIST)/jtool2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
	# jtool2.mk Prep jtool2
	cp -a $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jtool2 $(BUILD_DIST)/jtool2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/jtool2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/disarm $(BUILD_DIST)/jtool2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# jtool2.mk Sign
	$(call SIGN,jtool2,general.xml)
	
	# jtool2.mk Make .debs
	$(call PACK,jtool2,DEB_JTOOL2_V)
	
	# jtool2.mk Build cleanup
	rm -rf $(BUILD_DIST)/jtool2

.PHONY: jtool2 jtool2-package
