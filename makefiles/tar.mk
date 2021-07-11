ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += tar
TAR_VERSION   := 1.34
DEB_TAR_V     ?= $(TAR_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
TAR_CONFIGURE_ARGS += ac_cv_func_rpmatch=no
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
TAR_CONFIGURE_ARGS += --program-prefix=$(GNU_PREFIX)
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
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(TAR_CONFIGURE_ARGS)

	+$(MAKE) -C $(BUILD_WORK)/tar
	+$(MAKE) -C $(BUILD_WORK)/tar install \
		DESTDIR=$(BUILD_STAGE)/tar
	touch $(BUILD_WORK)/tar/.build_complete
endif

tar-package: tar-stage
	# tar.mk Package Structure
	rm -rf $(BUILD_DIST)/tar

	# tar.mk Prep tar
	cp -a $(BUILD_STAGE)/tar $(BUILD_DIST)
ifneq ($(MEMO_SUB_PREFIX),)
	mkdir -p $(BUILD_DIST)/tar/$(MEMO_PREFIX)/bin
	ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tar $(BUILD_DIST)/tar/$(MEMO_PREFIX)/bin/tar
endif
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/tar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/tar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin##/*} $(BUILD_DIST)/tar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $${bin##/*} | cut -c2-); \
	done
endif

	# tar.mk Sign
	$(call SIGN,tar,general.xml)

	# tar.mk Make .debs
	$(call PACK,tar,DEB_TAR_V)

	# tar.mk Build cleanup
	rm -rf $(BUILD_DIST)/tar

.PHONY: tar tar-package
