ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += brotli
BROTLI_VERSION   := 1.0.9
DEB_BROTLI_V     ?= $(BROTLI_VERSION)

brotli-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/brotli-$(BROTLI_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/brotli-$(BROTLI_VERSION).tar.gz \
			https://github.com/google/brotli/archive/v$(BROTLI_VERSION).tar.gz
	$(call EXTRACT_TAR,brotli-$(BROTLI_VERSION).tar.gz,brotli-$(BROTLI_VERSION),brotli)

ifneq ($(wildcard $(BUILD_WORK)/brotli/.build_complete),)
brotli:
	@echo "Using previously built brotli."
else
brotli: brotli-setup
	cd $(BUILD_WORK)/brotli && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) \
		-DCMAKE_AUTOGEN_PARALLEL=6
	+$(MAKE) -C $(BUILD_WORK)/brotli
	+$(MAKE) -C $(BUILD_WORK)/brotli install \
		DESTDIR="$(BUILD_STAGE)/brotli"
	+$(MAKE) -C $(BUILD_WORK)/brotli install \
		DESTDIR="$(BUILD_BASE)"
	for lib in $(BUILD_STAGE)/brotli/usr/lib/libbrotli{common,dec,enc}-static.a; do \
		if [ -f $$lib ]; then \
			mv $$lib $${lib/-static.a/.a}; \
		fi; \
	done
	touch $(BUILD_WORK)/brotli/.build_complete
endif

brotli-package: brotli-stage
	# brotli.mk Package Structure
	rm -rf $(BUILD_DIST)/{brotli,libbrotli-dev,libbrotli1}
	mkdir -p $(BUILD_DIST)/brotli/usr/{bin,share/man/man1} \
			$(BUILD_DIST)/libbrotli-dev/usr/{include/brotli,lib/pkgconfig} \
			$(BUILD_DIST)/libbrotli1/usr/lib

	# brotli.mk Prep brotli
	cp -a $(BUILD_STAGE)/brotli/usr/bin/brotli $(BUILD_DIST)/brotli/usr/bin
	cp -a $(BUILD_WORK)/brotli/docs/brotli.1 $(BUILD_DIST)/brotli/usr/share/man/man1

	# brotli.mk Prep libbrotli-dev
	cp -a $(BUILD_STAGE)/brotli/usr/include/brotli/{decode,encode,port,types}.h $(BUILD_DIST)/libbrotli-dev/usr/include/brotli
	cp -a $(BUILD_STAGE)/brotli/usr/lib/libbrotli{common,dec,enc}.{a,dylib} $(BUILD_DIST)/libbrotli-dev/usr/lib
	cp -a $(BUILD_STAGE)/brotli/usr/lib/pkgconfig/libbrotli{common,dec,enc}.pc $(BUILD_DIST)/libbrotli-dev/usr/lib/pkgconfig

	# brotli.mk Prep libbrotli1
	cp -a $(BUILD_STAGE)/brotli/usr/lib/libbrotli{common,dec,enc}.1*.dylib $(BUILD_DIST)/libbrotli1/usr/lib

	# brotli.mk Sign
	$(call SIGN,brotli,general.xml)
	$(call SIGN,libbrotli1,general.xml)

	# brotli.mk Make .debs
	$(call PACK,brotli,DEB_BROTLI_V)
	$(call PACK,libbrotli-dev,DEB_BROTLI_V)
	$(call PACK,libbrotli1,DEB_BROTLI_V)

	# brotli.mk Build cleanup
	rm -rf $(BUILD_DIST)/{brotli,libbrotli-dev,libbrotli1}

.PHONY: brotli brotli-package
