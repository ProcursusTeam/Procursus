ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                += libpod-parser-perl
LIBPOD-PARSER-PERL_VERSION := 1.63
DEB_LIBPOD-PARSER-PERL_V   ?= $(LIBPOD-PARSER-PERL_VERSION)

libpod-parser-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libpod-parser-perl-$(LIBPOD-PARSER-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libpod-parser-perl-$(LIBPOD-PARSER-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/M/MA/MAREKR/Pod-Parser-$(LIBPOD-PARSER-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libpod-parser-perl-$(LIBPOD-PARSER-PERL_VERSION).tar.gz,Pod-Parser-$(LIBPOD-PARSER-PERL_VERSION),libpod-parser-perl)

ifneq ($(wildcard $(BUILD_WORK)/libpod-parser-perl/.build_complete),)
libpod-parser-perl:
	@echo "Using previously built libpod-parser-perl."
else
libpod-parser-perl: libpod-parser-perl-setup perl
	cd $(BUILD_WORK)/libpod-parser-perl && /opt/procursus/bin/perl Makefile.PL \
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
	+$(MAKE) -C $(BUILD_WORK)/libpod-parser-perl
	+$(MAKE) -C $(BUILD_WORK)/libpod-parser-perl install \
		DESTDIR="$(BUILD_STAGE)/libpod-parser-perl"
	rm -rf $(BUILD_STAGE)/libpod-parser-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/libpod-parser-perl/.build_complete
endif

libpod-parser-perl-package: libpod-parser-perl-stage
	# libpod-parser-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libpod-parser-perl
	
	# libpod-parser-perl.mk Prep libpod-parser-perl
	cp -a $(BUILD_STAGE)/libpod-parser-perl $(BUILD_DIST)
	
	# libpod-parser-perl.mk Make .debs
	$(call PACK,libpod-parser-perl,DEB_LIBPOD-PARSER-PERL_V)
	
	# libpod-parser-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpod-parser-perl

.PHONY: libpod-parser-perl libpod-parser-perl-package
