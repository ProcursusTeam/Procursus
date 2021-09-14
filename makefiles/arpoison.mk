ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += arpoison
ARPOISON_VERSION := 0.7
DEB_ARPOISON_V   ?= $(ARPOISON_VERSION)

arpoison-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://www.arpoison.net/arpoison-$(ARPOISON_VERSION).tar.gz
	$(call EXTRACT_TAR,arpoison-$(ARPOISON_VERSION).tar.gz,arpoison-$(ARPOISON_VERSION),arpoison)
	mkdir -p $(BUILD_STAGE)/arpoison/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/

ifneq ($(wildcard $(BUILD_WORK)/arpoison/.build_complete),)
arpoison:
	@echo "Using previously built arpoison."
else
arpoison: arpoison-setup libnet
	# arpoison.o
	$(CC) $(CFLAGS) \
		-c -o $(BUILD_WORK)/arpoison/arpoison.o -x c \
		$(BUILD_WORK)/arpoison/arpoison.c\
	
	# arpoison
	$(CC) $(CFLAGS) $(LDFLAGS)\
		-o $(BUILD_WORK)/arpoison/arpoison \
		$(BUILD_WORK)/arpoison/arpoison.o \
		-l net

	# remove linking dir
	rm -rf $(BUILD_WORK)/linking

	+mkdir -p $(BUILD_STAGE)/arpoison/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/arpoison/arpoison $(BUILD_STAGE)/arpoison/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(call AFTER_BUILD)
endif

arpoison-package: arpoison-stage
	# arpoison.mk Package Structure
	rm -rf $(BUILD_DIST)/arpoison
	
	# arpoison.mk Prep arpoison
	cp -a $(BUILD_STAGE)/arpoison $(BUILD_DIST)
	
	# arpoison.mk Sign
	$(call SIGN,arpoison,general.xml)
	
	# arpoison.mk Make .debs
	$(call PACK,arpoison,DEB_ARPOISON_V)
	
	# arpoison.mk Build cleanup
	rm -rf $(BUILD_DIST)/arpoison

.PHONY: arpoison arpoison-package
