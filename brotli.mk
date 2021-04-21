ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += brotli
BROTLI_VERSION   := 1.0.9
DEB_BROTLI_V     ?= $(BROTLI_VERSION)

brotli-setup: setup
	$(call GITHUB_ARCHIVE,google,brotli,$(BROTLI_VERSION),v$(BROTLI_VERSION))
	$(call EXTRACT_TAR,brotli-$(BROTLI_VERSION).tar.gz,brotli-$(BROTLI_VERSION),brotli)

ifneq ($(wildcard $(BUILD_WORK)/brotli/.build_complete),)
brotli:
	@echo "Using previously built brotli."
else
brotli: brotli-setup
	cd $(BUILD_WORK)/brotli && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_AUTOGEN_PARALLEL=6
	+$(MAKE) -C $(BUILD_WORK)/brotli
	+$(MAKE) -C $(BUILD_WORK)/brotli install \
		DESTDIR="$(BUILD_STAGE)/brotli"
	+$(MAKE) -C $(BUILD_WORK)/brotli install \
		DESTDIR="$(BUILD_BASE)"
	for lib in $(BUILD_STAGE)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libbrotli{common,dec,enc}-static.a; do \
		if [ -f $$lib ]; then \
			mv $$lib $${lib/-static.a/.a}; \
		fi; \
	done
	touch $(BUILD_WORK)/brotli/.build_complete
endif

brotli-package: brotli-stage
	# brotli.mk Package Structure
	rm -rf $(BUILD_DIST)/{brotli,libbrotli-dev,libbrotli1}
	mkdir -p $(BUILD_DIST)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
			$(BUILD_DIST)/libbrotli-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/brotli,lib/pkgconfig} \
			$(BUILD_DIST)/libbrotli1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# brotli.mk Prep brotli
	cp -a $(BUILD_STAGE)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/brotli $(BUILD_DIST)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/brotli/docs/brotli.1 $(BUILD_DIST)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# brotli.mk Prep libbrotli-dev
	cp -a $(BUILD_STAGE)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/brotli/{decode,encode,port,types}.h $(BUILD_DIST)/libbrotli-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/brotli
	cp -a $(BUILD_STAGE)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libbrotli{common,dec,enc}.{a,dylib} $(BUILD_DIST)/libbrotli-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libbrotli{common,dec,enc}.pc $(BUILD_DIST)/libbrotli-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# brotli.mk Prep libbrotli1
	cp -a $(BUILD_STAGE)/brotli/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libbrotli{common,dec,enc}.1*.dylib $(BUILD_DIST)/libbrotli1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

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
