ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS     += findutils
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS       += findutils
endif # ($(MEMO_TARGET),darwin-\*)
FINDUTILS_VERSION := 4.8.0
DEB_FINDUTILS_V   ?= $(FINDUTILS_VERSION)-1

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
FINDUTILS_CONFIGURE_ARGS += --program-prefix=$(GNU_PREFIX)
endif

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
		$(DEFAULT_CONFIGURE_FLAGS) \
		--localstatedir=$(MEMO_PREFIX)/var/cache/locate \
		--disable-dependency-tracking \
		--disable-debug \
		--without-selinux \
		--with-packager=Procursus \
		--enable-threads=posix \
		$(FINDUTILS_CONFIGURE_ARGS) \
		CFLAGS="$(CFLAGS) -D__nonnull\(params\)="
	+$(MAKE) -C $(BUILD_WORK)/findutils \
		SORT="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$(GNU_PREFIX)sort"
	+$(MAKE) -C $(BUILD_WORK)/findutils install \
		DESTDIR=$(BUILD_STAGE)/findutils
	touch $(BUILD_WORK)/findutils/.build_complete
endif

findutils-package: findutils-stage
	# findutils.mk Package Structure
	rm -rf $(BUILD_DIST)/findutils

	# findutils.mk Prep findutils
	cp -a $(BUILD_STAGE)/findutils $(BUILD_DIST)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/findutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/findutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin##/*} $(BUILD_DIST)/findutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $${bin##/*} | cut -c2-); \
	done
endif

	# findutils.mk Sign
	$(call SIGN,findutils,general.xml)

	# findutils.mk Make .debs
	$(call PACK,findutils,DEB_FINDUTILS_V)

	# findutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/findutils

.PHONY: findutils findutils-package
