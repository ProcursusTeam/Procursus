ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += p11-kit
DOWNLOAD      += https://github.com/p11-glue/p11-kit/releases/download/$(P11_VERSION)/p11-kit-$(P11_VERSION).tar.xz{,.sig}
P11_VERSION   := 0.23.20
DEB_P11_V     ?= $(P11_VERSION)

p11-kit-setup: setup
	$(call PGP_VERIFY,p11-kit-$(P11_VERSION).tar.xz)
	$(call EXTRACT_TAR,p11-kit-$(P11_VERSION).tar.xz,p11-kit-$(P11_VERSION),p11-kit)

ifneq ($(wildcard $(BUILD_WORK)/p11-kit/.build_complete),)
p11-kit:
	@echo "Using previously built p11-kit."
else
p11-kit: p11-kit-setup gettext libtasn1
	cd $(BUILD_WORK)/p11-kit && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--without-trust-paths \
		--without-libffi \
		LIBTASN1_CFLAGS=-I$(BUILD_BASE)/usr/include
	+$(MAKE) -C $(BUILD_WORK)/p11-kit
	+$(MAKE) -C $(BUILD_WORK)/p11-kit install \
		DESTDIR=$(BUILD_STAGE)/p11-kit
	+$(MAKE) -C $(BUILD_WORK)/p11-kit install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/p11-kit/.build_complete
endif

p11-kit-package: p11-kit-stage
	# p11-kit.mk Package Structure
	rm -rf $(BUILD_DIST)/p11-kit
	mkdir -p $(BUILD_DIST)/p11-kit
	
	# p11-kit.mk Prep p11-kit
	cp -a $(BUILD_STAGE)/p11-kit/usr $(BUILD_DIST)/p11-kit
	
	# p11-kit.mk Sign
	$(call SIGN,p11-kit,general.xml)
	
	# p11-kit.mk Make .debs
	$(call PACK,p11-kit,DEB_P11_V)
	
	# p11-kit.mk Build cleanup
	rm -rf $(BUILD_DIST)/p11-kit

.PHONY: p11-kit p11-kit-package
