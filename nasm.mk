ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nasm
NASM_VERSION := 2.15.05
DEB_NASM_V   ?= $(NASM_VERSION)

nasm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.nasm.us/pub/nasm/releasebuilds/$(NASM_VERSION)/nasm-$(NASM_VERSION).tar.xz
	$(call EXTRACT_TAR,nasm-$(NASM_VERSION).tar.xz,nasm-$(NASM_VERSION),nasm)

ifneq ($(wildcard $(BUILD_WORK)/nasm/.build_complete),)
nasm:
	@echo "Using previously built nasm."
else
nasm: nasm-setup
	cd $(BUILD_WORK)/nasm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/nasm rdf
	+$(MAKE) -C $(BUILD_WORK)/nasm install install_rdf \
		DESTDIR=$(BUILD_STAGE)/nasm
	touch $(BUILD_WORK)/nasm/.build_complete
endif

nasm-package: nasm-stage
	# nasm.mk Package Structure
	rm -rf $(BUILD_DIST)/nasm

	# nasm.mk Prep nasm
	cp -a $(BUILD_STAGE)/nasm $(BUILD_DIST)

	# nasm.mk Sign
	$(call SIGN,nasm,general.xml)

	# nasm.mk Make .debs
	$(call PACK,nasm,DEB_NASM_V)

	# nasm.mk Build cleanup
	rm -rf $(BUILD_DIST)/nasm

.PHONY: nasm nasm-package
