ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += findutils
FINDUTILS_VERSION := 4.8.0
DEB_FINDUTILS_V   ?= $(FINDUTILS_VERSION)

findutils-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/findutils/findutils-$(FINDUTILS_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,findutils-$(FINDUTILS_VERSION).tar.xz)
	$(call EXTRACT_TAR,findutils-$(FINDUTILS_VERSION).tar.xz,findutils-$(FINDUTILS_VERSION),findutils)

ifneq ($(wildcard $(BUILD_WORK)/findutils/.build_complete),)
findutils:
	@echo "Using previously built findutils."
else
findutils: findutils-setup gettext
	cd $(BUILD_WORK)/findutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--localstatedir=/var/cache/locate \
		--disable-dependency-tracking \
		--disable-debug \
		--without-selinux \
		--with-packager=Procursus \
		--enable-threads=posix \
		CFLAGS="$(CFLAGS) -D__nonnull\(params\)="
	+$(MAKE) -C $(BUILD_WORK)/findutils \
		SORT="/usr/bin/sort"
	+$(MAKE) -C $(BUILD_WORK)/findutils install \
		DESTDIR=$(BUILD_STAGE)/findutils
	touch $(BUILD_WORK)/findutils/.build_complete
endif

findutils-package: findutils-stage
	# findutils.mk Package Structure
	rm -rf $(BUILD_DIST)/findutils
	
	# findutils.mk Prep findutils
	cp -a $(BUILD_STAGE)/findutils $(BUILD_DIST)
	
	# findutils.mk Sign
	$(call SIGN,findutils,general.xml)
	
	# findutils.mk Make .debs
	$(call PACK,findutils,DEB_FINDUTILS_V)
	
	# findutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/findutils

.PHONY: findutils findutils-package
