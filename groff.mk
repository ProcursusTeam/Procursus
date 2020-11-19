ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += groff
GROFF_VERSION  := 1.22.4
DEB_GROFF_V    ?= $(GROFF_VERSION)

groff-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/groff/groff-$(GROFF_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,groff-$(GROFF_VERSION).tar.gz)
	$(call EXTRACT_TAR,groff-$(GROFF_VERSION).tar.gz,groff-$(GROFF_VERSION),groff)

ifneq ($(wildcard $(BUILD_WORK)/groff/.build_complete),)
groff:
	@echo "Using previously built groff."
else
groff: groff-setup
	cd $(BUILD_WORK)/groff && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-x=no
	+$(MAKE) -C $(BUILD_WORK)/groff \
		AR="$(AR)" \
		GROFFBIN="$$(which groff)" \
		GROFF_BIN_PATH="$$(which groff | rev | cut -f2- -d'/' | rev)"
	+$(MAKE) -C $(BUILD_WORK)/groff install \
		DESTDIR=$(BUILD_STAGE)/groff
	touch $(BUILD_WORK)/groff/.build_complete
endif

groff-package: groff-stage
	# groff.mk Package Structure
	rm -rf $(BUILD_DIST)/groff
	mkdir -p $(BUILD_DIST)/groff
	
	# groff.mk Prep groff
	cp -a $(BUILD_STAGE)/groff $(BUILD_DIST)
	
	# groff.mk Sign
	$(call SIGN,groff,general.xml)
	
	# groff.mk Make .debs
	$(call PACK,groff,DEB_GROFF_V)
	
	# groff.mk Build cleanup
	rm -rf $(BUILD_DIST)/groff

.PHONY: groff groff-package
