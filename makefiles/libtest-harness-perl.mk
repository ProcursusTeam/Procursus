ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += libtest-harness-perl
LIBTEST-HARNESS-PERL_VERSION := 3.42
DEB_LIBTEST-HARNESS-PERL_V   ?= $(LIBTEST-HARNESS-PERL_VERSION)

libtest-harness-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libtest-harness-perl-$(LIBTEST-HARNESS-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libtest-harness-perl-$(LIBTEST-HARNESS-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/L/LE/LEONT/Test-Harness-$(LIBTEST-HARNESS-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libtest-harness-perl-$(LIBTEST-HARNESS-PERL_VERSION).tar.gz,Test-Harness-$(LIBTEST-HARNESS-PERL_VERSION),libtest-harness-perl)

ifneq ($(wildcard $(BUILD_WORK)/libtest-harness-perl/.build_complete),)
libtest-harness-perl:
	@echo "Using previously built libtest-harness-perl."
else
libtest-harness-perl: libtest-harness-perl-setup perl
	cd $(BUILD_WORK)/libtest-harness-perl && /opt/procursus/bin/perl Makefile.PL \
		$(DEFAULT_PERL_MAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libtest-harness-perl
	+$(MAKE) -C $(BUILD_WORK)/libtest-harness-perl install \
		DESTDIR="$(BUILD_STAGE)/libtest-harness-perl"
	rm -rf $(BUILD_STAGE)/libtest-harness-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/libtest-harness-perl/.build_complete
endif

libtest-harness-perl-package: libtest-harness-perl-stage
	# libtest-harness-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libtest-harness-perl

	# libtest-harness-perl.mk Prep libtest-harness-perl
	cp -a $(BUILD_STAGE)/libtest-harness-perl $(BUILD_DIST)

	# libtest-harness-perl.mk Make .debs
	$(call PACK,libtest-harness-perl,DEB_LIBTEST-HARNESS-PERL_V)

	# libtest-harness-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtest-harness-perl

.PHONY: libtest-harness-perl libtest-harness-perl-package
