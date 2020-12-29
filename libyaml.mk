ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libyaml
LIBYAML_VERSION := 0.2.5
DEB_LIBYAML_V   ?= $(LIBYAML_VERSION)

libyaml-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/libyaml-$(LIBYAML_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/libyaml-$(LIBYAML_VERSION).tar.gz \
			https://github.com/yaml/libyaml/archive/$(LIBYAML_VERSION).tar.gz
	$(call EXTRACT_TAR,libyaml-$(LIBYAML_VERSION).tar.gz,libyaml-$(LIBYAML_VERSION),libyaml)

ifneq ($(wildcard $(BUILD_WORK)/libyaml/.build_complete),)
libyaml:
	@echo "Using previously built libyaml."
else
libyaml: libyaml-setup
	cd $(BUILD_WORK)/libyaml && ./bootstrap && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libyaml
	+$(MAKE) -C $(BUILD_WORK)/libyaml install \
		DESTDIR=$(BUILD_STAGE)/libyaml
	+$(MAKE) -C $(BUILD_WORK)/libyaml install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libyaml/.build_complete
endif

libyaml-package: libyaml-stage
	# libyaml.mk Package Structure
	rm -rf $(BUILD_DIST)/libyaml*/
	mkdir -p $(BUILD_DIST)/libyaml-{0-2,dev}/usr/lib
	
	# libyaml.mk Prep libyaml-0-2
	cp -a $(BUILD_STAGE)/libyaml/usr/lib/libyaml-0.2.dylib $(BUILD_DIST)/libyaml-0-2/usr/lib
	
	# libyaml.mk Prep libyaml-dev
	cp -a $(BUILD_STAGE)/libyaml/usr/lib/{libyaml.{a,dylib},pkgconfig} $(BUILD_DIST)/libyaml-dev/usr/lib
	cp -a $(BUILD_STAGE)/libyaml/usr/include $(BUILD_DIST)/libyaml-dev/usr

	# libyaml.mk Sign
	$(call SIGN,libyaml-0-2,general.xml)
	
	# libyaml.mk Make .debs
	$(call PACK,libyaml-0-2,DEB_LIBYAML_V)
	$(call PACK,libyaml-dev,DEB_LIBYAML_V)
	
	# libyaml.mk Build cleanup
	rm -rf $(BUILD_DIST)/libyaml*/

.PHONY: libyaml libyaml-package
