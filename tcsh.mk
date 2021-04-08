ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tcsh
TCSH_VERSION  := 6.22.03
DEB_TCSH_V    ?= $(TCSH_VERSION)

tcsh-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) ftp://ftp.astron.com/pub/tcsh/tcsh-$(TCSH_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,tcsh-$(TCSH_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,tcsh-$(TCSH_VERSION).tar.gz,tcsh-$(TCSH_VERSION),tcsh)
	$(call DO_PATCH,tcsh,tcsh,-p0)

ifneq ($(wildcard $(BUILD_WORK)/tcsh/.build_complete),)
tcsh:
	@echo "Using previously built tcsh."
else
tcsh: tcsh-setup ncurses
	cd $(BUILD_WORK)/tcsh && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		LDFLAGS="$(LDFLAGS) -lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/tcsh
	+$(MAKE) -C $(BUILD_WORK)/tcsh install \
		DESTDIR=$(BUILD_STAGE)/tcsh
	touch $(BUILD_WORK)/tcsh/.build_complete
endif
tcsh-package: tcsh-stage
	# tcsh.mk Package Structure
	rm -rf $(BUILD_DIST)/tcsh
	
	# tcsh.mk Prep tcsh
	cp -a $(BUILD_STAGE)/tcsh $(BUILD_DIST)
	
	# tcsh.mk Sign
	$(call SIGN,tcsh,general.xml)
	
	# tcsh.mk Make .debs
	$(call PACK,tcsh,DEB_TCSH_V)
	
	# tcsh.mk Build cleanup
	rm -rf $(BUILD_DIST)/tcsh

.PHONY: tcsh tcsh-package
