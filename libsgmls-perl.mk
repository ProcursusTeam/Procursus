ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += libsgmls-perl
LIBSGMLS-PERL_VERSION := 1.1
DEB_LIBSGMLS-PERL_V   ?= $(LIBSGMLS-PERL_VERSION)

libsgmls-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libsgmls-perl-$(LIBSGMLS-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libsgmls-perl-$(LIBSGMLS-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/R/RA/RAAB/SGMLSpm-$(LIBSGMLS-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libsgmls-perl-$(LIBSGMLS-PERL_VERSION).tar.gz,SGMLSpm-$(LIBSGMLS-PERL_VERSION),libsgmls-perl)
	chmod -R 0744 $(BUILD_WORK)/libsgmls-perl

ifneq ($(wildcard $(BUILD_WORK)/libsgmls-perl/.build_complete),)
libsgmls-perl:
	@echo "Using previously built libsgmls-perl."
else
libsgmls-perl: libsgmls-perl-setup perl
	cd $(BUILD_WORK)/libsgmls-perl && /opt/procursus/bin/perl Makefile.PL \
		INSTALLSITEARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLARCHLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLVENDORARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLPRIVLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
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
	+$(MAKE) -C $(BUILD_WORK)/libsgmls-perl
	+$(MAKE) -C $(BUILD_WORK)/libsgmls-perl install \
		DESTDIR="$(BUILD_STAGE)/libsgmls-perl"
	rm -rf $(BUILD_STAGE)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mv $(BUILD_STAGE)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sgmlspl.pl $(BUILD_STAGE)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sgmlspl
	touch $(BUILD_WORK)/libsgmls-perl/.build_complete
endif

libsgmls-perl-package: libsgmls-perl-stage
	# libsgmls-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libsgmls-perl $(BUILD_DIST)/sgmlspl
	mkdir -p $(BUILD_DIST)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/sgmlspl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libsgmls-perl.mk Prep libsgmls-perl
	cp -a $(BUILD_STAGE)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libsgmls-perl.mk Prep sgmlspl
	cp -a $(BUILD_STAGE)/libsgmls-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/sgmlspl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libsgmls-perl.mk Make .debs
	$(call PACK,libsgmls-perl,DEB_LIBSGMLS-PERL_V)
	$(call PACK,sgmlspl,DEB_LIBSGMLS-PERL_V)
	
	# libsgmls-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsgmls-perl $(BUILD_DIST)/sgmlspl

.PHONY: libsgmls-perl libsgmls-perl-package
