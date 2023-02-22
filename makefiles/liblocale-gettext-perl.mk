ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                    += liblocale-gettext-perl
LIBLOCALE-GETTEXT-PERL_VERSION := 1.07
DEB_LIBLOCALE-GETTEXT-PERL_V   ?= $(LIBLOCALE-GETTEXT-PERL_VERSION)

liblocale-gettext-perl-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/liblocale-gettext-perl-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz, \
		https://cpan.metacpan.org/authors/id/P/PV/PVANDRY/gettext-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz)
	$(call EXTRACT_TAR,liblocale-gettext-perl-$(LIBLOCALE-GETTEXT-PERL_VERSION).tar.gz,Locale-gettext-$(LIBLOCALE-GETTEXT-PERL_VERSION),liblocale-gettext-perl)
	sed -i -e 's/conftest(.*))/1)/' -e '/^conftest(/d' -e "s/my \$$libs = ''/my \$$libs = '-lintl'/" $(BUILD_WORK)/liblocale-gettext-perl/Makefile.PL

ifneq ($(wildcard $(BUILD_WORK)/liblocale-gettext-perl/.build_complete),)
liblocale-gettext-perl:
	@echo "Using previously built liblocale-gettext-perl."
else
liblocale-gettext-perl: liblocale-gettext-perl-setup perl gettext
	cd $(BUILD_WORK)/liblocale-gettext-perl && /opt/procursus/bin/perl Makefile.PL \
		$(DEFAULT_PERL_MAKE_FLAGS)
	echo "#define HAVE_DGETTEXT" > $(BUILD_WORK)/liblocale-gettext-perl/config.h
	echo "#define HAVE_NGETTEXT" >> $(BUILD_WORK)/liblocale-gettext-perl/config.h
	echo "#define HAVE_NGETTEXT" >> $(BUILD_WORK)/liblocale-gettext-perl/config.h
	echo "#define HAVE_BIND_TEXTDOMAIN_CODESET" >> $(BUILD_WORK)/liblocale-gettext-perl/config.h
	+$(MAKE) -C $(BUILD_WORK)/liblocale-gettext-perl \
		$(DEFAULT_PERL_MAKE_FLAGS) \
		INST_DYNAMIC_FIX=-lintl
	+$(MAKE) -C $(BUILD_WORK)/liblocale-gettext-perl install \
		$(DEFAULT_PERL_MAKE_FLAGS) \
		DESTDIR="$(BUILD_STAGE)/liblocale-gettext-perl"
	rm -f $(BUILD_STAGE)/liblocale-gettext-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/perllocal.pod
	chmod 755 $(BUILD_STAGE)/liblocale-gettext-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/auto/Locale/gettext/gettext.so
	$(call AFTER_BUILD)
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
