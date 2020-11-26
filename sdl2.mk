ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

###
# This Makefile needs major changes before supporting Apple Silicon
###

SUBPROJECTS   += sdl2
SDL2_VERSION  := 2.0.12
DEB_SDL2_V    ?= $(SDL2_VERSION)

sdl2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://libsdl.org/release/SDL2-$(SDL2_VERSION).tar.gz
	$(call EXTRACT_TAR,SDL2-$(SDL2_VERSION).tar.gz,SDL2-$(SDL2_VERSION),sdl2)
	$(call DO_PATCH,sdl2,sdl2,-p1)
	$(SED) -i -e 's/have_metal=no/have_metal=yes/' -e '/\ CheckMETAL/a CheckHIDAPI' \
		-e '/framework,UIKit/a EXTRA_LDFLAGS="\$$EXTRA_LDFLAGS -Wl,-framework,IOKit"' $(BUILD_WORK)/sdl2/configure
	$(SED) -i 's/#elif __MACOSX__/#elif __APPLE__/' $(BUILD_WORK)/sdl2/src/hidapi/SDL_hidapi.c

ifneq ($(wildcard $(BUILD_WORK)/sdl2/.build_complete),)
sdl2:
	@echo "Using previously built sdl2."
else
sdl2: sdl2-setup
	cd $(BUILD_WORK)/sdl2 && ./configure -C \
		--host=aarch64-ios-darwin \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-hidapi \
		CFLAGS="-DNDEBUG -DIOS_DYLIB -g -O0 -pipe -fPIC -fobjc-arc $(CFLAGS)" \
		CPPFLAGS="-DNDEBUG -DIOS_DYLIB -g -O0 -pipe -fPIC -fobjc-arc $(CPPFLAGS)"
	cp $(BUILD_WORK)/sdl2/include/SDL_config_iphoneos.h $(BUILD_WORK)/sdl2/include/SDL_config.h
	+$(MAKE) -C $(BUILD_WORK)/sdl2 install \
		DESTDIR=$(BUILD_STAGE)/sdl2
	+$(MAKE) -C $(BUILD_WORK)/sdl2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/sdl2/.build_complete
endif

sdl2-package: sdl2-stage
	# sdl2.mk Package Structure
	rm -rf $(BUILD_DIST)/libsdl2-{2.0-0,dev}
	mkdir -p $(BUILD_DIST)/libsdl2-{2.0-0,dev}/usr/lib
	
	# sdl2.mk Prep libsdl2-2.0-0
	cp -a $(BUILD_STAGE)/sdl2/usr/lib/libSDL2-2.0.0.dylib $(BUILD_DIST)/libsdl2-2.0-0/usr/lib

	# sdl2.mk Prep libsdl2-dev
	cp -a $(BUILD_STAGE)/sdl2/usr/lib/!(libSDL2-2.0.0.dylib) $(BUILD_DIST)/libsdl2-dev/usr/lib
	cp -a $(BUILD_STAGE)/sdl2/usr/!(lib) $(BUILD_DIST)/libsdl2-dev/usr
	
	# sdl2.mk Sign
	$(call SIGN,libsdl2-2.0-0,general.xml)
	
	# sdl2.mk Make .debs
	$(call PACK,libsdl2-2.0-0,DEB_SDL2_V)
	$(call PACK,libsdl2-dev,DEB_SDL2_V)
	
	# sdl2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libsdl2-{2.0-0,dev}

.PHONY: sdl2 sdl2-package
