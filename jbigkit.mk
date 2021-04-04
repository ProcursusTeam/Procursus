ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    	+= jbigkit
JBIGKIT_VERSION := 2.1
DEB_JBIGKIT_V   ?= $(JBIGKIT_VERSION)

jbigkit-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.cl.cam.ac.uk/~mgk25/jbigkit/download/jbigkit-$(JBIGKIT_VERSION).tar.gz
	$(call EXTRACT_TAR,jbigkit-$(JBIGKIT_VERSION).tar.gz,jbigkit-$(JBIGKIT_VERSION),jbigkit)
	$(call DO_PATCH,jbigkit,jbigkit,-p1)

ifneq ($(wildcard $(BUILD_WORK)/jbigkit/.build_complete),)
jbigkit:
	@echo "Using previously built jbigkit."
else
jbigkit: jbigkit-setup
	+$(MAKE) -C $(BUILD_WORK)/jbigkit CC="$(CC)" CFLAGS="$(CFLAGS) -I../libjbig" PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/libjbig.0.dylib $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig.0.dylib
	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/libjbig.dylib $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig.dylib

	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/jbig.h $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/jbig.h
	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/jbig_ar.h $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/jbig_ar.h
	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/jbig85.h $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/jbig85.h

	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/libjbig.0.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig.0.dylib
	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/libjbig.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig.dylib

	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/jbig.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/jbig.h
	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/jbig_ar.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/jbig_ar.h
	$(GINSTALL) -D -m644 $(BUILD_WORK)/jbigkit/libjbig/jbig85.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/jbig85.h

	$(GINSTALL) -D -m755 $(BUILD_WORK)/jbigkit/pbmtools/jbgtopbm $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jbgtopbm
	$(GINSTALL) -D -m755 $(BUILD_WORK)/jbigkit/pbmtools/pbmtojbg $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbmtojbg
	$(GINSTALL) -D -m755 $(BUILD_WORK)/jbigkit/pbmtools/jbgtopbm85 $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jbgtopbm85
	$(GINSTALL) -D -m755 $(BUILD_WORK)/jbigkit/pbmtools/pbmtojbg85 $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pbmtojbg85

	$(GINSTALL) -d -m755 $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(GINSTALL) -m644 "$(BUILD_WORK)/jbigkit/pbmtools/pbmtojbg.1" $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(GINSTALL) -m644 "$(BUILD_WORK)/jbigkit/pbmtools/jbgtopbm.1" $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	touch $(BUILD_WORK)/jbigkit/.build_complete
endif

jbigkit-package: jbigkit-stage
	# jbigkit.mk Package Structure
	rm -rf $(BUILD_DIST)/{libjbig0,libjbig-dev,jbigkit-bin}
	mkdir -p \
			$(BUILD_DIST)/libjbig0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
			$(BUILD_DIST)/libjbig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
			$(BUILD_DIST)/jbigkit-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# jbigkit.mk Prep libjbig0
	cp -a $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig.0.dylib $(BUILD_DIST)/libjbig0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# jbigkit.mk Prep libjbig-dev
	cp -a $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libjbig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjbig.dylib $(BUILD_DIST)/libjbig-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# jbigkit.mk Prep jbigkit-bin
	cp -a $(BUILD_STAGE)/jbigkit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/jbigkit-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# jbigkit.mk Sign
	$(call SIGN,libjbig0,general.xml)
	$(call SIGN,jbigkit-bin,general.xml)

	# jbigkit.mk Make .debs
	$(call PACK,libjbig0,DEB_JBIGKIT_V)
	$(call PACK,libjbig-dev,DEB_JBIGKIT_V)
	$(call PACK,jbigkit-bin,DEB_JBIGKIT_V)

	# jbigkit.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libjbig0,libjbig-dev,jbigkit-bin}

.PHONY: jbigkit jbigkit-package
