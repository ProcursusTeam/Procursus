ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += brotli
BROTLI_VERSION   := 1.0.7
DEB_BROTLI_V     ?= $(BROTLI_VERSION)

brotli-setup: setup
ifeq ($(wildcard $(BUILD_SOURCE)/brotli-$(BROTLI_VERSION).tar.gz),)
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/google/brotli/archive/v$(BROTLI_VERSION).tar.gz
	mv $(BUILD_SOURCE)/v$(BROTLI_VERSION).tar.gz $(BUILD_SOURCE)/brotli-$(BROTLI_VERSION).tar.gz
endif
	$(call EXTRACT_TAR,brotli-$(BROTLI_VERSION).tar.gz,brotli-$(BROTLI_VERSION),brotli)

ifneq ($(wildcard $(BUILD_WORK)/brotli/.build_complete),)
brotli:
	@echo "Using previously built brotli."
else
brotli: brotli-setup
	$(SED) -i 's/exit \$$$$/exit \$$?/' $(BUILD_WORK)/brotli/bootstrap
	printf -- '\n' >> $(BUILD_WORK)/brotli/configure.ac
	printf -- 'man_MANS = docs/brotli.1\n' >> $(BUILD_WORK)/brotli/Makefile.am

	cd $(BUILD_WORK)/brotli && ./bootstrap
	cd $(BUILD_WORK)/brotli && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--mandir=/usr/share/man
	+$(MAKE) -C $(BUILD_WORK)/brotli \
		DESTDIR=$(BUILD_STAGE)/brotli
	+$(MAKE) -C $(BUILD_WORK)/brotli install \
		DESTDIR=$(BUILD_STAGE)/brotli
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
	cp -a $(BUILD_STAGE)/brotli/usr/share/man/man1/brotli.1 $(BUILD_DIST)/brotli/usr/share/man/man1

	# brotli.mk Prep libbrotli-dev
	cp -a $(BUILD_STAGE)/brotli/usr/include/brotli/{decode,encode,port,types}.h $(BUILD_DIST)/libbrotli-dev/usr/include/brotli
	cp -a $(BUILD_STAGE)/brotli/usr/lib/libbrotli{common,dec,enc}.a $(BUILD_DIST)/libbrotli-dev/usr/lib
	cp -a $(BUILD_STAGE)/brotli/usr/lib/libbrotli{common,dec,enc}.dylib $(BUILD_DIST)/libbrotli-dev/usr/lib
	cp -a $(BUILD_STAGE)/brotli/usr/lib/pkgconfig/libbrotli{common,dec,enc}.pc $(BUILD_DIST)/libbrotli-dev/usr/lib/pkgconfig

	# brotli.mk Prep libbrotli1
	cp -a $(BUILD_STAGE)/brotli/usr/lib/libbrotli{common,dec,enc}.1.dylib $(BUILD_DIST)/libbrotli1/usr/lib

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
