ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += m4
M4_VERSION  := 1.4.19
M4_REVISION := 1
DEB_M4_V    ?= $(M4_VERSION)-$(M4_REVISION)

m4-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/m4/m4-$(M4_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,m4-$(M4_VERSION).tar.gz)
	$(call EXTRACT_TAR,m4-$(M4_VERSION).tar.gz,m4-$(M4_VERSION),m4)
	$(call DO_PATCH,m4,m4,-p1)

ifneq ($(wildcard $(BUILD_WORK)/m4/.build_complete),)
m4:
	@echo "Using previously built m4."
else
m4: m4-setup gettext
	cd $(BUILD_WORK)/m4 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libintl-prefix=$(BUILD_BASE)/usr \
		--with-packager="Procursus" \
		--with-packager-version="revision $(M4_REVISION)" \
		--with-packager-bug-reports="https://github.com/ProcursusTeam/Procursus/issues" \
		M4_cv_func_rename_open_file_works=yes \
		ac_cv_c_undeclared_builtin_options='none needed' \
		ac_cv_func_calloc_0_nonnull=yes \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		ac_cv_have_decl_execvpe=no \
		ac_cv_header_libintl_h=yes \
		am_cv_func_iconv_works=yes \
		gl_cv_cc_long_double_expbit0='word 1 bit 20' \
		gl_cv_double_slash_root=no \
		gl_cv_func_btowc_eof=yes \
		gl_cv_func_btowc_nul=yes \
		gl_cv_func_dup2_works=yes \
		gl_cv_func_dup_works=yes \
		gl_cv_func_fcntl_f_dupfd_cloexec=yes \
		gl_cv_func_fcntl_f_dupfd_works=yes \
		gl_cv_func_fdopen_works=yes \
		gl_cv_func_fdopendir_works=yes \
		gl_cv_func_fflush_stdin=no \
		gl_cv_func_fopen_mode_e=no \
		gl_cv_func_fopen_mode_x=yes \
		gl_cv_func_fopen_slash=yes \
		gl_cv_func_fpurge_works=no \
		gl_cv_func_freopen_works_on_closed=yes \
		gl_cv_func_frexp_works=yes \
		gl_cv_func_frexpl_works=yes \
		gl_cv_func_fstatat_zero_flag=yes \
		gl_cv_func_ftello_works=yes \
		gl_cv_func_getcwd_null=yes \
		gl_cv_func_getcwd_path_max='no, but it is partly working' \
		gl_cv_func_getcwd_succeeds_beyond_4k=no \
		gl_cv_func_getdtablesize_works=yes \
		gl_cv_func_getopt_posix=no \
		gl_cv_func_isnanf_works=yes \
		gl_cv_func_isnanl_works=yes \
		gl_cv_func_iswcntrl_works=yes \
		gl_cv_func_iswdigit_works=yes \
		gl_cv_func_iswxdigit_works=yes \
		gl_cv_func_itold_works=yes \
		gl_cv_func_ldexpl_works=yes \
		gl_cv_func_link_works=no \
		gl_cv_func_lstat_dereferences_slashed_symlink=no \
		gl_cv_func_malloc_0_nonnull=1 \
		gl_cv_func_mbrtowc_C_locale_sans_EILSEQ=yes \
		gl_cv_func_mbrtowc_empty_input=yes \
		gl_cv_func_mbrtowc_incomplete_state=yes \
		gl_cv_func_mbrtowc_nul_retval=yes \
		gl_cv_func_mbrtowc_null_arg1=yes \
		gl_cv_func_mbrtowc_null_arg2=yes \
		gl_cv_func_mbrtowc_retval=yes \
		gl_cv_func_mbrtowc_sanitycheck=yes \
		gl_cv_func_mbrtowc_stores_incomplete=no \
		gl_cv_func_memchr_works=yes \
		gl_cv_func_mkdir_trailing_dot_works=yes \
		gl_cv_func_mkdir_trailing_slash_works=yes \
		gl_cv_func_nanosleep='no (mishandles large arguments)' \
		gl_cv_func_nl_langinfo_yesexpr_works=yes \
		gl_cv_func_open_slash=no \
		gl_cv_func_perror_works=yes \
		gl_cv_func_posix_spawn_secure_exec=yes \
		gl_cv_func_posix_spawn_works=yes \
		gl_cv_func_posix_spawnp_secure_exec=no \
		gl_cv_func_printf_directive_a=no \
		gl_cv_func_printf_directive_f=yes \
		gl_cv_func_printf_directive_ls=yes \
		gl_cv_func_printf_directive_n=no \
		gl_cv_func_printf_enomem=yes \
		gl_cv_func_printf_flag_grouping=yes \
		gl_cv_func_printf_flag_leftadjust=yes \
		gl_cv_func_printf_flag_zero=yes \
		gl_cv_func_printf_infinite=yes \
		gl_cv_func_printf_infinite_long_double=yes \
		gl_cv_func_printf_long_double=yes \
		gl_cv_func_printf_positions=yes \
		gl_cv_func_printf_precision=yes \
		gl_cv_func_printf_sizes_c99=yes \
		gl_cv_func_pthread_sigmask_in_libc_works=yes \
		gl_cv_func_pthread_sigmask_return_works=yes \
		gl_cv_func_re_compile_pattern_working=no \
		gl_cv_func_readlink_trailing_slash=no \
		gl_cv_func_readlink_truncate=yes \
		gl_cv_func_realpath_works=no \
		gl_cv_func_rename_dest_works=yes \
		gl_cv_func_rename_link_works=yes \
		gl_cv_func_rename_slash_dst_works=no \
		gl_cv_func_rename_slash_src_works=no \
		gl_cv_func_rmdir_works=yes \
		gl_cv_func_select_detects_ebadf=yes \
		gl_cv_func_select_supports0=yes \
		gl_cv_func_setenv_works=yes \
		gl_cv_func_setlocale_works=yes \
		gl_cv_func_signbit=yes \
		gl_cv_func_signbit_builtins=yes \
		gl_cv_func_sleep_works=yes \
		gl_cv_func_snprintf_retval_c99=yes \
		gl_cv_func_snprintf_size1=yes \
		gl_cv_func_snprintf_truncation_c99=yes \
		gl_cv_func_stat_file_slash=no \
		gl_cv_func_strerror_0_works=no \
		gl_cv_func_strndup_works=yes \
		gl_cv_func_strstr_linear=no \
		gl_cv_func_strstr_works_always=yes \
		gl_cv_func_strtod_works=yes \
		gl_cv_func_svid_putenv=no \
		gl_cv_func_symlink_works=no \
		gl_cv_func_ungetc_works=no \
		gl_cv_func_unsetenv_works=yes \
		gl_cv_func_wcrtomb_retval=yes \
		gl_cv_func_wcrtomb_works=yes \
		gl_cv_func_wctob_works=yes \
		gl_cv_func_wcwidth_works=no \
		gl_cv_func_working_mkstemp=yes \
		gl_cv_func_working_strsignal=yes \
		gl_cv_header_working_fcntl_h=yes \
		gl_cv_header_working_stdint_h=yes \
		gl_cv_struct_dirent_d_ino=yes \
		gt_cv_func_gnugettext3_libintl=yes \
		gt_cv_func_uselocale_works=yes \
		gt_cv_locale_fake=no \
		gt_use_preinstalled_gnugettext=yes \
		sv_cv_sigaltstack_low_base=yes
	+$(MAKE) -C $(BUILD_WORK)/m4
	+$(MAKE) -C $(BUILD_WORK)/m4 install \
		DESTDIR=$(BUILD_STAGE)/m4
	$(call AFTER_BUILD,copy)
endif
m4-package: m4-stage
	# m4.mk Package Structure
	rm -rf $(BUILD_DIST)/m4

	# m4.mk Prep m4
	cp -a $(BUILD_STAGE)/m4 $(BUILD_DIST)

	# m4.mk Sign
	$(call SIGN,m4,general.xml)

	# m4.mk Make .debs
	$(call PACK,m4,DEB_M4_V)

	# m4.mk Build cleanup
	rm -rf $(BUILD_DIST)/m4

.PHONY: m4 m4-package
