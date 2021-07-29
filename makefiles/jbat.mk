ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += jbat
JBAT_VERSION := 1.0
DEB_JBAT_V   ?= $(JBAT_VERSION)

jbat-setup: setup
	mkdir -p $(BUILD_WORK)/jbat
	lynx -width 1000 -dump http://newosxbook.com/src.jl\?tree\=listings\&file\=bat.c > \
		$(BUILD_WORK)/jbat/jbat.c
	$(SED) -i '/free/d' $(BUILD_WORK)/jbat/jbat.c

ifneq ($(wildcard $(BUILD_WORK)/jbat/.build_complete),)
jbat:
	@echo "Using previously built jbat."
else
jbat: jbat-setup
	$(CC) $(CFLAGS) $(LDFLAGS) $(BUILD_WORK)/jbat/jbat.c \
		-o $(BUILD_WORK)/jbat/jbat \
		-framework IOKit -framework CoreFoundation
	$(STRIP) $(BUILD_WORK)/jbat/jbat
	$(INSTALL) -Dm755 $(BUILD_WORK)/jbat/jbat $(BUILD_STAGE)/jbat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jbat
	touch $(BUILD_WORK)/jbat/.build_complete
endif

jbat-package: jbat-stage
	# jbat.mk Package Structure
	rm -rf $(BUILD_DIST)/jbat

	# jbat.mk Prep jbat
	cp -a $(BUILD_STAGE)/jbat $(BUILD_DIST)/jbat

	# jbat.mk Sign
	$(call SIGN,jbat,general.xml)

	# jbat.mk Make .debs
	$(call PACK,jbat,DEB_JBAT_V)

	# jbat.mk Build cleanup
	rm -rf $(BUILD_DIST)/jbat

.PHONY: jbat jbat-package
