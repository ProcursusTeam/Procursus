ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += cpio
CPIO_VERSION := 2.13
DEB_CPIO_V   ?= $(CPIO_VERSION)

cpio-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/cpio/cpio-$(CPIO_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,cpio-$(CPIO_VERSION).tar.gz)
	$(call EXTRACT_TAR,cpio-$(CPIO_VERSION).tar.gz,cpio-$(CPIO_VERSION),cpio)
	$(call DO_PATCH,cpio,cpio,-p1)

ifneq ($(wildcard $(BUILD_WORK)/cpio/.build_complete),)
cpio:
	@echo "Using previously built cpio."
else
cpio: cpio-setup gettext
	cd $(BUILD_WORK)/cpio && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/cpio
	+$(MAKE) -C $(BUILD_WORK)/cpio install \
		DESTDIR=$(BUILD_STAGE)/cpio
	touch $(BUILD_WORK)/cpio/.build_complete
endif

cpio-package: cpio-stage
	# cpio.mk Package Structure
	rm -rf $(BUILD_DIST)/cpio
	mkdir -p $(BUILD_DIST)/cpio

	# cpio.mk Prep cpio
	cp -a $(BUILD_STAGE)/cpio $(BUILD_DIST)

	# cpio.mk Sign
	$(call SIGN,cpio,general.xml)

	# cpio.mk Make .debs
	$(call PACK,cpio,DEB_CPIO_V)

	# cpio.mk Build cleanup
	rm -rf $(BUILD_DIST)/cpio

.PHONY: cpio cpio-package
