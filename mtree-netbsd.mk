ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += mtree-netbsd
MTREE_NETBSD_VERSION := 20180822-6
DEB_MTREE_NETBSD_V   ?= $(MTREE_NETBSD_VERSION)

mtree-netbsd-setup: setup
	$(call GITHUB_ARCHIVE,jgoerzen,mtree-netbsd,$(MTREE_NETBSD_VERSION),debian/$(MTREE_NETBSD_VERSION))
	$(call EXTRACT_TAR,mtree-netbsd-$(MTREE_NETBSD_VERSION).tar.gz,mtree-netbsd-debian-$(MTREE_NETBSD_VERSION),mtree-netbsd)
	wget -q -nc -P $(BUILD_WORK)/mtree-netbsd https://raw.githubusercontent.com/NetBSD/src/trunk/lib/libc/gen/pwcache.{c,h}
	$(call DO_PATCH,mtree-netbsd,mtree-netbsd,-p1)

ifneq ($(wildcard $(BUILD_WORK)/mtree-netbsd/.build_complete),)
mtree-netbsd:
	@echo "Using previously built mtree-netbsd."
else
mtree-netbsd: mtree-netbsd-setup libmd
	cd $(BUILD_WORK)/mtree-netbsd && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--sbindir=\$${prefix}/bin \
		LIBS="-lmd" \
		ac_cv_func_fnmatch_works="yes"
	echo "#define HAVE_SHA512_FILE 1" >> $(BUILD_WORK)/mtree-netbsd/config.h
	+$(MAKE) -C $(BUILD_WORK)/mtree-netbsd
	+$(MAKE) -C $(BUILD_WORK)/mtree-netbsd install \
		DESTDIR=$(BUILD_STAGE)/mtree-netbsd
	touch $(BUILD_WORK)/mtree-netbsd/.build_complete
endif

mtree-netbsd-package: mtree-netbsd-stage
	# mtree-netbsd.mk Package Structure
	rm -rf $(BUILD_DIST)/mtree-netbsd
	mkdir -p $(BUILD_DIST)/mtree-netbsd

	# mtree-netbsd.mk Prep mtree-netbsd
	cp -a $(BUILD_STAGE)/mtree-netbsd $(BUILD_DIST)

	# mtree-netbsd.mk Sign
	$(call SIGN,mtree-netbsd,general.xml)

	# mtree-netbsd.mk Make .debs
	$(call PACK,mtree-netbsd,DEB_MTREE_NETBSD_V)

	# mtree-netbsd.mk Build cleanup
	rm -rf $(BUILD_DIST)/mtree-netbsd

.PHONY: mtree-netbsd mtree-netbsd-package
