ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += @pkg@
@PKG@_VERSION := @PKG_VERSION@
DEB_@PKG@_V   ?= $(@PKG@_VERSION)

@pkg@-setup: setup
@download@
	$(call EXTRACT_TAR,@pkg@-$(@PKG@_VERSION).tar.@compression@,@pkg@-$(@PKG@_VERSION),@pkg@)
	$(call DO_PATCH,@pkg@,@pkg@,-p1)

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup perl
	cd $(BUILD_WORK)/@pkg@ && /opt/procursus/bin/perl Makefile.PL \
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
	+$(MAKE) -C $(BUILD_WORK)/@pkg@
	+$(MAKE) -C $(BUILD_WORK)/@pkg@ install \
		DESTDIR="$(BUILD_STAGE)/@pkg@"
	touch $(BUILD_WORK)/@pkg@/.build_complete
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@
	
	# @pkg@.mk Prep @pkg@
	cp -a $(BUILD_STAGE)/@pkg@ $(BUILD_DIST)
	
	# @pkg@.mk Make .debs
	$(call PACK,@pkg@,DEB_@PKG@_V)
	
	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@

.PHONY: @pkg@ @pkg@-package
