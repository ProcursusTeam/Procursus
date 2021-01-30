ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += rpmalloc
RPMALLOC_VERSION := 1.4.1
DEB_RPMALLOC_V   ?= $(RPMALLOC_VERSION)

rpmalloc-setup: setup
	wget -q -nc -P $(BUILD_WORK)/rpmalloc \
		https://raw.githubusercontent.com/mjansson/rpmalloc/1.4.1/rpmalloc/malloc.c \
		https://raw.githubusercontent.com/mjansson/rpmalloc/1.4.1/rpmalloc/rpmalloc.{c,h}

ifneq ($(wildcard $(BUILD_WORK)/rpmalloc/.build_complete),)
rpmalloc:
	@echo "Using previously built rpmalloc."
else
rpmalloc: rpmalloc-setup
	$(CC) $(CFLAGS) $(BUILD_WORK)/rpmalloc/rpmalloc.c -DENABLE_PRELOAD=1 -DENABLE_OVERRIDE=1 -o $(BUILD_WORK)/rpmalloc/rpmalloc.o -c
	$(AR) -crs $(BUILD_WORK)/rpmalloc/librpmalloc.a $(BUILD_WORK)/rpmalloc/rpmalloc.o
	$(CC) $(CFLAGS) $(BUILD_WORK)/rpmalloc/rpmalloc.o -dynamiclib -o $(BUILD_WORK)/rpmalloc/librpmalloc.0.dylib -install_name "/usr/lib/librpmalloc.0.dylib"
	$(GINSTALL) -Dm0755 $(BUILD_WORK)/rpmalloc/librpmalloc.0.dylib $(BUILD_STAGE)/rpmalloc/usr/lib/librpmalloc.0.dylib
	$(GINSTALL) -Dm0644 $(BUILD_WORK)/rpmalloc/librpmalloc.a $(BUILD_STAGE)/rpmalloc/usr/lib/librpmalloc.a
	$(GINSTALL) -Dm0644 $(BUILD_WORK)/rpmalloc/rpmalloc.h $(BUILD_STAGE)/rpmalloc/usr/include/rpmalloc.h
	$(LN) -s librpmalloc.0.dylib $(BUILD_STAGE)/rpmalloc/usr/lib/librpmalloc.dylib
	$(GINSTALL) -Dm0755 $(BUILD_WORK)/rpmalloc/librpmalloc.0.dylib $(BUILD_BASE)/usr/lib/librpmalloc.0.dylib
	$(GINSTALL) -Dm0644 $(BUILD_WORK)/rpmalloc/librpmalloc.a $(BUILD_BASE)/usr/lib/librpmalloc.a
	$(GINSTALL) -Dm0644 $(BUILD_WORK)/rpmalloc/rpmalloc.h $(BUILD_BASE)/usr/include/rpmalloc.h
	$(LN) -s librpmalloc.0.dylib $(BUILD_BASE)/usr/lib/librpmalloc.dylib
	touch $(BUILD_WORK)/rpmalloc/.build_complete
endif

rpmalloc-package: rpmalloc-stage
	# rpmalloc.mk Package Structure
	rm -rf $(BUILD_DIST)/librpmalloc{0,-dev}
	mkdir -p $(BUILD_DIST)/librpmalloc{0,-dev}/usr/lib
	
	# rpmalloc.mk Prep librpmalloc0
	cp -a $(BUILD_STAGE)/rpmalloc/usr/lib/librpmalloc.0.dylib $(BUILD_DIST)/librpmalloc0/usr/lib
	
	# rpmalloc.mk Prep librpmalloc-dev
	cp -a $(BUILD_STAGE)/rpmalloc/usr/lib/librpmalloc.{dylib,a} $(BUILD_DIST)/librpmalloc-dev/usr/lib
	cp -a $(BUILD_STAGE)/rpmalloc/usr/include $(BUILD_DIST)/librpmalloc-dev/usr
	
	# rpmalloc.mk Sign
	$(call SIGN,librpmalloc0,general.xml)
	
	# rpmalloc.mk Make .debs
	$(call PACK,librpmalloc0,DEB_RPMALLOC_V)
	$(call PACK,librpmalloc-dev,DEB_RPMALLOC_V)
	
	# rpmalloc.mk Build cleanup
	rm -rf $(BUILD_DIST)/librpmalloc{0,-dev}

.PHONY: rpmalloc rpmalloc-package
