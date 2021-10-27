ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += autoconf2.13
AUTOCONF2.13_VERSION  := 2.13
DEB_AUTOCONF2.13_V    ?= $(AUTOCONF2.13_VERSION)

autoconf2.13-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/autoconf/autoconf-$(AUTOCONF2.13_VERSION).tar.gz
	$(call EXTRACT_TAR,autoconf-$(AUTOCONF2.13_VERSION).tar.gz,autoconf-$(AUTOCONF2.13_VERSION),autoconf2.13)
	$(call DO_PATCH,autoconf2.13,autoconf2.13,-p1)

ifneq ($(wildcard $(BUILD_WORK)/autoconf2.13/.build_complete),)
autoconf2.13:
	@echo "Using previously built autoconf2.13."
else
autoconf2.13: autoconf2.13-setup
	cd $(BUILD_WORK)/autoconf2.13 && PERL="$(shell command -v perl)" ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--program-suffix=2.13
	+$(MAKE) -C $(BUILD_WORK)/autoconf2.13
	+sed -i -e 's|bindir = /usr/bin|bindir = $$(prefix)/bin|g' -e 's|prefix = $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|prefix = $(BUILD_STAGE)/autoconf2.13/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' $(BUILD_WORK)/autoconf2.13/Makefile
	+$(MAKE) -C $(BUILD_WORK)/autoconf2.13 install \
		DESTDIR=$(BUILD_STAGE)/autoconf2.13
	$(call AFTER_BUILD)
endif
autoconf2.13-package: autoconf2.13-stage
	# autoconf2.13.mk Package Structure
	rm -rf $(BUILD_DIST)/autoconf2.13

	# autoconf2.13.mk Prep autoconf2.13
	cp -a $(BUILD_STAGE)/autoconf2.13 $(BUILD_DIST)

	# autoconf2.13.mk Sign
	$(call SIGN,autoconf2.13,general.xml)

	# autoconf2.13.mk Make .debs
	$(call PACK,autoconf2.13,DEB_AUTOCONF2.13_V)

	# autoconf2.13.mk Build cleanup
	rm -rf $(BUILD_DIST)/autoconf2.13

.PHONY: autoconf2.13 autoconf2.13-package
