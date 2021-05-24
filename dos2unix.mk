ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += dos2unix
DOS2UNIX_VERSION := 7.4.2
DEB_DOS2UNIX_V   ?= $(DOS2UNIX_VERSION)

dos2unix-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://waterlan.home.xs4all.nl/dos2unix/dos2unix-$(DOS2UNIX_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,dos2unix-$(DOS2UNIX_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,dos2unix-$(DOS2UNIX_VERSION).tar.gz,dos2unix-$(DOS2UNIX_VERSION),dos2unix)

ifneq ($(wildcard $(BUILD_WORK)/dos2unix/.build_complete),)
dos2unix:
	@echo "Using previously built dos2unix."
else
dos2unix: dos2unix-setup gettext
	+$(MAKE) -C $(BUILD_WORK)/dos2unix LDFLAGS="$(LDFLAGS)" prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/dos2unix install \
		DESTDIR=$(BUILD_STAGE)/dos2unix prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/dos2unix/.build_complete
endif

dos2unix-package: dos2unix-stage
	# dos2unix.mk Package Structure
	rm -rf $(BUILD_DIST)/dos2unix

	# dos2unix.mk Prep dos2unix-utils
	cp -a $(BUILD_STAGE)/dos2unix $(BUILD_DIST)

	# dos2unix.mk Sign
	$(call SIGN,dos2unix,general.xml)

	# dos2unix.mk Make .debs
	$(call PACK,dos2unix,DEB_DOS2UNIX_V)

	# dos2unix.mk Build cleanup
	rm -rf $(BUILD_DIST)/dos2unix

.PHONY: dos2unix dos2unix-package
