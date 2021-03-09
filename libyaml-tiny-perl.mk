ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS               += libyaml-tiny-perl
LIBYAML-TINY-PERL_VERSION := 1.73
DEB_LIBYAML-TINY-PERL_V   ?= $(LIBYAML-TINY-PERL_VERSION)

libyaml-tiny-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libyaml-tiny-perl-$(LIBYAML-TINY-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libyaml-tiny-perl-$(LIBYAML-TINY-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/E/ET/ETHER/YAML-Tiny-$(LIBYAML-TINY-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libyaml-tiny-perl-$(LIBYAML-TINY-PERL_VERSION).tar.gz,YAML-Tiny-$(LIBYAML-TINY-PERL_VERSION),libyaml-tiny-perl)

ifneq ($(wildcard $(BUILD_WORK)/libyaml-tiny-perl/.build_complete),)
libyaml-tiny-perl:
	@echo "Using previously built libyaml-tiny-perl."
else
libyaml-tiny-perl: libyaml-tiny-perl-setup perl
	cd $(BUILD_WORK)/libyaml-tiny-perl && /opt/procursus/bin/perl Makefile.PL \
		INSTALLSITEARCH=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLARCHLIB=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLVENDORARCH=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLPRIVLIB=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/perl5 \
		INSTALLSITELIB=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/perl5 \
		INSTALLVENDORLIB=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/perl5 \
		PERL_LIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_ARCHLIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_ARCHLIBDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_INC=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
		PERL_INCDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
		PREFIX=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		INSTALLMAN1DIR=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLSITEMAN1DIR=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLVENDORMAN1DIR=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLMAN3DIR=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man3 \
		INSTALLSITEMAN3DIR=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man3 \
		INSTALLVENDORMAN3DIR=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man3 \
		PERL="/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/perl" \
		CCFLAGS="$(CFLAGS)" \
		LDDLFLAGS="$(LDFLAGS) -shared"
	+$(MAKE) -C $(BUILD_WORK)/libyaml-tiny-perl
	+$(MAKE) -C $(BUILD_WORK)/libyaml-tiny-perl install \
		DESTDIR="$(BUILD_STAGE)/libyaml-tiny-perl"
	rm -rf $(BUILD_STAGE)/libyaml-tiny-perl/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/libyaml-tiny-perl/.build_complete
endif

libyaml-tiny-perl-package: libyaml-tiny-perl-stage
	# libyaml-tiny-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libyaml-tiny-perl
	
	# libyaml-tiny-perl.mk Prep libyaml-tiny-perl
	cp -a $(BUILD_STAGE)/libyaml-tiny-perl $(BUILD_DIST)
	
	# libyaml-tiny-perl.mk Make .debs
	$(call PACK,libyaml-tiny-perl,DEB_LIBYAML-TINY-PERL_V)
	
	# libyaml-tiny-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libyaml-tiny-perl

.PHONY: libyaml-tiny-perl libyaml-tiny-perl-package
