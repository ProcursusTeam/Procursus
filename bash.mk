ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += bash
BASH_VERSION  := 5.0
DEB_BASH_V    ?= $(BASH_VERSION).$(BASH_SUB_V)

# When built with SSH_SOURCE_BASHRC, bash will source ~/.bashrc when
# it's non-interactively from sshd.  This allows the user to set
# environment variables prior to running the command (e.g. PATH).  The
# /bin/bash that ships with macOS defines this, and without it, some
# things (e.g. git+ssh) will break if the user sets their default shell to
# Homebrew's bash instead of /bin/bash.

bash-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/bash/bash-$(BASH_VERSION).tar.gz{,.sig} \
		https://ftpmirror.gnu.org/bash/bash-$(BASH_VERSION)-patches/bash50-00{1..9}{,.sig} \
		https://ftpmirror.gnu.org/bash/bash-$(BASH_VERSION)-patches/bash50-0{10..18}{,.sig}
	$(call PGP_VERIFY,bash-$(BASH_VERSION).tar.gz)
	$(call PGP_VERIFY,bash50-001)
	$(call PGP_VERIFY,bash50-002)
	$(call PGP_VERIFY,bash50-003)
	$(call PGP_VERIFY,bash50-004)
	$(call PGP_VERIFY,bash50-005)
	$(call PGP_VERIFY,bash50-006)
	$(call PGP_VERIFY,bash50-007)
	$(call PGP_VERIFY,bash50-008)
	$(call PGP_VERIFY,bash50-009)
	$(call PGP_VERIFY,bash50-010)
	$(call PGP_VERIFY,bash50-011)
	$(call PGP_VERIFY,bash50-012)
	$(call PGP_VERIFY,bash50-013)
	$(call PGP_VERIFY,bash50-014)
	$(call PGP_VERIFY,bash50-015)
	$(call PGP_VERIFY,bash50-016)
	$(call PGP_VERIFY,bash50-017)
	$(call PGP_VERIFY,bash50-018)
	$(call EXTRACT_TAR,bash-$(BASH_VERSION).tar.gz,bash-$(BASH_VERSION),bash)
	mkdir -p $(BUILD_STAGE)/bash/bin
	mkdir -p $(BUILD_PATCH)/bash-$(BASH_VERSION)
	find $(BUILD_SOURCE) -name 'bash50*' -not -name '*.sig' -exec cp '{}' $(BUILD_PATCH)/bash-$(BASH_VERSION)/ \;
	$(call DO_PATCH,bash-$(BASH_VERSION),bash,-p0)
	$(SED) -i 's/ENOEXEC)/ENOEXEC \&\& i != EPERM)/' $(BUILD_WORK)/bash/execute_cmd.c

ifneq ($(wildcard $(BUILD_WORK)/bash/.build_complete),)
bash:
	@echo "Using previously built bash."
else
bash: bash-setup ncurses readline
	@# TODO: This is kinda messy, clean up
	cd $(BUILD_WORK)/bash && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-nls \
		--with-installed-readline=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
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
	ln -s ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bash $(BUILD_STAGE)/bash/$(MEMO_PREFIX)/bin/bash
	ln -s ../$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/bash $(BUILD_STAGE)/bash/$(MEMO_PREFIX)/bin/sh
	ln -s bash $(BUILD_STAGE)/bash/$(MEMO_PREFIX)/bin/sh
	touch $(BUILD_WORK)/bash/.build_complete
endif

bash-package: BASH_SUB_V=$(shell find $(BUILD_PATCH)/bash-$(BASH_VERSION) -type f | $(WC) -l)
bash-package: bash-stage
	# bash.mk Package Structure
	rm -rf $(BUILD_DIST)/bash
	mkdir -p $(BUILD_DIST)/bash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# bash.mk Prep bash
	cp -a $(BUILD_STAGE)/bash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,lib} $(BUILD_DIST)/bash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/bash/bin $(BUILD_DIST)/bash

	# bash.mk Sign
	$(call SIGN,bash,general.xml)

	# bash.mk Make .debs
	$(call PACK,bash,DEB_BASH_V)

	# bash.mk Build cleanup
	rm -rf $(BUILD_DIST)/bash

.PHONY: bash bash-package
