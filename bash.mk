ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += bash
BASH_VERSION  := 5.1
DEB_BASH_V    ?= $(BASH_VERSION)

bash-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/bash/bash-$(BASH_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,bash-$(BASH_VERSION).tar.gz)
	$(call EXTRACT_TAR,bash-$(BASH_VERSION).tar.gz,bash-$(BASH_VERSION),bash)
	mkdir -p $(BUILD_STAGE)/bash/bin
	$(SED) -i 's/ENOEXEC)/ENOEXEC \&\& i != EPERM)/' $(BUILD_WORK)/bash/execute_cmd.c

ifneq ($(wildcard $(BUILD_WORK)/bash/.build_complete),)
bash:
	@echo "Using previously built bash."
else
bash: bash-setup ncurses readline
	@# TODO: This is kinda messy, clean up
	cd $(BUILD_WORK)/bash && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-nls \
		--with-installed-readline=$(BUILD_BASE)/usr/lib \
		CFLAGS="$(CFLAGS) -DSSH_SOURCE_BASHRC" \
		ac_cv_c_stack_direction=-1 \
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
		ac_cv_sys_interpreter=no
	+$(MAKE) -C $(BUILD_WORK)/bash \
		TERMCAP_LIB=-lncursesw
	+$(MAKE) -C $(BUILD_WORK)/bash install \
		DESTDIR="$(BUILD_STAGE)/bash"
	ln -s ../usr/bin/bash $(BUILD_STAGE)/bash/bin/bash
	ln -s ../usr/bin/bash $(BUILD_STAGE)/bash/bin/sh
	ln -s bash $(BUILD_STAGE)/bash/usr/bin/sh
	touch $(BUILD_WORK)/bash/.build_complete
endif

bash-package: bash-stage
	# bash.mk Package Structure
	rm -rf $(BUILD_DIST)/bash
	mkdir -p $(BUILD_DIST)/bash/usr

	# bash.mk Prep bash
	cp -a $(BUILD_STAGE)/bash/usr/{bin,include,lib} $(BUILD_DIST)/bash/usr
	cp -a $(BUILD_STAGE)/bash/bin $(BUILD_DIST)/bash

	# bash.mk Sign
	$(call SIGN,bash,general.xml)

	# bash.mk Make .debs
	$(call PACK,bash,DEB_BASH_V)

	# bash.mk Build cleanup
	rm -rf $(BUILD_DIST)/bash

.PHONY: bash bash-package
