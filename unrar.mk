ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += unrar
UNRAR_VERSION := 6.0.4
DEB_UNRAR_V   ?= $(UNRAR_VERSION)-1

unrar-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.rarlab.com/rar/unrarsrc-$(UNRAR_VERSION).tar.gz
	$(call EXTRACT_TAR,unrarsrc-$(UNRAR_VERSION).tar.gz,n/a,unrar)
	$(call DO_PATCH,unrar,unrar,-p1)

ifneq ($(wildcard $(BUILD_WORK)/unrar/.build_complete),)
unrar:
	@echo "Using previously built unrar."
else
unrar: unrar-setup
	+$(MAKE) -C $(BUILD_WORK)/unrar \
		CXX="$(CXX) $(CFLAGS)" \
		STRIP=$(STRIP)
	mkdir -p $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,include,share/man/man1}
	cp -af $(BUILD_WORK)/unrar/unrar $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	+$(MAKE) -C $(BUILD_WORK)/unrar clean
	+$(MAKE) -C $(BUILD_WORK)/unrar lib \
		CXX="$(CXX) $(CFLAGS)" \
		AR="$(AR)" \
		STRIP=$(STRIP)
	cp -af $(BUILD_WORK)/unrar/libunrar*.dylib $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -af $(BUILD_WORK)/unrar/libunrar.a $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -af $(BUILD_WORK)/unrar/*.hpp $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_MISC)/unrar.1 $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	touch $(BUILD_WORK)/unrar/.build_complete
endif

unrar-package: unrar-stage
	# unrar.mk Package Structure
	rm -rf $(BUILD_DIST)/unrar $(BUILD_DIST)/libunrar{5,-dev}
	mkdir -p $(BUILD_DIST)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libunrar5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libunrar-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib}

	# unrar.mk Prep unrar
	cp -a $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# unrar.mk Prep libunrar5
	cp -a $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunrar.5*.dylib $(BUILD_DIST)/libunrar5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unrar.mk Prep libunrar-dev
	cp -a $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunrar.{a,dylib} $(BUILD_DIST)/libunrar-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libunrar-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# unrar.mk Sign
	$(call SIGN,unrar,general.xml)
	$(call SIGN,libunrar5,general.xml)

	# unrar.mk Make .debs
	$(call PACK,unrar,DEB_UNRAR_V)
	$(call PACK,libunrar5,DEB_UNRAR_V)
	$(call PACK,libunrar-dev,DEB_UNRAR_V)

	# unrar.mk Build cleanup
	rm -rf $(BUILD_DIST)/unrar $(BUILD_DIST)/libunrar{5,-dev}

.PHONY: unrar unrar-package
