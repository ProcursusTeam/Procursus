ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += make
MAKE_VERSION := 4.3
DEB_MAKE_V   ?= $(MAKE_VERSION)-2

make-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/make/make-$(MAKE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,make-$(MAKE_VERSION).tar.gz)
	$(call EXTRACT_TAR,make-$(MAKE_VERSION).tar.gz,make-$(MAKE_VERSION),make)

ifneq ($(wildcard $(BUILD_WORK)/make/.build_complete),)
make:
	@echo "Using previously built make."
else
make: make-setup gettext
	$(SED) -i '/case ENOEXEC:/a \ \ \ \ case EPERM:' $(BUILD_WORK)/make/src/job.c
	$(SED) -i 's/defined (__arm) ||//' $(BUILD_WORK)/make/src/makeint.h
	cd $(BUILD_WORK)/make && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-guile=no
	+$(MAKE) -C $(BUILD_WORK)/make \
		CFLAGS="$(CFLAGS) -DPOSIX"
	+$(MAKE) -C $(BUILD_WORK)/make install \
		DESTDIR="$(BUILD_STAGE)/make"
	touch $(BUILD_WORK)/make/.build_complete
endif

make-package: make-stage
	# make.mk Package Structure
	rm -rf $(BUILD_DIST)/make
	mkdir -p $(BUILD_DIST)/make
	
	# make.mk Prep make
	cp -a $(BUILD_STAGE)/make $(BUILD_DIST)
	
	# make.mk Sign
	$(call SIGN,make,general.xml)
	
	# make.mk Make .debs
	$(call PACK,make,DEB_MAKE_V)
	
	# make.mk Build cleanup
	rm -rf $(BUILD_DIST)/make

.PHONY: make make-package
