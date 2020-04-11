ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

BASH_VERSION := 5.0
DEB_BASH_V   ?= $(BASH_VERSION).$(BASH_SUB_V)

# When built with SSH_SOURCE_BASHRC, bash will source ~/.bashrc when
# it's non-interactively from sshd.  This allows the user to set
# environment variables prior to running the command (e.g. PATH).  The
# /bin/bash that ships with macOS defines this, and without it, some
# things (e.g. git+ssh) will break if the user sets their default shell to
# Homebrew's bash instead of /bin/bash.

ifneq ($(wildcard $(BUILD_WORK)/bash/.build_complete),)
bash:
	@echo "Using previously built bash."
else
bash: setup ncurses readline
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
		gt_cv_int_divbyzero_sigfpe=no
	$(MAKE) -C $(BUILD_WORK)/bash \
		TERMCAP_LIB=-lncursesw
	$(MAKE) -C $(BUILD_WORK)/bash install \
		DESTDIR="$(BUILD_STAGE)/bash"
	touch $(BUILD_WORK)/bash/.build_complete
endif

bash-package: BASH_SUB_V=$(shell find $(BUILD_WORK)/bash-$(BASH_VERSION)-patches -type f | wc -l)
bash-package: bash-stage
	# bash.mk Package Structure
	rm -rf $(BUILD_DIST)/bash
	mkdir -p $(BUILD_DIST)/bash/usr

	# bash.mk Prep bash
	$(FAKEROOT) cp -a $(BUILD_STAGE)/bash/usr/{bin,include,lib} $(BUILD_DIST)/bash/usr
	ln -s bash $(BUILD_DIST)/bash/usr/bin/sh

	# bash.mk Sign
	$(call SIGN,bash,general.xml)

	# bash.mk Make .debs
	$(call PACK,bash,DEB_BASH_V)

	# bash.mk Build cleanup
	rm -rf $(BUILD_DIST)/bash

.PHONY: bash bash-package