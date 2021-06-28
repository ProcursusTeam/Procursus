ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tmate
TMATE_VERSION := 2.4.0
DEB_TMATE_V   := $(TMATE_VERSION)

tmate-setup: setup
	$(call GITHUB_ARCHIVE,tmate-io,tmate,$(TMATE_VERSION),$(TMATE_VERSION))
	$(call EXTRACT_TAR,tmate-$(TMATE_VERSION).tar.gz,tmate-$(TMATE_VERSION),tmate)

ifneq ($(wildcard $(BUILD_WORK)/tmate/.build_complete),)
tmate:
	@echo "Using previously built tmate."
else
tmate: tmate-setup libevent ncurses msgpack libssh
	cd $(BUILD_WORK)/tmate && ./autogen.sh
	cd $(BUILD_WORK)/tmate && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/tmate install \
		DESTDIR="$(BUILD_STAGE)/tmate"
	touch $(BUILD_WORK)/tmate/.build_complete
endif
tmate-package: tmate-stage
	# tmate.mk Package Structure
	rm -rf $(BUILD_DIST)/tmate

	# tmate.mk Prep tmate
	cp -a $(BUILD_STAGE)/tmate $(BUILD_DIST)

	# tmate.mk Sign
	$(call SIGN,tmate,general.xml)

	# tmate.mk Make .debs
	$(call PACK,tmate,DEB_TMATE_V)

	# tmate.mk Build cleanup
	rm -rf $(BUILD_DIST)/tmate

.PHONY: tmate tmate-package
