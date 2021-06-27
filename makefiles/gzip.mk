ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += gzip
GZIP_VERSION  := 1.10
DEB_GZIP_V    ?= $(GZIP_VERSION)-2

gzip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/gzip/gzip-$(GZIP_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,gzip-$(GZIP_VERSION).tar.xz)
	$(call EXTRACT_TAR,gzip-$(GZIP_VERSION).tar.xz,gzip-$(GZIP_VERSION),gzip)
	mkdir -p $(BUILD_STAGE)/gzip/$(MEMO_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/gzip/.build_complete),)
gzip:
	@echo "Using previously built gzip."
else
gzip: gzip-setup
	cd $(BUILD_WORK)/gzip && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/gzip install \
		DESTDIR=$(BUILD_STAGE)/gzip
ifneq ($(MEMO_SUB_PREFIX),)
	for bin in $(BUILD_STAGE)/gzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(basename $$bin) $(BUILD_STAGE)/gzip/$(MEMO_PREFIX)/bin/$$(basename $$bin); \
	done
endif
	touch $(BUILD_WORK)/gzip/.build_complete
endif

gzip-package: gzip-stage
	# gzip.mk Package Structure
	rm -rf $(BUILD_DIST)/gzip

	# gzip.mk Prep gzip
	cp -a $(BUILD_STAGE)/gzip $(BUILD_DIST)

	# gzip.mk Sign
	$(call SIGN,gzip,general.xml)

	# gzip.mk Make .debs
	$(call PACK,gzip,DEB_GZIP_V)

	# gzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/gzip

.PHONY: gzip gzip-package
