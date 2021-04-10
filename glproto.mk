ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += glproto
GLPROTO_VERSION := 1.4.17
DEB_GLPROTO_V   ?= $(GLPROTO_VERSION)

glproto-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.x.org/archive/individual/proto/glproto-$(GLPROTO_VERSION).tar.gz
	$(call EXTRACT_TAR,glproto-$(GLPROTO_VERSION).tar.gz,glproto-$(GLPROTO_VERSION),glproto)

ifneq ($(wildcard $(BUILD_WORK)/glproto/.build_complete),)
glproto:
	@echo "Using previously built glproto."
else
glproto: glproto-setup libx11 libxau libxmu xorgproto
	cd $(BUILD_WORK)/glproto && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var
	+$(MAKE) -C $(BUILD_WORK)/glproto
	+$(MAKE) -C $(BUILD_WORK)/glproto install \
		DESTDIR=$(BUILD_STAGE)/glproto
	+$(MAKE) -C $(BUILD_WORK)/glproto install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/glproto/.build_complete
endif

glproto-package: glproto-stage
# glproto.mk Package Structure
	rm -rf $(BUILD_DIST)/glproto
	
# glproto.mk Prep glproto
	cp -a $(BUILD_STAGE)/glproto $(BUILD_DIST)
	
# glproto.mk Sign
	$(call SIGN,glproto,general.xml)
	
# glproto.mk Make .debs
	$(call PACK,glproto,DEB_glproto_V)
	
# glproto.mk Build cleanup
	rm -rf $(BUILD_DIST)/glproto

.PHONY: glproto glproto-package