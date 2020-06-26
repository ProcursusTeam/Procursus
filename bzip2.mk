ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += bzip2
BZIP2_VERSION := 1.0.8
DEB_BZIP2_V   ?= $(BZIP2_VERSION)

bzip2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sourceware.org/pub/bzip2/bzip2-$(BZIP2_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,bzip2-$(BZIP2_VERSION).tar.gz)
	$(call EXTRACT_TAR,bzip2-$(BZIP2_VERSION).tar.gz,bzip2-$(BZIP2_VERSION),bzip2)
	mkdir -p $(BUILD_STAGE)/bzip2/bin

ifneq ($(wildcard $(BUILD_WORK)/bzip2/.build_complete),)
bzip2:
	@echo "Using previously built bzip2."
else
bzip2: bzip2-setup
	+$(MAKE) -C $(BUILD_WORK)/bzip2 install \
		PREFIX=$(BUILD_STAGE)/bzip2/usr \
		CC=$(CC) \
		AR=$(AR) \
		RANLIB=$(RANLIB) \
		CFLAGS="$(CFLAGS)"
	cd $(BUILD_STAGE)/bzip2/usr/bin; \
	rm -f bz{cmp,egrep,fgrep,less}; \
	ln -s bzdiff bzcmp; \
	ln -s bzgrep bzegrep; \
	ln -s bzgrep bzfgrep; \
	ln -s bzmore bzless
	for bin in $(BUILD_STAGE)/bzip2/usr/bin/*; do \
		ln -s ../usr/bin/$$(basename $$bin) $(BUILD_STAGE)/bzip2/bin/$$(basename $$bin); \
	done
	touch $(BUILD_WORK)/bzip2/.build_complete
endif

bzip2-package: bzip2-stage
	# bzip2.mk Package Structure
	rm -rf $(BUILD_DIST)/bzip2
	mkdir -p $(BUILD_DIST)/bzip2
	
	# bzip2.mk Prep bzip2
	cp -a $(BUILD_STAGE)/bzip2 $(BUILD_DIST)
	rm -rf $(BUILD_DIST)/bzip2/usr/man
	
	# bzip2.mk Sign
	$(call SIGN,bzip2,general.xml)
	
	# bzip2.mk Make .debs
	$(call PACK,bzip2,DEB_BZIP2_V)
	
	# bzip2.mk Build cleanup
	rm -rf $(BUILD_DIST)/bzip2

.PHONY: bzip2 bzip2-package
