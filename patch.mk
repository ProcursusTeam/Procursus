ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += patch
PATCH_VERSION := 2.7.6
DEB_PATCH_V   ?= $(PATCH_VERSION)

patch-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/patch/patch-$(PATCH_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,patch-$(PATCH_VERSION).tar.xz)
	$(call EXTRACT_TAR,patch-$(PATCH_VERSION).tar.xz,patch-$(PATCH_VERSION),patch)

ifneq ($(wildcard $(BUILD_WORK)/patch/.build_complete),)
patch:
	@echo "Using previously built patch."
else
patch: patch-setup
	cd $(BUILD_WORK)/patch && ./configure -C \
		--host=$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/patch
	+$(MAKE) -C $(BUILD_WORK)/patch install \
		prefix=$(BUILD_STAGE)/patch/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/patch/.build_complete
endif

patch-package: patch-stage
	# patch.mk Package Structure
	rm -rf $(BUILD_DIST)/patch
	mkdir -p $(BUILD_DIST)/patch
	
	# patch.mk Prep patch
	cp -a $(BUILD_STAGE)/patch $(BUILD_DIST)
	
	# patch.mk Sign
	$(call SIGN,patch,general.xml)
	
	# patch.mk Make .debs
	$(call PACK,patch,DEB_PATCH_V)
	
	# patch.mk Build cleanup
	rm -rf $(BUILD_DIST)/patch

.PHONY: patch patch-package
