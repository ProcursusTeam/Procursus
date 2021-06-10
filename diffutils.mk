ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
SUBPROJECTS       += diffutils
else
STRAPPROJECTS     += diffutils
endif
DIFFUTILS_VERSION := 3.7
DEB_DIFFUTILS_V   ?= $(DIFFUTILS_VERSION)-2

diffutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/diffutils/diffutils-$(DIFFUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,diffutils-$(DIFFUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,diffutils-$(DIFFUTILS_VERSION).tar.xz,diffutils-$(DIFFUTILS_VERSION),diffutils)

ifneq ($(wildcard $(BUILD_WORK)/diffutils/.build_complete),)
diffutils:
	@echo "Using previously built diffutils."
else
diffutils: diffutils-setup gettext
	cd $(BUILD_WORK)/diffutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/diffutils
	+$(MAKE) -C $(BUILD_WORK)/diffutils install \
		DESTDIR=$(BUILD_STAGE)/diffutils
	touch $(BUILD_WORK)/diffutils/.build_complete
endif

diffutils-package: diffutils-stage
	# diffutils.mk Package Structure
	rm -rf $(BUILD_DIST)/diffutils

	# diffutils.mk Prep diffutils
	cp -a $(BUILD_STAGE)/diffutils $(BUILD_DIST)

	# diffutils.mk Sign
	$(call SIGN,diffutils,general.xml)

	# diffutils.mk Make .debs
	$(call PACK,diffutils,DEB_DIFFUTILS_V)

	# diffutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/diffutils

.PHONY: diffutils diffutils-package
