ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += gawk
GAWK_VERSION := 5.1.0
DEB_GAWK_V   ?= $(GAWK_VERSION)-2

gawk-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/gawk/gawk-$(GAWK_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,gawk-$(GAWK_VERSION).tar.xz)
	$(call EXTRACT_TAR,gawk-$(GAWK_VERSION).tar.xz,gawk-$(GAWK_VERSION),gawk)

ifneq ($(wildcard $(BUILD_WORK)/gawk/.build_complete),)
gawk:
	@echo "Using previously built gawk."
else
gawk: gawk-setup gettext mpfr4 libgmp10
	cd $(BUILD_WORK)/gawk && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-libsigsegv-prefix
	+$(MAKE) -C $(BUILD_WORK)/gawk install \
		DESTDIR=$(BUILD_STAGE)/gawk
	rm -f $(BUILD_STAGE)/gawk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*awk-*
	rm -f $(BUILD_STAGE)/gawk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/awk
	touch $(BUILD_WORK)/gawk/.build_complete
endif

gawk-package: gawk-stage
	# gawk.mk Package Structure
	rm -rf $(BUILD_DIST)/gawk

	# gawk.mk Prep gawk
	cp -a $(BUILD_STAGE)/gawk $(BUILD_DIST)

	# gawk.mk Sign
	$(call SIGN,gawk,general.xml)

	# gawk.mk Make .debs
	$(call PACK,gawk,DEB_GAWK_V)

	# gawk.mk Build cleanup
	rm -rf $(BUILD_DIST)/gawk

.PHONY: gawk gawk-package
