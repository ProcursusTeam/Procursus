ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += patchutils
PATCHUTILS_VERSION := 0.4.2
DEB_PATCHUTILS_V   ?= $(PATCHUTILS_VERSION)-1

patchutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://cyberelk.net/tim/data/patchutils/stable/patchutils-$(PATCHUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,patchutils-$(PATCHUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,patchutils-$(PATCHUTILS_VERSION).tar.xz,patchutils-$(PATCHUTILS_VERSION),patchutils)

ifneq ($(wildcard $(BUILD_WORK)/patchutils/.build_complete),)
patchutils:
	@echo "Using previously built patchutils."
else
patchutils: patchutils-setup pcre2
	cd $(BUILD_WORK)/patchutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-pcre2
	+$(MAKE) -C $(BUILD_WORK)/patchutils
	+$(MAKE) -C $(BUILD_WORK)/patchutils install \
		DESTDIR=$(BUILD_STAGE)/patchutils
	$(SED) -i -e "s|$$(cat $(BUILD_STAGE)/patchutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/recountdiff | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl|" \
		-e "s|$$(cat $(BUILD_STAGE)/patchutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gitdiff | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/patchutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	touch $(BUILD_WORK)/patchutils/.build_complete
endif

patchutils-package: patchutils-stage
	# patchutils.mk Package Structure
	rm -rf $(BUILD_DIST)/patchutils

	# patchutils.mk Prep patchutils
	cp -a $(BUILD_STAGE)/patchutils $(BUILD_DIST)

	# patchutils.mk Sign
	$(call SIGN,patchutils,general.xml)

	# patchutils.mk Make .debs
	$(call PACK,patchutils,DEB_PATCHUTILS_V)

	# patchutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/patchutils

.PHONY: patchutils patchutils-package
