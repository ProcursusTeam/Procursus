ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -ge 1800 ] && echo 1),1)

SUBPROJECTS             += libkrw-dopamine
DOPAMINE_VERSION        := 2.1.7
CHOMA_COMMIT            := 96000d80c62f407ef7e103dc3bcb29133a3b990d
LIBKRW_DOPAMINE_VERSION := 2.0.3
DEB_LIBKRW_DOPAMINE_V   ?= $(LIBKRW_DOPAMINE_VERSION)
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
	cp -a $(BUILD_WORK)/libkrw-dopamine/Dopamine/BaseBin/_external/include/xpc_private.h $(BUILD_WORK)/libkrw-dopamine/include/
	cp -a $(BUILD_WORK)/libkrw-dopamine/ChOma/src/*.h $(BUILD_WORK)/libkrw-dopamine/include/choma
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
