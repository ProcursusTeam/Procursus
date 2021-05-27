ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += rc
RC_VERSION  := 1.7.4
DEB_RC_V    ?= $(RC_VERSION)-1

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
RC_CONFIGURE_ARGS := LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec -lreadline -lncursesw"
else
RC_CONFIGURE_ARGS := LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lreadline -lncursesw"
endif

rc-setup: setup
	$(call GITHUB_ARCHIVE,rakitzis,rc,$(RC_VERSION),v$(RC_VERSION))
	$(call EXTRACT_TAR,rc-$(RC_VERSION).tar.gz,rc-$(RC_VERSION),rc)
	$(call DO_PATCH,rc,rc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/rc/.build_complete),)
rc:
	@echo "Using previously built rc."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
rc: rc-setup readline ncurses
else
rc: rc-setup readline ncurses libiosexec
endif
	cd $(BUILD_WORK)/rc && autoreconf -fi && ac_cv_func_setpgrp_void=yes ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-edit=readline \
		rc_cv_sysv_sigcld=false \
		$(RC_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/rc
	+$(MAKE) -C $(BUILD_WORK)/rc install \
		DESTDIR=$(BUILD_STAGE)/rc
	touch $(BUILD_WORK)/rc/.build_complete
endif

rc-package: rc-stage
	# rc.mk Package Structure
	rm -rf $(BUILD_DIST)/rc

	# rc.mk Prep rc
	cp -a $(BUILD_STAGE)/rc $(BUILD_DIST)

	# rc.mk Sign
	$(call SIGN,rc,general.xml)

	# rc.mk Make .debs
	$(call PACK,rc,DEB_RC_V)

	# rc.mk Build cleanup
	rm -rf $(BUILD_DIST)/rc

.PHONY: rc rc-package
