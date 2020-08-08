ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mpfr
MPFR_VERSION := 4.1.0
DEB_MPFR_V   ?= $(MPFR_VERSION)

mpfr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.mpfr.org/mpfr-current/mpfr-$(MPFR_VERSION).tar.gz
	$(call EXTRACT_TAR,mpfr-$(MPFR_VERSION).tar.gz,mpfr-$(MPFR_VERSION),mpfr)

ifneq ($(wildcard $(BUILD_WORK)/mpfr/.build_complete),)
mpfr:
	@echo "Using previously built mpfr."
else
mpfr:
	cd $(BUILD_WORK)/mpfr && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/mpfr
	+$(MAKE) -C $(BUILD_WORK)/mpfr install \
		DESTDIR=$(BUILD_STAGE)/mpfr
	touch $(BUILD_WORK)/mpfr/.build_complete
endif

mpfr-package: mpfr-stage
	# mpfr.mk Package Structure
	rm -rf $(BUILD_DIST)/mpfr
	mkdir -p $(BUILD_DIST)/mpfr
	
	# mpfr.mk Prep mpfr
	cp -a $(BUILD_STAGE)/mpfr/usr $(BUILD_DIST)/mpfr
	
	# mpfr.mk Sign
	$(call SIGN,mpfr,general.xml)
	
	# mpfr.mk Make .debs
	$(call PACK,mpfr,DEB_MPFR_V)
	
	# mpfr.mk Build cleanup
	rm -rf $(BUILD_DIST)/mpfr

.PHONY: mpfr mpfr-package
