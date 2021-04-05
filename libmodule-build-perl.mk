ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += libmodule-build-perl
LIBMODULE-BUILD-PERL_VERSION := 0.4231
DEB_LIBMODULE-BUILD-PERL_V   ?= $(LIBMODULE-BUILD-PERL_VERSION)

libmodule-build-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libmodule-build-perl-$(LIBMODULE-BUILD-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libmodule-build-perl-$(LIBMODULE-BUILD-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/L/LE/LEONT/Module-Build-$(LIBMODULE-BUILD-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libmodule-build-perl-$(LIBMODULE-BUILD-PERL_VERSION).tar.gz,Module-Build-$(LIBMODULE-BUILD-PERL_VERSION),libmodule-build-perl)

ifneq ($(wildcard $(BUILD_WORK)/libmodule-build-perl/.build_complete),)
libmodule-build-perl:
	@echo "Using previously built libmodule-build-perl."
else
libmodule-build-perl: libmodule-build-perl-setup perl
	cd $(BUILD_WORK)/libmodule-build-perl && /opt/procursus/bin/perl Build.PL \
		cc=$(CC) \
		ld=$(CC) \
		destdir=$(BUILD_STAGE)/libmodule-build-perl \
		install_base=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		install_path=lib=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		install_path=arch=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		install_path=bin=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		install_path=script=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		install_path=libdoc=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		install_path=bindoc=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		install_path=html=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/perl5
	$(BUILD_WORK)/libmodule-build-perl/Build install
	rm -rf $(BUILD_STAGE)/libmodule-build-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/libmodule-build-perl/.build_complete
endif

libmodule-build-perl-package: libmodule-build-perl-stage
	# libmodule-build-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libmodule-build-perl

	# libmodule-build-perl.mk Prep libmodule-build-perl
	cp -a $(BUILD_STAGE)/libmodule-build-perl $(BUILD_DIST)

	# libmodule-build-perl.mk Make .debs
	$(call PACK,libmodule-build-perl,DEB_LIBMODULE-BUILD-PERL_V)

	# libmodule-build-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmodule-build-perl

.PHONY: libmodule-build-perl libmodule-build-perl-package
