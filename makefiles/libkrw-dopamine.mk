ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1800 ] && echo 1),1)

SUBPROJECTS             += libkrw-dopamine
DOPAMINE_VERSION        := 2.0.11
CHOMA_COMMIT            := 54fedaf26175d5db27246d66b55d540ff6bcb83d
LIBKRW_DOPAMINE_VERSION := 2.0.1
DEB_LIBKRW_DOPAMINE_V   ?= $(LIBKRW_DOPAMINE_VERSION)-1
LIBKRW_DOPAMINE_LIBS    := -ljailbreak -framework Foundation

libkrw-dopamine-setup: setup
	$(call GITHUB_ARCHIVE,opa334,Dopamine,$(DOPAMINE_VERSION),$(DOPAMINE_VERSION),Dopamine)
	$(call EXTRACT_TAR,Dopamine-$(DOPAMINE_VERSION).tar.gz,Dopamine-$(DOPAMINE_VERSION),libkrw-dopamine/Dopamine)
	$(call GITHUB_ARCHIVE,opa334,ChOma,$(CHOMA_COMMIT),$(CHOMA_COMMIT),ChOma)
	$(call EXTRACT_TAR,ChOma-$(CHOMA_COMMIT).tar.gz,ChOma-$(CHOMA_COMMIT),libkrw-dopamine/ChOma)
	mkdir -p $(BUILD_WORK)/libkrw-dopamine/include/{libjailbreak,choma}
	cp -a $(BUILD_WORK)/libkrw-dopamine/Dopamine/Packages/libkrw-provider/src $(BUILD_WORK)/libkrw-dopamine/
	cp -a $(BUILD_WORK)/libkrw-dopamine/Dopamine/BaseBin/libjailbreak/src/*.h $(BUILD_WORK)/libkrw-dopamine/include/libjailbreak
	cp -a $(BUILD_WORK)/libkrw-dopamine/Dopamine/BaseBin/_external/include/libkrw $(BUILD_WORK)/libkrw-dopamine/include/
	cp -a $(BUILD_WORK)/libkrw-dopamine/ChOma/src/*.h $(BUILD_WORK)/libkrw-dopamine/include/choma
	sed -i 's/krw_plugin_initializer_t krw_initializer/int krw_initializer/' $(BUILD_WORK)/libkrw-dopamine/src/main.c
	rm -rf $(BUILD_WORK)/libkrw-dopamine/{Dopamine,ChOma}
	mkdir -p $(BUILD_STAGE)/libkrw-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

ifneq ($(wildcard $(BUILD_WORK)/libkrw-dopamine/.build_complete),)
libkrw-dopamine:
	@echo "Using previously built libkrw-dopamine."
else
libkrw-dopamine: libkrw-dopamine-setup

	# libkrw-dopamine.dylib
	$(CC) $(CFLAGS) -fobjc-arc -dynamiclib \
		-I$(BUILD_WORK)/libkrw-dopamine/include \
		-install_name "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-dopamine.dylib" \
		-o $(BUILD_STAGE)/libkrw-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-dopamine.dylib \
		$(BUILD_WORK)/libkrw-dopamine/src/main.c \
		$(LDFLAGS) \
		-L$(BUILD_MISC)/libjailbreak-dopamine2 \
		$(LIBKRW_DOPAMINE_LIBS)
	$(call AFTER_BUILD)
endif

libkrw-dopamine-package: libkrw-dopamine-stage
	# libkrw-dopamine.mk Package Structure
	rm -rf $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)-dopamine
	mkdir -p $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

	# libkrw-dopamine.mk Prep libkrw-dopamine
	cp -a $(BUILD_STAGE)/libkrw-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw-dopamine.dylib $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

	# libkrw-dopamine.mk Sign
	$(call SIGN,libkrw$(LIBKRW_SOVERSION)-dopamine,general.xml)

	# libkrw-dopamine.mk Make .debs
	$(call PACK,libkrw$(LIBKRW_SOVERSION)-dopamine,DEB_LIBKRW_DOPAMINE_V)

	# libkrw-dopamine.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkrw$(LIBKRW_SOVERSION)-dopamine

.PHONY: libkrw-dopamine libkrw-dopamine-package

endif
endif
