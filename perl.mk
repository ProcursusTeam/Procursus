ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += perl
PERL_MAJOR   := 5.32
PERL_VERSION := $(PERL_MAJOR).0
PERL_API_V   := $(PERL_MAJOR).0
PERL_CROSS_V := 1.3.4
DEB_PERL_V   ?= $(PERL_VERSION)

perl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.cpan.org/src/5.0/perl-$(PERL_VERSION).tar.gz \
		https://github.com/arsv/perl-cross/releases/download/$(PERL_CROSS_V)/perl-cross-$(PERL_CROSS_V).tar.gz
	rm -rf $(BUILD_WORK)/perl
	$(call EXTRACT_TAR,perl-$(PERL_VERSION).tar.gz,perl-$(PERL_VERSION),perl)
	$(call EXTRACT_TAR,perl-cross-$(PERL_CROSS_V).tar.gz,perl-cross-$(PERL_CROSS_V),perl,1)
	$(SED) -i 's/readelf --syms/nm -g/g' $(BUILD_WORK)/perl/cnf/configure_type.sh
	$(SED) -i 's/readelf/nm/g' $(BUILD_WORK)/perl/cnf/configure__f.sh
	$(SED) -i 's/readelf/nm/g' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	$(SED) -i 's/bsd/darwin/g' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	$(SED) -i 's/BSD/Darwin/g' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	$(SED) -i '/try_link/ s/$$/ -Wno-error=implicit-function-declaration/' $(BUILD_WORK)/perl/cnf/configure_func.sh
	$(SED) -i '/-Wl,-E/ s/^/#/' $(BUILD_WORK)/perl/cnf/configure_tool.sh
	$(SED) -i '/-Wl,-E/ s/^/#/' $(BUILD_WORK)/perl/Makefile
	$(SED) -i 's/$$(CC) $$(LDDLFLAGS)/$$(CC) $$(LDDLFLAGS) -compatibility_version $(PERL_API_V) -current_version $(PERL_VERSION) -install_name $$(archlib)\/CORE\/$$@/g' $(BUILD_WORK)/perl/Makefile
	$(SED) -i 's/| $$Is{Android}/| $$Is{Darwin}/g' $(BUILD_WORK)/perl/cpan/ExtUtils-MakeMaker/lib/ExtUtils/MM_Unix.pm
	$(SED) -i 's/$$Is{Android} )/$$Is{Darwin} )/g' $(BUILD_WORK)/perl/cpan/ExtUtils-MakeMaker/lib/ExtUtils/MM_Unix.pm
	$(SED) -i '/$$Is{Solaris} =/a \ \ \ \ $$Is{Darwin}  = $$^O eq '\''darwin'\'';' $(BUILD_WORK)/perl/cpan/ExtUtils-MakeMaker/lib/ExtUtils/MM_Unix.pm
	$(SED) -i "s/&& $$^O ne 'darwin' //" $(BUILD_WORK)/perl/ext/Errno/Errno_pm.PL
	$(SED) -i "s/$$^O eq 'linux'/\$$Config{gccversion} ne ''/" $(BUILD_WORK)/perl/ext/Errno/Errno_pm.PL
	$(SED) -i 's/--sysroot=$$sysroot/-isysroot $$sysroot -arch $(MEMO_ARCH) $(PLATFORM_VERSION_MIN)/' $(BUILD_WORK)/perl/cnf/configure_tool.sh
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

	mkdir -p $(BUILD_WORK)/perl/include
	cp -a $(BUILD_BASE)/usr/include/unistd.h $(BUILD_WORK)/perl/include

ifneq ($(wildcard $(BUILD_WORK)/perl/.build_complete),)
perl:
	@echo "Using previously built perl."
else
perl: perl-setup
	@# Don't use $$(CFLAGS) here because, in the case BerkeleyDB was made before perl, it will look at the db.h in $$(BUILD_BASE).
	cd $(BUILD_WORK)/perl && CC='$(CC)' AR='$(AR)' NM='$(NM)' OBJDUMP='objdump' CFLAGS='-DPERL_DARWIN -DPERL_USE_SAFE_PUTENV -DTIME_HIRES_CLOCKID_T -O2 -arch $(MEMO_ARCH) -isysroot $(TARGET_SYSROOT) -isystem $(BUILD_WORK)/perl/include $(PLATFORM_VERSION_MIN)' ./configure \
		--target=$(GNU_HOST_TRIPLE) \
		--sysroot=$(TARGET_SYSROOT) \
		--prefix=/usr \
		-Duseshrplib \
		-Dusevendorprefix \
		-Dvendorprefix=/usr \
		-Dusethreads \
		-Dvendorlib=/usr/share/perl5 \
		-Dvendorarch=/usr/lib/perl5/$(PERL_VERSION)
	+$(MAKE) -C $(BUILD_WORK)/perl \
		PERL_ARCHIVE=$(BUILD_WORK)/perl/libperl.dylib
	+$(MAKE) -C $(BUILD_WORK)/perl install.perl \
		DESTDIR=$(BUILD_STAGE)/perl
	touch $(BUILD_WORK)/perl/.build_complete
endif

perl-package: perl-stage
	# perl.mk Package Structure
	rm -rf $(BUILD_DIST)/perl
	mkdir -p $(BUILD_DIST)/perl
	
	# perl.mk Prep perl
	cp -a $(BUILD_STAGE)/perl/usr $(BUILD_DIST)/perl
	
	# perl.mk Sign
	$(call SIGN,perl,general.xml)
	
	# perl.mk Make .debs
	$(call PACK,perl,DEB_PERL_V)
	
	# perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/perl

.PHONY: perl perl-package
