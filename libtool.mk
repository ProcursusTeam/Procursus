ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libtool
LIBTOOL_VERSION := 2.4.6
DEB_LIBTOOL_V   ?= $(LIBTOOL_VERSION)-1

libtool-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/libtool/libtool-$(LIBTOOL_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libtool-$(LIBTOOL_VERSION).tar.gz)
	$(call EXTRACT_TAR,libtool-$(LIBTOOL_VERSION).tar.gz,libtool-$(LIBTOOL_VERSION),libtool)

ifneq ($(wildcard $(BUILD_WORK)/libtool/.build_complete),)
libtool:
	@echo "Using previously built libtool."
else
libtool: libtool-setup
	cd $(BUILD_WORK)/libtool && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--program-prefix=g \
		--enable-ltdl-install
	+$(MAKE) -C $(BUILD_WORK)/libtool
	+$(MAKE) -C $(BUILD_WORK)/libtool install \
		DESTDIR=$(BUILD_STAGE)/libtool
	+$(MAKE) -C $(BUILD_WORK)/libtool install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libtool/.build_complete
endif
libtool-package: libtool-stage
	# libtool.mk Package Structure
	rm -rf $(BUILD_DIST)/libtool
	mkdir -p $(BUILD_DIST)/libtool
	
	# libtool.mk Prep libtool
	cp -a $(BUILD_STAGE)/libtool $(BUILD_DIST)
	
	# libtool.mk Sign
	$(call SIGN,libtool,general.xml)
	
	# libtool.mk Make .debs
	$(call PACK,libtool,DEB_LIBTOOL_V)
	
	# libtool.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtool

.PHONY: libtool libtool-package
