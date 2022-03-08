ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += swig
SWIG_VERSION := 4.0.2
DEB_SWIG_V   ?= $(SWIG_VERSION)-2

swig-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://downloads.sourceforge.net/project/swig/swig/swig-$(SWIG_VERSION)/swig-$(SWIG_VERSION).tar.gz
	$(call EXTRACT_TAR,swig-$(SWIG_VERSION).tar.gz,swig-$(SWIG_VERSION),swig)
	$(call DO_PATCH,swig,swig,-p1)

ifneq ($(wildcard $(BUILD_WORK)/swig/.build_complete),)
swig:
	@echo "Using previously built swig."
else
swig: swig-setup pcre2
	cd $(BUILD_WORK)/swig && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--mandir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		--with-swiglibdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/swig4.0 \
		--program-suffix=4.0
	+$(MAKE) -C $(BUILD_WORK)/swig
	+$(MAKE) -C $(BUILD_WORK)/swig install \
		DESTDIR=$(BUILD_STAGE)/swig
	$(LN_S) swig4.0 $(BUILD_STAGE)/swig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/swig
	$(LN_S) ccache-swig4.0 $(BUILD_STAGE)/swig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ccache-swig
	$(call AFTER_BUILD)
endif

swig-package: swig-stage
	# swig.mk Package Structure
	rm -rf $(BUILD_DIST)/swig
	mkdir -p $(BUILD_DIST)/swig{4.0}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share}

	# swig.mk Prep swig
	cp -a $(BUILD_STAGE)/swig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{swig,ccache-swig} $(BUILD_DIST)/swig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# swig.mk Prep swig4.0
	cp -a $(BUILD_STAGE)/swig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{swig,ccache-swig}4.0 $(BUILD_DIST)/swig4.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/swig/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/swig4.0 $(BUILD_DIST)/swig4.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# swig.mk Sign
	$(call SIGN,swig4.0,general.xml)

	# swig.mk Make .debs
	$(call PACK,swig,DEB_SWIG_V)
	$(call PACK,swig4.0,DEB_SWIG_V)

	# swig.mk Build cleanup
	rm -rf $(BUILD_DIST)/swig

.PHONY: swig swig-package
