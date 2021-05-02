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
libyaml-tiny-perl: libyaml-tiny-perl-setup
	cd $(BUILD_WORK)/libyaml-tiny-perl && /opt/procursus/bin/perl Makefile.PL \
		$(DEFAULT_PERL_MAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libyaml-tiny-perl
	+$(MAKE) -C $(BUILD_WORK)/libyaml-tiny-perl install \
		DESTDIR="$(BUILD_STAGE)/libyaml-tiny-perl"
	rm -rf $(BUILD_STAGE)/libyaml-tiny-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
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
