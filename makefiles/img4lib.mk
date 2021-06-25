ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += img4lib
IMG4LIB_COMMIT  := be2e7dd93339f42d7143ae574a329938e97020b4
IMG4LIB_VERSION := 1.0+git20201209.$(shell echo $(IMG4LIB_COMMIT) | cut -c -7)
DEB_IMG4LIB_V   ?= $(IMG4LIB_VERSION)-1

img4lib-setup: setup
	$(call GITHUB_ARCHIVE,xerub,img4lib,v$(IMG4LIB_COMMIT),$(IMG4LIB_COMMIT))
	$(call EXTRACT_TAR,img4lib-v$(IMG4LIB_COMMIT).tar.gz,img4lib-$(IMG4LIB_COMMIT),img4lib)
	$(SED) -i 's/CFLAGS =/CFLAGS ?=/' $(BUILD_WORK)/img4lib/Makefile
	$(SED) -i 's/LDFLAGS =/LDFLAGS ?=/' $(BUILD_WORK)/img4lib/Makefile
	$(SED) -i '/CFLAGS += -DUSE_LIBCOMPRESSION/d' $(BUILD_WORK)/img4lib/Makefile
	$(SED) -i '/LDLIBS = -lcompression/d' $(BUILD_WORK)/img4lib/Makefile
	$(SED) -i 's/CC =/CC ?=/' $(BUILD_WORK)/img4lib/Makefile
	$(SED) -i 's/LD =/LD ?=/' $(BUILD_WORK)/img4lib/Makefile
	$(SED) -i 's/AR =/AR ?=/' $(BUILD_WORK)/img4lib/Makefile
	mkdir -p $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include/{libvfs,libDER},lib}

ifneq ($(wildcard $(BUILD_WORK)/img4lib/.build_complete),)
img4lib:
	@echo "Using previously built img4lib."
else
img4lib: img4lib-setup openssl lzfse
	+$(MAKE) -C $(BUILD_WORK)/img4lib \
		LD=$(CC)
	cp -a $(BUILD_WORK)/img4lib/img4 $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/img4lib/libDER/*.h $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libDER
	cp -a $(BUILD_WORK)/img4lib/libvfs/*.h $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libvfs
	cp -a $(BUILD_WORK)/img4lib/libimg4.a $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/img4lib/.build_complete
endif

img4lib-package: img4lib-stage
	# img4lib.mk Package Structure
	rm -rf $(BUILD_DIST)/{img4lib,libimg4-dev}
	mkdir -p $(BUILD_DIST)/{img4lib,libimg4-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# img4lib.mk Prep img4lib
	cp -a $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# img4lib.mk Prep libimg4-dev
	cp -a $(BUILD_STAGE)/img4lib/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib} $(BUILD_DIST)/libimg4-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# img4lib.mk Sign
	$(call SIGN,img4lib,general.xml)

	# img4lib.mk Make .debs
	$(call PACK,img4lib,DEB_IMG4LIB_V)
	$(call PACK,libimg4-dev,DEB_IMG4LIB_V)

	# img4lib.mk Build cleanup
	rm -rf $(BUILD_DIST)/{img4lib,libimg4-dev}

.PHONY: img4lib img4lib-package
