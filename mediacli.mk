ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += mediacli
MEDIACLI_VERSION := 1.2
DEB_MEDIACLI_V   ?= $(MEDIACLI_VERSION)

mediacli-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/absidue/mediacli/releases/download/v$(MEDIACLI_VERSION)/mediacli-$(MEDIACLI_VERSION).tar.xz
	$(call EXTRACT_TAR,mediacli-$(MEDIACLI_VERSION).tar.xz,mediacli-$(MEDIACLI_VERSION),mediacli)

ifneq ($(wildcard $(BUILD_WORK)/mediacli/.build_complete),)
mediacli:
	@echo "Using previously built MediaCLI."
else
mediacli: mediacli-setup
	+$(MAKE) -C $(BUILD_WORK)/mediacli
	+$(MAKE) -C $(BUILD_WORK)/mediacli install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/mediacli
	touch $(BUILD_WORK)/mediacli/.build_complete
endif

mediacli-package: mediacli-stage
	# mediacli.mk Package Structure
	rm -rf $(BUILD_DIST)/mediacli

	# mediacli.mk Prep mediacli
	cp -a $(BUILD_STAGE)/mediacli $(BUILD_DIST)

	# mediacli.mk Sign
	$(call SIGN,mediacli,general.xml)

	# mediacli.mk Make .deb
	$(call PACK,mediacli,DEB_MEDIACLI_V)

	# mediacli.mk Build cleanup
	rm -rf $(BUILD_DIST)/mediacli

.PHONY: mediacli mediacli-package
