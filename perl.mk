ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

PERL_MAJOR   := 5.30
PERL_VERSION := $(PERL_MAJOR).1
PERL_API_V   := $(PERL_MAJOR).0
PERL_CROSS_V := 1.3.2
DEB_PERL_V   ?= $(PERL_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/perl/.build_complete),)
perl:
	@echo "Using previously built perl."
else
perl: setup
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
	touch $(BUILD_WORK)/perl/cnf/hints/darwin
	echo -e "# Linux syscalls\n\
	d_voidsig='undef'\n\
	d_nanosleep='define'\n\
	d_clock_gettime='define'\n\
	d_clock_getres='define'\n\
	d_clock_nanosleep='undef'\n\
	d_clock='define'\n\
	libperl='libperl.dylib'" > $(BUILD_WORK)/perl/cnf/hints/darwin
	cd $(BUILD_WORK)/perl && CFLAGS='-DPERL_DARWIN -DPERL_USE_SAFE_PUTENV -DTIME_HIRES_CLOCKID_T $(CFLAGS)' ./configure \
	--target=$(GNU_HOST_TRIPLE) \
	--sysroot=$(SYSROOT) \
	--prefix=/usr \
	-Duseshrplib \
	-Dusevendorprefix \
	-Dvendorprefix=/usr \
	-Dusethreads \
	-Dbyteorder=12345678 \
	-Dvendorlib=/usr/share/perl5 \
	-Dvendorarch=/usr/lib/perl5/$(PERL_VERSION)
	make -C $(BUILD_WORK)/perl \
		PERL_ARCHIVE=$(BUILD_WORK)/perl/libperl.dylib
	touch $(BUILD_WORK)/perl/.build_complete
	make -C $(BUILD_WORK)/perl install.perl \
		DESTDIR=$(BUILD_STAGE)/perl
endif

perl-package: perl-stage
	# perl.mk Package Structure
	rm -rf $(BUILD_DIST)/perl
	mkdir -p $(BUILD_DIST)/perl
	
	# perl.mk Prep perl
	$(FAKEROOT) cp -a $(BUILD_STAGE)/perl/usr $(BUILD_DIST)/perl
	
	# perl.mk Sign
	$(call SIGN,perl,general.xml)
	
	# perl.mk Make .debs
	$(call PACK,perl,DEB_PERL_V)
	
	# perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/perl

.PHONY: perl perl-package
