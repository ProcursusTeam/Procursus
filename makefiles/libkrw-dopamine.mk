ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ifeq ($(shell [ "$(MEMO_CFVER)" -eq 1800 ] && echo 1),1)

STRAPPROJECTS     			+= libkrw-dopamine
LIBKRW_DOPAMINE_VERSION 	:= 1.0.0
LIBKRW_DOPAMINE_MINOR	 	:= 1
DEB_LIBKRW_DOPAMINE_V   	?= $(LIBKRW_DOPAMINE_VERSION)
LIBKRW_DOPAMINE_LIBS   		:= -ljailbreak -framework Foundation

libkrw-dopamine-setup: setup
	$(call GITHUB_ARCHIVE,Cryptiiiic,libjbdrw,$(LIBKRW_DOPAMINE_VERSION),v$(LIBKRW_DOPAMINE_VERSION))
	$(call EXTRACT_TAR,libjbdrw-$(LIBKRW_DOPAMINE_VERSION).tar.gz,libjbdrw-$(LIBKRW_DOPAMINE_VERSION),libkrw0-dopamine)
	mkdir -p $(BUILD_STAGE)/libkrw0-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

ifneq ($(wildcard $(BUILD_WORK)/libkrw0-dopamine/.build_complete),)
libkrw-dopamine:
	@echo "Using previously built libkrw-dopamine."
else
libkrw-dopamine: libkrw-dopamine-setup

	# libkrw0-dopamine.dylib
	$(CC) $(CFLAGS) -fobjc-arc -dynamiclib \
		-I$(BUILD_WORK)/libkrw0-dopamine/include \
		-DVERSION=$(LIBKRW_DOPAMINE_MINOR) \
		-install_name "$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw0-dopamine.dylib" \
		-o $(BUILD_STAGE)/libkrw0-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw0-dopamine.dylib \
		$(BUILD_WORK)/libkrw0-dopamine/src/jbdrw.m \
		$(LDFLAGS) \
		-L$(BUILD_WORK)/libkrw0-dopamine/lib \
		$(LIBKRW_DOPAMINE_LIBS)
	$(call AFTER_BUILD,copy)
endif

libkrw-dopamine-package: libkrw-dopamine-stage
	# libkrw-dopamine.mk Package Structure
	rm -rf $(BUILD_DIST)/libkrw0-dopamine
	mkdir -p $(BUILD_DIST)/libkrw0-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw

	# libkrw-dopamine.mk Prep libkrw0-dopamine
	cp -a $(BUILD_STAGE)/libkrw0-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw/libkrw0-dopamine.dylib $(BUILD_DIST)/libkrw0-dopamine/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrw


	# libkrw-dopamine.mk Sign
	$(call SIGN,libkrw0-dopamine,general.xml)

	# libkrw-dopamine.mk Make .debs
	$(call PACK,libkrw0-dopamine,DEB_LIBKRW_DOPAMINE_V)

	# libkrw-dopamine.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkrw-dopamine

.PHONY: libkrw-dopamine libkrw-dopamine-package

endif
endif
