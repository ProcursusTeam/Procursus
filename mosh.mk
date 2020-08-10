ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mosh
MOSH_VERSION := 1.3.2
DEB_MOSH_V   ?= $(MOSH_VERSION)

mosh-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mosh.org/mosh-$(MOSH_VERSION).tar.gz
	$(call EXTRACT_TAR,mosh-$(MOSH_VERSION).tar.gz,mosh-$(MOSH_VERSION),mosh)
	$(call DO_PATCH,mosh,mosh,-p1)

ifneq ($(wildcard $(BUILD_WORK)/mosh/.build_complete),)
mosh:
	@echo "Using previously built mosh."
else
mosh: mosh-setup libprotobuf
	cd $(BUILD_WORK)/mosh && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-ncursesw \
		--disable-dependency-tracking \
		--enable-completion
	+$(MAKE) -C $(BUILD_WORK)/mosh 
	+$(MAKE) -C $(BUILD_WORK)/mosh install \
		DESTDIR=$(BUILD_STAGE)/mosh
	touch $(BUILD_WORK)/mosh/.build_complete
endif

mosh-package: mosh-stage
	# mosh.mk Package Structure
	rm -rf $(BUILD_DIST)/mosh
	mkdir -p $(BUILD_DIST)/mosh
	
	# mosh.mk Prep mosh
	cp -a $(BUILD_STAGE)/mosh/usr $(BUILD_DIST)/mosh
	
	# mosh.mk Sign
	$(call SIGN,mosh,general.xml)
	
	# mosh.mk Make .debs
	$(call PACK,mosh,DEB_MOSH_V)
	
	# mosh.mk Build cleanup
	rm -rf $(BUILD_DIST)/mosh

.PHONY: mosh mosh-package
