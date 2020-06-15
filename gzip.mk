ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += gzip
DOWNLOAD      += https://ftpmirror.gnu.org/gzip/gzip-$(GZIP_VERSION).tar.xz{,.sig}
GZIP_VERSION  := 1.10
DEB_GZIP_V    ?= $(GZIP_VERSION)

gzip-setup: setup
	$(call PGP_VERIFY,gzip-$(GZIP_VERSION).tar.xz)
	$(call EXTRACT_TAR,gzip-$(GZIP_VERSION).tar.xz,gzip-$(GZIP_VERSION),gzip)
	mkdir -p $(BUILD_STAGE)/gzip/bin

ifneq ($(wildcard $(BUILD_WORK)/gzip/.build_complete),)
gzip:
	@echo "Using previously built gzip."
else
gzip: gzip-setup
	cd $(BUILD_WORK)/gzip && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/gzip install \
		DESTDIR=$(BUILD_STAGE)/gzip
	for bin in $(BUILD_STAGE)/gzip/usr/bin/*; do \
		ln -s ../usr/bin/$$(basename $$bin) $(BUILD_STAGE)/gzip/bin/$$(basename $$bin); \
	done
	touch $(BUILD_WORK)/gzip/.build_complete
endif

gzip-package: gzip-stage
	# gzip.mk Package Structure
	rm -rf $(BUILD_DIST)/gzip
	mkdir -p $(BUILD_DIST)/gzip
	
	# gzip.mk Prep gzip
	cp -a $(BUILD_STAGE)/gzip $(BUILD_DIST)
	
	# gzip.mk Sign
	$(call SIGN,gzip,general.xml)
	
	# gzip.mk Make .debs
	$(call PACK,gzip,DEB_GZIP_V)
	
	# gzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/gzip

.PHONY: gzip gzip-package
