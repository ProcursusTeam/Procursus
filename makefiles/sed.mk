ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
SED_CONFIGURE_ARGS := --program-prefix=$(GNU_PREFIX)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += sed
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS   += sed
endif # ($(MEMO_TARGET),darwin-\*)
SED_VERSION   := 4.8
DEB_SED_V     ?= $(SED_VERSION)-2

sed-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/sed/sed-$(SED_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,sed-$(SED_VERSION).tar.xz)
	$(call EXTRACT_TAR,sed-$(SED_VERSION).tar.xz,sed-$(SED_VERSION),sed)

ifneq ($(wildcard $(BUILD_WORK)/sed/.build_complete),)
sed:
	@echo "Using previously built sed."
else
sed: sed-setup gettext
	cd $(BUILD_WORK)/sed && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		$(SED_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/sed
	+$(MAKE) -C $(BUILD_WORK)/sed install \
		DESTDIR=$(BUILD_STAGE)/sed
	touch $(BUILD_WORK)/sed/.build_complete
endif

sed-package: sed-stage
	# sed.mk Package Structure
	rm -rf $(BUILD_DIST)/sed
	mkdir -p $(BUILD_DIST)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# sed.mk Prep sed
	cp -a $(BUILD_STAGE)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin##/*} $(BUILD_DIST)/sed/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $${bin##/*} | cut -c2-); \
	done
endif

	# sed.mk Sign
	$(call SIGN,sed,general.xml)

	# sed.mk Make .debs
	$(call PACK,sed,DEB_SED_V)

	# sed.mk Build cleanup
	rm -rf $(BUILD_DIST)/sed

.PHONY: sed sed-package
