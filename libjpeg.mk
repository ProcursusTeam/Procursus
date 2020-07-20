
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libjpeg
LIBJPEG_VERSION := 9d
DEB_LIBJPEG_V   ?= $(LIBJPEG_VERSION)

libjpeg-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		http://ijg.org/files/jpegsrc.v$(LIBJPEG_VERSION).tar.gz
	$(call EXTRACT_TAR,jpegsrc.v$(LIBJPEG_VERSION).tar.gz,jpeg-$(LIBJPEG_VERSION),libjpeg)

ifneq ($(wildcard $(BUILD_WORK)/libjpeg/.build_complete),)
libjpeg:
	@echo "Using previously built libjpeg."
else
libjpeg: libjpeg-setup
	cd $(BUILD_WORK)/libjpeg && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libjpeg
	+$(MAKE) -C $(BUILD_WORK)/libjpeg install \
		DESTDIR="$(BUILD_STAGE)/libjpeg"
	+$(MAKE) -C $(BUILD_WORK)/libjpeg install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libjpeg/.build_complete
endif

libjpeg-package: libjpeg-stage
  # libjpeg.mk Package Structure
	rm -rf $(BUILD_DIST)/libjpeg
	mkdir -p $(BUILD_DIST)/libjpeg

	# libjpeg.mk Prep libjpeg
	cp -a $(BUILD_STAGE)/libjpeg/usr $(BUILD_DIST)/libjpeg

  # libjpeg.mk Sign
	$(call SIGN,libjpeg,general.xml)

  # libjpeg.mk Make .debs
	$(call PACK,libjpeg,DEB_LIBJPEG_V)

  # libjpeg.mk Build cleanup
	rm -rf $(BUILD_DIST)/libjpeg

.PHONY: libjpeg libjpeg-package
