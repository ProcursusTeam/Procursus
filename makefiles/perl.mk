ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += perl
PERL_MAJOR   := 5.32
PERL_VERSION := $(PERL_MAJOR).1
PERL_API_V   := $(PERL_MAJOR).0
PERL_CROSS_V := 1.3.5
DEB_PERL_V   ?= $(PERL_VERSION)

export PERL_MAJOR

perl-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE) https://www.cpan.org/src/5.0/perl-$(PERL_VERSION).tar.gz, \
		https://github.com/arsv/perl-cross/releases/download/$(PERL_CROSS_V)/perl-cross-$(PERL_CROSS_V).tar.gz)
	rm -rf $(BUILD_WORK)/perl
	$(call EXTRACT_TAR,perl-$(PERL_VERSION).tar.gz,perl-$(PERL_VERSION),perl)
	chmod -R +w $(BUILD_WORK)/perl
	$(call EXTRACT_TAR,perl-cross-$(PERL_CROSS_V).tar.gz,perl-cross-$(PERL_CROSS_V),perl,1)
	sed -i 's/readelf --syms/nm -g/g' $(BUILD_WORK)/perl/cnf/configure_type.sh
	sed -i 's/readelf/nm/g' $(BUILD_WORK)/perl/cnf/configure__f.sh
	sed -i 's/readelf/nm/g' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	sed -i 's/bsd/darwin/g' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	sed -i 's/BSD/Darwin/g' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	sed -i '/try_link/ s/$$/ -Wno-error=implicit-function-declaration/' $(BUILD_WORK)/perl/cnf/configure_func.sh
	sed -i '/-Wl,-E/ s/^/#/' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	sed -i '/-Wl,-E/ s/^/#/' $(BUILD_WORK)/perl/Makefile
	sed -i 's/$$(CC) $$(LDDLFLAGS)/$$(CC) $$(LDDLFLAGS) -compatibility_version $(PERL_API_V) -current_version $(PERL_VERSION) -install_name $$(archlib)\/CORE\/$$@/g' $(BUILD_WORK)/perl/Makefile
	sed -i 's/| $$Is{Android}/| $$Is{Darwin}/g' $(BUILD_WORK)/perl/cpan/ExtUtils-MakeMaker/lib/ExtUtils/MM_Unix.pm
	sed -i 's/$$Is{Android} )/$$Is{Darwin} )/g' $(BUILD_WORK)/perl/cpan/ExtUtils-MakeMaker/lib/ExtUtils/MM_Unix.pm
	sed -i '/$$Is{Solaris} =/a \ \ \ \ $$Is{Darwin}  = $$^O eq '\''darwin'\'';' $(BUILD_WORK)/perl/cpan/ExtUtils-MakeMaker/lib/ExtUtils/MM_Unix.pm
	sed -i "s/&& $$^O ne 'darwin' //" $(BUILD_WORK)/perl/ext/Errno/Errno_pm.PL
	sed -i "s/$$^O eq 'linux'/\$$Config{gccversion} ne ''/" $(BUILD_WORK)/perl/ext/Errno/Errno_pm.PL
	sed -i 's/--sysroot=$$sysroot/-isysroot $$sysroot -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN)/' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	touch $(BUILD_WORK)/perl/cnf/hints/darwin
	echo -e "# Linux syscalls\n\
	d_voidsig='undef'\n\
	d_nanosleep='define'\n\
	d_clock_gettime='define'\n\
	d_clock_getres='define'\n\
	d_clock_nanosleep='undef'\n\
	d_clock='define'\n\
	byteorder='12345678'\n\
	libperl='libperl.dylib'" > $(BUILD_WORK)/perl/cnf/hints/darwin

ifneq ($(wildcard $(BUILD_WORK)/perl/.build_complete),)
perl:
	@echo "Using previously built perl."
else
perl: perl-setup
	cd $(BUILD_WORK)/perl && \
	CC='$(CC)' AR='$(AR)' NM='$(NM)' OBJDUMP='objdump' \
	HOSTCFLAGS='-DPERL_CORE -DUSE_CROSS_COMPILE -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 $(CFLAGS_FOR_BUILD)' \
	HOSTLDFLAGS='$(LDFLAGS_FOR_BUILD)' \
	CFLAGS='-DPERL_DARWIN -DPERL_USE_SAFE_PUTENV -DTIME_HIRES_CLOCKID_T -DLIBIOSEXEC_INTERNAL=1 $(patsubst -flto=thin,,$(CFLAGS))' \
	LDFLAGS='$(patsubst -flto=thin,,$(LDFLAGS))' ./configure \
		--build=$$($(BUILD_MISC)/config.guess) \
		--target=$(GNU_HOST_TRIPLE) \
		--sysroot=$(TARGET_SYSROOT) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-Duseshrplib \
		-Dusevendorprefix \
		-Dvendorprefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		-Dusethreads \
		-Dvendorlib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		-Dprivlib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		-Darchlib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		-Dvendorarch=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)
	+$(MAKE) -C $(BUILD_WORK)/perl -j1 \
		PERL_ARCHIVE=$(BUILD_WORK)/perl/libperl.dylib \
		LIBS="$(filter -liosexec,$(LDFLAGS))"
	+$(MAKE) -C $(BUILD_WORK)/perl install.perl \
		DESTDIR=$(BUILD_STAGE)/perl
	$(LN_S) $(PERL_MAJOR) $(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_VERSION)
	chmod -R u+w $(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)
	$(call AFTER_BUILD)
endif

perl-package: perl-stage
	# perl.mk Package Structure
	rm -rf $(BUILD_DIST)/perl

	# perl.mk Prep perl
	cp -a $(BUILD_STAGE)/perl $(BUILD_DIST)

	# perl.mk Sign
	$(call SIGN,perl,general.xml)

	# perl.mk Make .debs
	$(call PACK,perl,DEB_PERL_V)

	# perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/perl

.PHONY: perl perl-package
