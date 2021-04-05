ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pbzx
PBZX_VERSION   := 1.0.2
DEB_PBZX_V     ?= $(PBZX_VERSION)

pbzx-setup: setup
	$(call GITHUB_ARCHIVE,NiklasRosenstein,pbzx,$(PBZX_VERSION),v$(PBZX_VERSION))
	$(call EXTRACT_TAR,pbzx-$(PBZX_VERSION).tar.gz,pbzx-$(PBZX_VERSION),pbzx)

ifneq ($(wildcard $(BUILD_WORK)/pbzx/.build_complete),)
pbzx:
	@echo "Using previously built pbzx."
else
pbzx: pbzx-setup xar xz
	$(CC) $(CFLAGS) $(LDFLAGS) -llzma -lxar $(BUILD_WORK)/pbzx/pbzx.c -o $(BUILD_WORK)/pbzx/pbzx
	$(STRIP) $(BUILD_WORK)/pbzx/pbzx
	$(GINSTALL) -Dm755 $(BUILD_WORK)/pbzx/pbzx $(BUILD_STAGE)/pbzx/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbzx
	touch $(BUILD_WORK)/pbzx/.build_complete
endif

pbzx-package: pbzx-stage
	# pbzx.mk Package Structure
	rm -rf $(BUILD_DIST)/pbzx

	# pbzx.mk Prep pbzx
	cp -a $(BUILD_STAGE)/pbzx $(BUILD_DIST)/pbzx

	# pbzx.mk Sign
	$(call SIGN,pbzx,general.xml)

	# pbzx.mk Make .debs
	$(call PACK,pbzx,DEB_PBZX_V)

	# pbzx.mk Build cleanup
	rm -rf $(BUILD_DIST)/pbzx

.PHONY: pbzx pbzx-package
