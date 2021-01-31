ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += tar
TAR_VERSION   := 1.33
DEB_TAR_V     ?= $(TAR_VERSION)-1

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
TAR_CONFIGURE_ARGS += ac_cv_func_rpmatch=no
endif

tar-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/tar/tar-$(TAR_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,tar-$(TAR_VERSION).tar.xz)
	$(call EXTRACT_TAR,tar-$(TAR_VERSION).tar.xz,tar-$(TAR_VERSION),tar)

ifneq ($(wildcard $(BUILD_WORK)/tar/.build_complete),)
tar:
	@echo "Using previously built tar."
else
tar: tar-setup gettext
	cd $(BUILD_WORK)/tar && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		$(TAR_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/tar
	+$(MAKE) -C $(BUILD_WORK)/tar install \
		DESTDIR=$(BUILD_STAGE)/tar
	touch $(BUILD_WORK)/tar/.build_complete
endif

tar-package: tar-stage
	# tar.mk Package Structure
	rm -rf $(BUILD_DIST)/tar
	mkdir -p $(BUILD_DIST)/tar/bin
	
	# tar.mk Prep tar
	cp -a $(BUILD_STAGE)/tar/usr $(BUILD_DIST)/tar
	ln -s /usr/bin/tar $(BUILD_DIST)/tar/bin/tar
	
	# tar.mk Sign
	$(call SIGN,tar,general.xml)
	
	# tar.mk Make .debs
	$(call PACK,tar,DEB_TAR_V)
	
	# tar.mk Build cleanup
	rm -rf $(BUILD_DIST)/tar

.PHONY: tar tar-package
