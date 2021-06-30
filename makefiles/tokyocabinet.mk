ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += tokyocabinet
TOKYOCABINET_VERSION := 1.4.48
DEB_TOKYOCABINET_V   ?= $(TOKYOCABINET_VERSION)

tokyocabinet-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dbmx.net//tokyocabinet/tokyocabinet-$(TOKYOCABINET_VERSION).tar.gz
	$(call EXTRACT_TAR,tokyocabinet-$(TOKYOCABINET_VERSION).tar.gz,tokyocabinet-$(TOKYOCABINET_VERSION),tokyocabinet)
	$(call DO_PATCH,tokyocabinet,tokyocabinet,-p1)

ifneq ($(wildcard $(BUILD_WORK)/tokyocabinet/.build_complete),)
tokyocabinet:
	@echo "Using previously built tokyocabinet."
else
tokyocabinet: tokyocabinet-setup gettext
	cd $(BUILD_WORK)/tokyocabinet && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--enable-devel \
		--enable-off64 \
		--enable-swab \
		--enable-uyield
	+$(MAKE) -C $(BUILD_WORK)/tokyocabinet
	+$(MAKE) -C $(BUILD_WORK)/tokyocabinet install \
		DESTDIR=$(BUILD_STAGE)/tokyocabinet
	+$(MAKE) -C $(BUILD_WORK)/tokyocabinet install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/tokyocabinet/.build_complete
endif

tokyocabinet-package: tokyocabinet-stage
	# tokyocabinet.mk Package Structure
	rm -rf $(BUILD_DIST)/libtokyocabinet{9,-dev} $(BUILD_DIST)/tokyocabinet-{bin,doc}
	mkdir -p $(BUILD_DIST)/libtokyocabinet{9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib,-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib} \
		$(BUILD_DIST)/tokyocabinet-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/ \
		$(BUILD_DIST)/tokyocabinet-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	
	# tokyocabinet.mk Prep tokyocabinet-bin
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tokyocabinet-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/tokyocabinet-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec $(BUILD_DIST)/tokyocabinet-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# tokyocabinet.mk Prep tokyocabinet-doc
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tokyocabinet $(BUILD_DIST)/tokyocabinet-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/
	
	# tokyocabinet.mk Prep libtokyocabinet9
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtokyocabinet.*.dylib $(BUILD_DIST)/libtokyocabinet9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# tokyocabinet.mk Prep libtokyocabinet-dev
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtokyocabinet-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/tokyocabinet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,lib{tokyocabinet.a,tokyocabinet.dylib}} $(BUILD_DIST)/libtokyocabinet-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# tokyocabinet.mk Sign
	$(call SIGN,tokyocabinet-bin,general.xml)
	$(call SIGN,libtokyocabinet9,general.xml)
	
	# tokyocabinet.mk Make .debs
	$(call PACK,tokyocabinet-bin,DEB_TOKYOCABINET_V)
	$(call PACK,tokyocabinet-doc,DEB_TOKYOCABINET_V)
	$(call PACK,libtokyocabinet9,DEB_TOKYOCABINET_V)
	$(call PACK,libtokyocabinet-dev,DEB_TOKYOCABINET_V)
	
	# tokyocabinet.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtokyocabinet{9,-dev} $(BUILD_DIST)/tokyocabinet-{bin,doc}

.PHONY: tokyocabinet tokyocabinet-package
