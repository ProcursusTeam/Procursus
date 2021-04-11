ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += libapt-pkg-perl
LIBAPT-PKG-PERL_VERSION := 0.1.40
DEB_LIBAPT-PKG-PERL_V   ?= $(LIBAPT-PKG-PERL_VERSION)

libapt-pkg-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libapt-pkg-perl-$(LIBAPT-PKG-PERL_VERSION).tar.xz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libapt-pkg-perl-$(LIBAPT-PKG-PERL_VERSION).tar.xz \
			https://deb.debian.org/debian/pool/main/liba/libapt-pkg-perl/libapt-pkg-perl_$(LIBAPT-PKG-PERL_VERSION).tar.xz
	$(call EXTRACT_TAR,libapt-pkg-perl-$(LIBAPT-PKG-PERL_VERSION).tar.xz,libapt-pkg-perl-$(LIBAPT-PKG-PERL_VERSION),libapt-pkg-perl)

ifneq ($(wildcard $(BUILD_WORK)/libapt-pkg-perl/.build_complete),)
libapt-pkg-perl:
	@echo "Using previously built libapt-pkg-perl."
else
libapt-pkg-perl: libapt-pkg-perl-setup perl apt
	cd $(BUILD_WORK)/libapt-pkg-perl && $(shell which perl) Makefile.PL \
		$(DEFAULT_PERL_MAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libapt-pkg-perl \
		CC="$(CXX)" \
		CCFLAGS="-std=c++11 $(CXXFLAGS) -Denviron" \
		LD="$(CXX)" \
		LDDLFLAGS="-std=c++11 -shared $(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/libapt-pkg-perl install \
		DESTDIR="$(BUILD_STAGE)/libapt-pkg-perl"
	rm -f $(BUILD_STAGE)/libapt-pkg-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/perllocal.pod
	touch $(BUILD_WORK)/libapt-pkg-perl/.build_complete
endif

libapt-pkg-perl-package: libapt-pkg-perl-stage
	# libapt-pkg-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libapt-pkg-perl

	# libapt-pkg-perl.mk Prep libapt-pkg-perl
	cp -a $(BUILD_STAGE)/libapt-pkg-perl $(BUILD_DIST)

	# libapt-pkg-perl.mk Sign
	$(call SIGN,libapt-pkg-perl,general.xml)

	# libapt-pkg-perl.mk Make .debs
	$(call PACK,libapt-pkg-perl,DEB_LIBAPT-PKG-PERL_V)

	# libapt-pkg-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libapt-pkg-perl

.PHONY: libapt-pkg-perl libapt-pkg-perl-package
