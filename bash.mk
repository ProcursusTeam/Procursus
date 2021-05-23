ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += bash
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS   += bash
endif # ($(MEMO_TARGET),darwin-\*)
BASH_VERSION  := 5.1
BASH_SUB_V    := 008
DEB_BASH_V    ?= $(BASH_VERSION).$(BASH_SUB_V)

bash-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/bash/bash-$(BASH_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,bash-$(BASH_VERSION).tar.gz)
	$(call EXTRACT_TAR,bash-$(BASH_VERSION).tar.gz,bash-$(BASH_VERSION),bash)
	mkdir -p $(BUILD_STAGE)/bash/$(MEMO_PREFIX)/bin
	$(call DO_PATCH,bash,bash,-p0)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(SED) -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_WORK)/bash/execute_cmd.h
BASH_CONFIGURE_ARGS := ac_cv_c_stack_direction=-1 \
	ac_cv_func_mmap_fixed_mapped=yes \
	ac_cv_func_setvbuf_reversed=no \
	ac_cv_func_strcoll_works=yes \
	ac_cv_func_working_mktime=yes \
	ac_cv_prog_cc_g=no \
	ac_cv_rl_version=8.0 \
	ac_cv_type_getgroups=gid_t \
	bash_cv_dev_fd=absent \
	bash_cv_dup2_broken=no \
	bash_cv_func_ctype_nonascii=no \
	bash_cv_func_sigsetjmp=present \
	bash_cv_func_strcoll_broken=yes \
	bash_cv_job_control_missing=present \
	bash_cv_must_reinstall_sighandlers=no \
	bash_cv_sys_named_pipes=present \
	bash_cv_sys_siglist=yes \
	gt_cv_int_divbyzero_sigfpe=no \
	LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec"
endif

ifneq ($(wildcard $(BUILD_WORK)/bash/.build_complete),)
bash:
	@echo "Using previously built bash."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
bash: bash-setup ncurses readline
else
bash: bash-setup ncurses readline libiosexec
endif
	cd $(BUILD_WORK)/bash && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-nls \
		--with-installed-readline=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		CFLAGS="$(CFLAGS) -DSSH_SOURCE_BASHRC" \
		$(BASH_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/bash \
		CC_FOR_BUILD='$(shell which cc)' \
		TERMCAP_LIB=-lncursesw
	+$(MAKE) -C $(BUILD_WORK)/bash install \
		DESTDIR="$(BUILD_STAGE)/bash"
ifneq ($(MEMO_SUB_PREFIX),)
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bash $(BUILD_STAGE)/bash/$(MEMO_PREFIX)/bin/bash
endif
	touch $(BUILD_WORK)/bash/.build_complete
endif

bash-package: bash-stage
	# bash.mk Package Structure
	rm -rf $(BUILD_DIST)/bash

	# bash.mk Prep bash
	cp -a $(BUILD_STAGE)/bash $(BUILD_DIST)

	# bash.mk Sign
	$(call SIGN,bash,general.xml)

	# bash.mk Make .debs
	$(call PACK,bash,DEB_BASH_V)

	# bash.mk Build cleanup
	rm -rf $(BUILD_DIST)/bash

.PHONY: bash bash-package
