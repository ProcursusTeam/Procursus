ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libtakeover
LIBTAKEOVER_VERSION := 31
LIBTAKEOVER_COMMIT  := ceecc6927f4b052965e1cad34b9b77153ba70c0b
DEB_LIBTAKEOVER_V   ?= $(LIBTAKEOVER_VERSION)-1

libtakeover-setup: setup
	$(call GITHUB_ARCHIVE,tihmstar,libtakeover,$(LIBTAKEOVER_VERSION),$(LIBTAKEOVER_VERSION))
	$(call EXTRACT_TAR,libtakeover-$(LIBTAKEOVER_VERSION).tar.gz,libtakeover-$(LIBTAKEOVER_VERSION),libtakeover)
	sed -i 's/git rev\-list \-\-count HEAD/printf ${LIBTAKEOVER_VERSION}/g' $(BUILD_WORK)/libtakeover/configure.ac
	sed -i 's/git rev\-parse HEAD/printf ${LIBTAKEOVER_VERSION}/g' $(BUILD_WORK)/libtakeover/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libtakeover/.build_complete),)
libtakeover:
	@echo "Using previously built libtakeover."
else
libtakeover: libtakeover-setup libgeneral
	cd $(BUILD_WORK)/libtakeover && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libtakeover
	+$(MAKE) -C $(BUILD_WORK)/libtakeover install \
		DESTDIR="$(BUILD_STAGE)/libtakeover"
	$(call AFTER_BUILD,copy)
endif

libtakeover-package: libtakeover-stage
	# libtakeover.mk Package Structure
	rm -rf $(BUILD_DIST)/*libtakeover*/
	mkdir -p $(BUILD_DIST)/{libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin,libtakeover0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib,libtakeover-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}}

	# libtakeover.mk Prep libtakeover
	cp -a $(BUILD_STAGE)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/orphan_commander $(BUILD_DIST)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/inject_criticald $(BUILD_DIST)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libtakeover.mk Prep libtakeover0
	cp -a $(BUILD_STAGE)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtakeover.0.dylib $(BUILD_DIST)/libtakeover0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libtakeover.mk Prep libtakeover-dev
	cp -a $(BUILD_STAGE)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libtakeover.dylib,pkgconfig} $(BUILD_DIST)/libtakeover-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libtakeover/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libtakeover $(BUILD_DIST)/libtakeover-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# libtakeover.mk Sign
	$(call SIGN,libtakeover,libtakeover.xml)
	$(call SIGN,libtakeover0,libtakeover.xml)

	# libtakeover.mk Make .debs
	$(call PACK,libtakeover0,DEB_LIBTAKEOVER_V)
	$(call PACK,libtakeover,DEB_LIBTAKEOVER_V)
	$(call PACK,libtakeover-dev,DEB_LIBTAKEOVER_V)

	# libtakeover.mk Build cleanup
	rm -rf $(BUILD_DIST)/*libtakeover*/

.PHONY: libtakeover libtakeover-package
