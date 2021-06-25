ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += debootstrap
DEBOOTSTRAP_VERSION := 1.0.123
DEB_DEBOOTSTRAP_V   ?= $(DEBOOTSTRAP_VERSION)

debootstrap-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/d/debootstrap/debootstrap_$(DEBOOTSTRAP_VERSION).tar.gz
	$(TAR) xf $(BUILD_SOURCE)/debootstrap_$(DEBOOTSTRAP_VERSION).tar.gz -C $(BUILD_WORK)
	$(call DO_PATCH,debootstrap,debootstrap,-p1)
	$(SED) -i 's/@VERSION@/$(DEB_DEBOOTSTRAP_V)/g' $(BUILD_WORK)/debootstrap/debootstrap

ifneq ($(wildcard $(BUILD_WORK)/debootstrap/.build_complete),)
debootstrap:
	@echo "Using previously built debootstrap."
else
debootstrap: debootstrap-setup
	+$(MAKE) -C $(BUILD_WORK)/debootstrap install \
		DESTDIR=$(BUILD_STAGE)/debootstrap
	$(INSTALL) -Dm644 $(BUILD_WORK)/debootstrap/debootstrap.8 \
		$(BUILD_STAGE)/debootstrap/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/debootstrap.8
	touch $(BUILD_WORK)/debootstrap/.build_complete
endif

debootstrap-package: debootstrap-stage
	# debootstrap.mk Package Structure
	rm -rf $(BUILD_DIST)/debootstrap

	# debootstrap.mk Prep debootstrap
	cp -a $(BUILD_STAGE)/debootstrap $(BUILD_DIST)

	# debootstrap.mk Make .debs
	$(call PACK,debootstrap,DEB_DEBOOTSTRAP_V)

	# debootstrap.mk Build cleanup
	rm -rf $(BUILD_DIST)/debootstrap

.PHONY: debootstrap debootstrap-package
