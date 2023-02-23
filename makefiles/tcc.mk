ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tcc
TCC_COMMIT  := 605538f46d277fe0931f72f032a24a675417ee2a
TCC_VERSION := 0.9.27+git20230222.$(shell echo $(TCC_COMMIT) | cut -c -7)
DEB_TCC_V   ?= $(TCC_VERSION)

### NOTE: tcc package from Procursus must be installed for successful compilation
###       of this project. All available targets are cross compiled.

### WARN: Remove 'fixios.patch' when __clear_cache is natively implemented for
###       arm64-osx in tcc.

tcc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://repo.or.cz/tinycc.git/snapshot/$(TCC_COMMIT).tar.gz
	$(call EXTRACT_TAR,$(TCC_COMMIT).tar.gz,tinycc-$(shell echo $(TCC_COMMIT) | cut -c -7),tcc)
	$(call DO_PATCH,tcc,tcc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/tcc/.build_complete),)
tcc:
	@echo "Using previously built tcc."
else
tcc: tcc-setup
	cd $(BUILD_WORK)/tcc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--cpu=$(MEMO_ARCH) \
		--cc=$(CC) \
		--ar=$(AR) \
		--source-path=$(BUILD_WORK)/tcc \
		--sysincludepaths=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcc/include:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include:/usr/local/include:/usr/include:$(ON_DEVICE_SDK_PATH)/usr/include:{B}/include \
		--libpaths=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcc:$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib:/usr/local/lib:/usr/lib:$(ON_DEVICE_SDK_PATH)/usr/lib:{B}/lib \
		--enable-cross
	+$(MAKE) -C $(BUILD_WORK)/tcc \
		MACOSX_DEPLOYMENT_TARGET=$(MACOSX_DEPLOYMENT_TARGET)
	+$(MAKE) -C $(BUILD_WORK)/tcc install \
		DESTDIR=$(BUILD_STAGE)/tcc
	$(call AFTER_BUILD)
endif

tcc-package: tcc-stage
	# tcc.mk Package Structure
	rm -rf $(BUILD_DIST)/tcc $(BUILD_DIST)/libtcc-dev
	mkdir -p $(BUILD_DIST)/libtcc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include}

	# tcc.mk Prep tcc
	cp -a $(BUILD_STAGE)/tcc $(BUILD_DIST)
	rm -rf $(BUILD_DIST)/tcc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtcc.a \
		$(BUILD_DIST)/tcc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# tcc.mk Prep libtcc-dev
	cp -a $(BUILD_STAGE)/tcc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libtcc.h $(BUILD_DIST)/libtcc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/tcc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtcc.a $(BUILD_DIST)/libtcc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tcc.mk Sign
	$(call SIGN,tcc,general.xml)

	# tcc.mk Make .debs
	$(call PACK,tcc,DEB_TCC_V)
	$(call PACK,libtcc-dev,DEB_TCC_V)

	# tcc.mk Build cleanup
	rm -rf $(BUILD_DIST)/tcc $(BUILD_DIST)/libtcc-dev

.PHONY: tcc tcc-package
