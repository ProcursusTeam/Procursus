ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                += libxml-parser-perl
LIBXML_PARSER_PERL_VERSION := 2.46
DEB_LIBXML_PARSER_PERL_V   ?= $(LIBXML_PARSER_PERL_VERSION)

libxml-parser-perl-setup: setup
	-[ ! -f $(BUILD_SOURCE)/libxml-parser-perl-$(LIBXML_PARSER_PERL_VERSION).tar.gz ] && \
			wget -q -nc -O$(BUILD_SOURCE)/libxml-parser-perl-$(LIBXML_PARSER_PERL_VERSION).tar.gz \
				https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-$(LIBXML_PARSER_PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libxml-parser-perl-$(LIBXML_PARSER_PERL_VERSION).tar.gz,XML-Parser-$(LIBXML_PARSER_PERL_VERSION),libxml-parser-perl)

ifneq ($(wildcard $(BUILD_WORK)/libxml-parser-perl/.build_complete),)
libxml-parser-perl:
	@echo "Using previously built libxml-parser-perl."
else
libxml-parser-perl: libxml-parser-perl-setup perl expat
	cd $(BUILD_WORK)/libxml-parser-perl && /opt/procursus/bin/perl Makefile.PL \
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
		PERL="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl" \
		CCFLAGS="$(CFLAGS)" \
		LDDLFLAGS="$(LDFLAGS) -shared"
	+$(MAKE) -C $(BUILD_WORK)/libxml-parser-perl
	+$(MAKE) -C $(BUILD_WORK)/libxml-parser-perl install \
		DESTDIR="$(BUILD_STAGE)/libxml-parser-perl"
	rm -f $(BUILD_STAGE)/libxml-parser-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/*/perllocal.pod
	touch $(BUILD_WORK)/libxml-parser-perl/.build_complete
endif

libxml-parser-perl-package: libxml-parser-perl-stage
	# libxml-parser-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libxml-parser-perl
	
	# libxml-parser-perl.mk Prep libxml-parser-perl
	cp -a $(BUILD_STAGE)/libxml-parser-perl $(BUILD_DIST)
	
	# libxml-parser-perl.mk Make .debs
	$(call PACK,libxml-parser-perl,DEB_LIBXML_PARSER_PERL_V)
	
	# libxml-parser-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxml-parser-perl

.PHONY: libxml-parser-perl libxml-parser-perl-package
