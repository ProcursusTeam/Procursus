ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += unrar
UNRAR_VERSION := 6.0.4
DEB_UNRAR_V   ?= $(UNRAR_VERSION)-1

unrar-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.rarlab.com/rar/unrarsrc-$(UNRAR_VERSION).tar.gz
	$(call EXTRACT_TAR,unrarsrc-$(UNRAR_VERSION).tar.gz,n/a,unrar)

ifneq ($(wildcard $(BUILD_WORK)/unrar/.build_complete),)
unrar:
	@echo "Using previously built unrar."
else
unrar: unrar-setup
	$(SED) -i 's/libunrar.so/libunrar.dylib/g' $(BUILD_WORK)/unrar/Makefile
	+$(MAKE) -C $(BUILD_WORK)/unrar \
		CXX="$(CXX) $(CFLAGS)" \
		STRIP=$(STRIP)
	mkdir -p $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -af $(BUILD_WORK)/unrar/unrar $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	+$(MAKE) -C $(BUILD_WORK)/unrar clean
	+$(MAKE) -C $(BUILD_WORK)/unrar lib \
		CXX="$(CXX) $(CFLAGS)" \
		AR="$(AR)" \
		STRIP=$(STRIP)
	mkdir -p $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -af $(BUILD_WORK)/unrar/libunrar.dylib $(BUILD_STAGE)/unrar/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	touch $(BUILD_WORK)/unrar/.build_complete
endif

unrar-package: unrar-stage
	# unrar.mk Package Structure
	rm -rf $(BUILD_DIST)/unrar
	
	# unrar.mk Prep unrar
	cp -a $(BUILD_STAGE)/unrar $(BUILD_DIST)
	
	# unrar.mk Sign
	$(call SIGN,unrar,general.xml)
	
	# unrar.mk Make .debs
	$(call PACK,unrar,DEB_UNRAR_V)
	
	# unrar.mk Build cleanup
	rm -rf $(BUILD_DIST)/unrar

.PHONY: unrar unrar-package
