ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += autoconf
AUTOCONF_VERSION  := 2.71
DEB_AUTOCONF_V    ?= $(AUTOCONF_VERSION)

autoconf-setup: setup
	curl --silent -Z --create-dirs -C - --remote-name-all --output-dir $(BUILD_SOURCE) https://ftpmirror.gnu.org/autoconf/autoconf-$(AUTOCONF_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,autoconf-$(AUTOCONF_VERSION).tar.gz)
	$(call EXTRACT_TAR,autoconf-$(AUTOCONF_VERSION).tar.gz,autoconf-$(AUTOCONF_VERSION),autoconf)
	sed -i 's/libtoolize/glibtoolize/g' $(BUILD_WORK)/autoconf/bin/autoreconf.in
	sed -i 's/libtoolize/glibtoolize/g' $(BUILD_WORK)/autoconf/man/autoreconf.1

ifneq ($(wildcard $(BUILD_WORK)/autoconf/.build_complete),)
autoconf:
	@echo "Using previously built autoconf."
else
autoconf: autoconf-setup
	cd $(BUILD_WORK)/autoconf && PERL="$(shell command -v perl)" ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/autoconf
	+$(MAKE) -C $(BUILD_WORK)/autoconf install \
		DESTDIR=$(BUILD_STAGE)/autoconf
	$(call AFTER_BUILD,copy)
endif
autoconf-package: autoconf-stage
	# autoconf.mk Package Structure
	rm -rf $(BUILD_DIST)/autoconf

	# autoconf.mk Prep autoconf
	cp -a $(BUILD_STAGE)/autoconf $(BUILD_DIST)

	# autoconf.mk Sign
	$(call SIGN,autoconf,general.xml)

	# autoconf.mk Make .debs
	$(call PACK,autoconf,DEB_AUTOCONF_V)

	# autoconf.mk Build cleanup
	rm -rf $(BUILD_DIST)/autoconf

.PHONY: autoconf autoconf-package
