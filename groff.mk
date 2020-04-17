ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += groff
DOWNLOAD       += https://ftp.gnu.org/gnu/groff/groff-$(GROFF_VERSION).tar.gz{,.sig}
GROFF_VERSION  := 1.22.4
DEB_GROFF_V    ?= $(GROFF_VERSION)

groff-setup: setup
	$(call PGP_VERIFY,groff-$(GROFF_VERSION).tar.gz)
	$(call EXTRACT_TAR,groff-$(GROFF_VERSION).tar.gz,groff-$(GROFF_VERSION),groff)

ifneq ($(wildcard $(BUILD_WORK)/groff/.build_complete),)
groff:
	@echo "Using previously built groff."
else
groff: groff-setup
	cd $(BUILD_WORK)/groff && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-x=no
	+$(MAKE) -C $(BUILD_WORK)/groff \
		AR="$(AR)" \
		GROFFBIN="/usr/bin/groff" \
		GROFF_BIN_PATH="/usr/bin"
	+$(MAKE) -C $(BUILD_WORK)/groff install \
		DESTDIR=$(BUILD_STAGE)/groff
	touch $(BUILD_WORK)/groff/.build_complete
endif

groff-package: groff-stage
	# groff.mk Package Structure
	rm -rf $(BUILD_DIST)/groff
	mkdir -p $(BUILD_DIST)/groff
	
	# groff.mk Prep groff
	$(FAKEROOT) cp -a $(BUILD_STAGE)/groff/usr $(BUILD_DIST)/groff
	
	# groff.mk Sign
	$(call SIGN,groff,general.xml)
	
	# groff.mk Make .debs
	$(call PACK,groff,DEB_GROFF_V)
	
	# groff.mk Build cleanup
	rm -rf $(BUILD_DIST)/groff

.PHONY: groff groff-package
