ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += liboniguruma
LIBONIGURUMA_VERSION   := 6.9.4
DEB_LIBONIGURUMA_V     ?= $(LIBONIGURUMA_VERSION)

liboniguruma-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/kkos/oniguruma/releases/download/v$(LIBONIGURUMA_VERSION)/onig-$(LIBONIGURUMA_VERSION).tar.gz
	$(call EXTRACT_TAR,onig-$(LIBONIGURUMA_VERSION).tar.gz,onig-$(LIBONIGURUMA_VERSION),liboniguruma)

ifneq ($(wildcard $(BUILD_WORK)/liboniguruma/.build_complete),)
liboniguruma:
	@echo "Using previously built liboniguruma."
else
liboniguruma: liboniguruma-setup
	cd $(BUILD_WORK)/liboniguruma && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-shared=yes \
		--enable-static=no
	+$(MAKE) -C $(BUILD_WORK)/liboniguruma install \
		DESTDIR=$(BUILD_STAGE)/liboniguruma
	touch $(BUILD_WORK)/liboniguruma/.build_complete
endif

liboniguruma-package: liboniguruma-stage
	# liboniguruma.mk Package Structure
	rm -rf $(BUILD_DIST)/liboniguruma
	mkdir -p $(BUILD_DIST)/liboniguruma

	# liboniguruma.mk Prep liboniguruma
	cp -a $(BUILD_STAGE)/liboniguruma/usr $(BUILD_DIST)/liboniguruma

	# liboniguruma.mk Make .debs
	$(call PACK,liboniguruma,DEB_LIBONIGURUMA_V)

	# liboniguruma.mk Build cleanup
	rm -rf $(BUILD_DIST)/liboniguruma

.PHONY: liboniguruma liboniguruma-package
