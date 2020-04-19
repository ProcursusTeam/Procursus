ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += gzip
DOWNLOAD      += https://ftp.gnu.org/gnu/gzip/gzip-$(GZIP_VERSION).tar.xz{,.sig}
GZIP_VERSION  := 1.10
DEB_GZIP_V    ?= $(GZIP_VERSION)

gzip-setup: setup
	$(call PGP_VERIFY,gzip-$(GZIP_VERSION).tar.xz)
	$(call EXTRACT_TAR,gzip-$(GZIP_VERSION).tar.xz,gzip-$(GZIP_VERSION),gzip)

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
	touch $(BUILD_WORK)/gzip/.build_complete
endif

gzip-package: gzip-stage
	# gzip.mk Package Structure
	rm -rf $(BUILD_DIST)/gzip
	mkdir -p $(BUILD_DIST)/gzip
	
	# gzip.mk Prep gzip
	cp -a $(BUILD_STAGE)/gzip/usr $(BUILD_DIST)/gzip
	
	# gzip.mk Sign
	$(call SIGN,gzip,general.xml)
	
	# gzip.mk Make .debs
	$(call PACK,gzip,DEB_GZIP_V)
	
	# gzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/gzip

.PHONY: gzip gzip-package
