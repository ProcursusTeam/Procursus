ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# When built with SSH_SOURCE_BASHRC, bash will source ~/.bashrc when
# it's non-interactively from sshd.  This allows the user to set
# environment variables prior to running the command (e.g. PATH).  The
# /bin/bash that ships with macOS defines this, and without it, some
# things (e.g. git+ssh) will break if the user sets their default shell to
# Homebrew's bash instead of /bin/bash.

bash:
	@# TODO: This is kinda messy, clean up
	sed -i s/'#undef HAVE_SYS_SIGLIST'/'#define HAVE_SYS_SIGLIST 1'/ bash/config.h.in
	cd bash && CFLAGS="$(CFLAGS) -DSSH_SOURCE_BASHRC" \
		./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-installed-readline \
		bash_cv_dev_fd=absent \
		bash_cv_sys_named_pipes=present \
		bash_cv_job_control_missing=present \
		bash_cv_func_sigsetjmp=present \
		bash_cv_func_ctype_nonascii=no \
		bash_cv_must_reinstall_sighandlers=no \
		bash_cv_func_strcoll_broken=yes \
		ac_cv_c_stack_direction=-1 \
		ac_cv_func_mmap_fixed_mapped=yes \
		gt_cv_int_divbyzero_sigfpe=no \
		ac_cv_func_setvbuf_reversed=no \
		ac_cv_func_strcoll_works=yes \
		ac_cv_func_working_mktime=yes \
		ac_cv_type_getgroups=gid_t \
		bash_cv_dup2_broken=no \
		ac_cv_prog_cc_g=no \
		ac_cv_rl_version=6.0
	$(MAKE) -C bash
	$(FAKEROOT) $(MAKE) -C bash install DESTDIR="$(DESTDIR)"

.PHONY: bash
