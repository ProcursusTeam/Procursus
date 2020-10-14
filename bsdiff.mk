ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS 	 += bsdiff
BSDIFF_VERSION := 4.3
DEB_BSDIFF_V   ?= $(BSDIFF_VERSION)

bsdiff-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/bsdiff-$(BSDIFF_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/bsdiff-$(BSDIFF_VERSION).tar.gz \
			https://github.com/mendsley/bsdiff/archive/v$(BSDIFF_VERSION).tar.gz
	$(call EXTRACT_TAR,bsdiff-$(BSDIFF_VERSION).tar.gz,bsdiff-$(BSDIFF_VERSION),bsdiff)
	$(call DO_PATCH,bsdiff,bsdiff)

ifneq ($(wildcard $(BUILD_WORK)/bsdiff/.build_complete),)
bsdiff:
	@echo "Using previously built bsdiff."
else
bsdiff: bsdiff-setup
	+$(MAKE) -C $(BUILD_WORK)/bsdiff

	mkdir -p $(BUILD_STAGE)/bsdiff/usr/{bin,share/man/man1}

	+$(MAKE) -C $(BUILD_WORK)/bsdiff install \
		PREFIX="$(BUILD_STAGE)/bsdiff/usr" \
		INSTALL=install
	touch $(BUILD_WORK)/bsdiff/.build_complete
endif

bsdiff-package: bsdiff-stage
	# bsdiff.mk Package Structure
	rm -rf $(BUILD_DIST)/bsdiff
	mkdir -p $(BUILD_DIST)/bsdiff/usr

	# bsdiff.mk Prep bsdiff
	cp -a $(BUILD_STAGE)/bsdiff/usr/{bin,share} $(BUILD_DIST)/bsdiff/usr

	# bsdiff.mk Sign
	$(call SIGN,bsdiff,general.xml)

	# bsdiff.mk Make .debs
	$(call PACK,bsdiff,DEB_BSDIFF_V)

	# bsdiff.mk Build cleanup
	rm -rf $(BUILD_DIST)/bsdiff

.PHONY: bsdiff bsdiff-package
