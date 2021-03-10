ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                    += liblocale-gettext-perl
LIBLOCALE-GETTEXT-PERL_VERSION := 1.07
DEB_LIBLOCALE-GETTEXT-PERL_V   ?= $(LIBLOCALE-GETTEXT-PERL_VERSION)

liblocale-gettext-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/liblocale-gettext-perl-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/liblocale-gettext-perl-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/P/PV/PVANDRY/gettext-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,liblocale-gettext-perl-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz,Locale-gettext-$(LIBLOCALE-GETTEXT-PERL_VERSION),liblocale-gettext-perl)

ifneq ($(wildcard $(BUILD_WORK)/liblocale-gettext-perl/.build_complete),)
liblocale-gettext-perl:
	@echo "Using previously built liblocale-gettext-perl."
else
liblocale-gettext-perl: liblocale-gettext-perl-setup perl gettext
	cd $(BUILD_WORK)/liblocale-gettext-perl && /opt/procursus/bin/perl Makefile.PL \
		INSTALLSITEARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLARCHLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLVENDORARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLPRIVLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		INSTALLSITELIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		INSTALLVENDORLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		PERL_LIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_ARCHLIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_ARCHLIBDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_INC=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
		PERL_INCDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		INSTALLMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLSITEMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLVENDORMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		INSTALLSITEMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		INSTALLVENDORMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		PERL="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl" \
		CCFLAGS="$(CFLAGS)" \
		LDDLFLAGS="$(LDFLAGS) -shared"
	+$(MAKE) -C $(BUILD_WORK)/liblocale-gettext-perl
	+$(MAKE) -C $(BUILD_WORK)/liblocale-gettext-perl install \
		DESTDIR="$(BUILD_STAGE)/liblocale-gettext-perl"
	rm -f $(BUILD_STAGE)/liblocale-gettext-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/perllocal.pod
	touch $(BUILD_WORK)/liblocale-gettext-perl/.build_complete
endif

liblocale-gettext-perl-package: liblocale-gettext-perl-stage
	# liblocale-gettext-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/liblocale-gettext-perl
	
	# liblocale-gettext-perl.mk Prep liblocale-gettext-perl
	cp -a $(BUILD_STAGE)/liblocale-gettext-perl $(BUILD_DIST)

	# liblocale-gettext-perl.mk Sign
	$(call SIGN,liblocale-gettext-perl,general.xml)
	
	# liblocale-gettext-perl.mk Make .debs
	$(call PACK,liblocale-gettext-perl,DEB_LIBLOCALE-GETTEXT-PERL_V)
	
	# liblocale-gettext-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblocale-gettext-perl

.PHONY: liblocale-gettext-perl liblocale-gettext-perl-package
