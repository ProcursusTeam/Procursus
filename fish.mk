ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += fish
FISH_VERSION  := 3.1.2
DEB_FISH_V    ?= $(FISH_VERSION)

fish-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/fish-shell/fish-shell/releases/download/$(FISH_VERSION)/fish-$(FISH_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,fish-$(FISH_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,fish-$(FISH_VERSION).tar.gz,fish-$(FISH_VERSION),fish)

ifneq ($(wildcard $(BUILD_WORK)/fish/.build_complete),)
fish:
	@echo "Using previously built fish"
else
fish: fish-setup ncurses gettext python3
	cd $(BUILD_WORK)/fish && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)" \
		-DCMAKE_LIBRARY_PATH="$(BUILD_BASE)/usr/lib" \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_CROSSCOMPILING=true

	+$(MAKE) -C $(BUILD_WORK)/fish
	+$(MAKE) -C $(BUILD_WORK)/fish install \
		DESTDIR=$(BUILD_STAGE)/fish

	touch $(BUILD_WORK)/fish/.build_complete
endif

fish-package: fish-stage
	rm -rf $(BUILD_DIST)/fish
	mkdir -p $(BUILD_DIST)/fish
	
	cp -a $(BUILD_STAGE)/fish/usr $(BUILD_DIST)/fish
	mv $(BUILD_DIST)/fish/usr/etc $(BUILD_DIST)/fish/etc

	$(call SIGN,fish,general.xml)
	
	$(call PACK,fish,DEB_FISH_V)
	
	rm -rf $(BUILD_DIST)/fish

.PHONY: fish fish-package
