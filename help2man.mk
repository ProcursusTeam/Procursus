ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += help2man
HELP2MAN_VERSION  := 1.48.3
DEB_HELP2MAN_V    ?= $(HELP2MAN_VERSION)

help2man-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://mirrors.kernel.org/gnu/help2man/help2man-$(HELP2MAN_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,help2man-$(HELP2MAN_VERSION).tar.xz)
	$(call EXTRACT_TAR,help2man-$(HELP2MAN_VERSION).tar.xz,help2man-$(HELP2MAN_VERSION),help2man)

ifneq ($(wildcard $(BUILD_WORK)/help2man/.build_complete),)
help2man:
	@echo "Using previously built help2man."
else
help2man: help2man-setup gettext
	cd $(BUILD_WORK)/help2man && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/help2man
	+$(MAKE) -C $(BUILD_WORK)/help2man install \
		DESTDIR=$(BUILD_STAGE)/help2man
	+$(MAKE) -C $(BUILD_WORK)/help2man install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/help2man/.build_complete
endif
help2man-package: help2man-stage
	# help2man.mk Package Structure
	rm -rf $(BUILD_DIST)/help2man

	# help2man.mk Prep help2man
	cp -a $(BUILD_STAGE)/help2man $(BUILD_DIST)

	# help2man.mk Sign
	$(call SIGN,help2man,general.xml)

	# help2man.mk Make .debs
	$(call PACK,help2man,DEB_HELP2MAN_V)

	# help2man.mk Build cleanup
	rm -rf $(BUILD_DIST)/help2man

.PHONY: help2man help2man-package
