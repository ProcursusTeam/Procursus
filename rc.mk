ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += rc
RC_VERSION  := 1.7.4
DEB_RC_V    ?= $(RC_VERSION)

rc-setup: setup
	wget -O $(BUILD_SOURCE)/rc-$(RC_VERSION).tar.gz https://github.com/rakitzis/rc/archive/refs/tags/v$(RC_VERSION).tar.gz
	$(call EXTRACT_TAR,rc-$(RC_VERSION).tar.gz,rc-$(RC_VERSION),rc)
	$(call DO_PATCH,rc,rc,-p1)

ifneq ($(wildcard $(BUILD_WORK)/rc/.build_complete),)
rc:
	@echo "Using previously built rc."
else
rc: rc-setup readline
	cd $(BUILD_WORK)/rc && autoreconf -fi && ac_cv_func_setpgrp_void=yes ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-edit=readline \

	sed -i 's/HAVE_SYSV_SIGCLD\ 1/HAVE_SYSV_SIGCLD\ 0/g' $(BUILD_WORK)/rc/config.h
	
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
