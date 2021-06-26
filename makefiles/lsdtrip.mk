ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lsdtrip
LSDTRIP_VERSION   := 1.0.2
DEB_LSDTRIP_V     ?= $(LSDTRIP_VERSION)

lsdtrip-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/lsdtrip-$(LSDTRIP_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/lsdtrip-$(LSDTRIP_VERSION).tar.gz \
			http://newosxbook.com/tools/lsdtrip.tgz
	mkdir -p $(BUILD_WORK)/lsdtrip
	tar xf $(BUILD_SOURCE)/lsdtrip-$(LSDTRIP_VERSION).tar.gz -C $(BUILD_WORK)/lsdtrip

ifneq ($(wildcard $(BUILD_WORK)/lsdtrip/.build_complete),)
lsdtrip:
	@echo "Using previously built lsdtrip."
else
lsdtrip: lsdtrip-setup
	$(CC) $(CFLAGS) $(LDFLAGS) -DARM $(BUILD_WORK)/lsdtrip/ls.m \
		-o $(BUILD_WORK)/lsdtrip/lsdtrip \
		-lobjc -framework Foundation -framework MobileCoreServices
	$(STRIP) $(BUILD_WORK)/lsdtrip/lsdtrip
	$(INSTALL) -Dm755 $(BUILD_WORK)/lsdtrip/lsdtrip $(BUILD_STAGE)/lsdtrip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsdtrip
	touch $(BUILD_WORK)/lsdtrip/.build_complete
endif

lsdtrip-package: lsdtrip-stage
	# lsdtrip.mk Package Structure
	rm -rf $(BUILD_DIST)/lsdtrip

	# lsdtrip.mk Prep lsdtrip
	cp -a $(BUILD_STAGE)/lsdtrip $(BUILD_DIST)/lsdtrip

	# lsdtrip.mk Sign
	$(call SIGN,lsdtrip,general.xml)
	$(LDID) -M$(BUILD_WORK)/lsdtrip/ls.ent $(BUILD_DIST)/lsdtrip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/lsdtrip

	# lsdtrip.mk Make .debs
	$(call PACK,lsdtrip,DEB_LSDTRIP_V)

	# lsdtrip.mk Build cleanup
	rm -rf $(BUILD_DIST)/lsdtrip

.PHONY: lsdtrip lsdtrip-package
