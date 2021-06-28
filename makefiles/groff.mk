ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += groff
GROFF_VERSION  := 1.22.4
DEB_GROFF_V    ?= $(GROFF_VERSION)

###
#
# TODO: Revisit this and its dependencies at a later date.
#
###

groff-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/groff/groff-$(GROFF_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,groff-$(GROFF_VERSION).tar.gz)
	$(call EXTRACT_TAR,groff-$(GROFF_VERSION).tar.gz,groff-$(GROFF_VERSION),groff)
	$(call DO_PATCH,groff,groff,-p1) # Remove in next release.

ifneq ($(wildcard $(BUILD_WORK)/groff/.build_complete),)
groff:
	@echo "Using previously built groff."
else
groff: groff-setup
	cd $(BUILD_WORK)/groff && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x=no \
		--without-uchardet
	+$(MAKE) -C $(BUILD_WORK)/groff \
		AR="$(AR)" \
		GROFFBIN="$$(which groff)" \
		GROFF_BIN_PATH="$$(dirname $$(which groff))"
	+$(MAKE) -C $(BUILD_WORK)/groff install \
		DESTDIR=$(BUILD_STAGE)/groff
	touch $(BUILD_WORK)/groff/.build_complete
endif

groff-package: groff-stage
	# groff.mk Package Structure
	rm -rf $(BUILD_DIST)/groff

	# groff.mk Prep groff
	cp -a $(BUILD_STAGE)/groff $(BUILD_DIST)

	# groff.mk Sign
	$(call SIGN,groff,general.xml)

	# groff.mk Make .debs
	$(call PACK,groff,DEB_GROFF_V)

	# groff.mk Build cleanup
	rm -rf $(BUILD_DIST)/groff

.PHONY: groff groff-package
