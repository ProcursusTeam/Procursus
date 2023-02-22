ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += dpkg-repack
DPKG_REPACK_VERSION := 1.52
DEB_DPKG_REPACK_V   ?= $(DPKG_REPACK_VERSION)

dpkg-repack-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://deb.debian.org/debian/pool/main/d/dpkg-repack/dpkg-repack_$(DPKG_REPACK_VERSION).tar.xz)
	$(call EXTRACT_TAR,dpkg-repack_$(DPKG_REPACK_VERSION).tar.xz,dpkg-repack-$(DPKG_REPACK_VERSION),dpkg-repack)

ifneq ($(wildcard $(BUILD_WORK)/dpkg-repack/.build_complete),)
dpkg-repack:
	@echo "Using previously built dpkg-repack."
else
dpkg-repack: dpkg-repack-setup
	cd $(BUILD_WORK)/dpkg-repack && pod2man \
		--section 1 \
		--center='dpkg suite' \
		--release='$(DEB_DPKG_REPACK_V)' \
		dpkg-repack.pod dpkg-repack.1
	sed -e "s|x.y|$(DEB_DPKG_REPACK_V)|" \
		-e "1s|.*|#!$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl|" \
		-e "s/-pd/-pP/" \
		< $(BUILD_WORK)/dpkg-repack/dpkg-repack.pl > $(BUILD_WORK)/dpkg-repack/dpkg-repack
	$(INSTALL) -Dm0755 $(BUILD_WORK)/dpkg-repack/dpkg-repack $(BUILD_STAGE)/dpkg-repack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dpkg-repack
	$(INSTALL) -Dm0644 $(BUILD_WORK)/dpkg-repack/dpkg-repack.1 $(BUILD_STAGE)/dpkg-repack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/dpkg-repack.1
	$(call AFTER_BUILD)
endif

dpkg-repack-package: dpkg-repack-stage
	# dpkg-repack.mk Package Structure
	rm -rf $(BUILD_DIST)/dpkg-repack
	mkdir -p $(BUILD_DIST)/dpkg-repack

	# dpkg-repack.mk Prep dpkg-repack
	cp -a $(BUILD_STAGE)/dpkg-repack $(BUILD_DIST)

	# dpkg-repack.mk Make .debs
	$(call PACK,dpkg-repack,DEB_DPKG_REPACK_V)

	# dpkg-repack.mk Build cleanup
	rm -rf $(BUILD_DIST)/dpkg-repack

.PHONY: dpkg-repack dpkg-repack-package
