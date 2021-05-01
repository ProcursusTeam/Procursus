ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += popt
POPT_VERSION := 1.18
DEB_POPT_V   ?= $(POPT_VERSION)

popt-setup: setup
	$(call GITHUB_ARCHIVE,rpm-software-management,popt,$(POPT_VERSION),popt-$(POPT_VERSION)-release)
	$(call EXTRACT_TAR,popt-$(POPT_VERSION).tar.gz,popt-popt-$(POPT_VERSION)-release,popt)

ifneq ($(wildcard $(BUILD_WORK)/popt/.build_complete),)
popt:
	@echo "Using previously built popt."
else
popt: popt-setup
	cd $(BUILD_WORK)/popt && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/popt
	+$(MAKE) -C $(BUILD_WORK)/popt install \
		DESTDIR=$(BUILD_STAGE)/popt
	+$(MAKE) -C $(BUILD_WORK)/popt install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/popt/.build_complete
endif

popt-package: popt-stage
	# popt.mk Package Structure
	rm -rf $(BUILD_DIST)/libpopt{0,-dev}
	mkdir -p $(BUILD_DIST)/libpopt{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share}

	# popt.mk Prep libpopt0
	cp -a $(BUILD_STAGE)/popt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpopt.*.dylib $(BUILD_DIST)/libpopt0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/popt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libpopt0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# popt.mk Prep libpopt-dev
	cp -a $(BUILD_STAGE)/popt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpopt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/popt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libpopt.{a,dylib}} $(BUILD_DIST)/libpopt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/popt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/libpopt-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# popt.mk Sign
	$(call SIGN,libpopt0,general.xml)

	# popt.mk Make .debs
	$(call PACK,libpopt0,DEB_POPT_V)
	$(call PACK,libpopt-dev,DEB_POPT_V)

	# popt.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpopt{0,-dev}

.PHONY: popt popt-package
