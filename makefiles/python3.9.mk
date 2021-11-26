ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += python3.9
PYTHON3_VERSION  := 3.9.9
DEB_PYTHON3_V    ?= $(PYTHON3_VERSION)

python3.9-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.python.org/ftp/python/$(PYTHON3_VERSION)/Python-$(PYTHON3_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,Python-$(PYTHON3_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,Python-$(PYTHON3_VERSION).tar.xz,Python-$(PYTHON3_VERSION),python3.9)
	$(call DO_PATCH,python3,python3.9,-p1)
	sed -i -e 's/-vxworks/-darwin/g' -e 's/system=VxWorks/system=Darwin/g' -e '/readelf for/d' -e 's|LIBFFI_INCLUDEDIR=.*|LIBFFI_INCLUDEDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include"|g' $(BUILD_WORK)/python3.9/configure.ac
	sed -i -e "s|self.compiler.library_dirs|['$(TARGET_SYSROOT)/usr/lib'] + ['$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib']|g" -e "s|self.compiler.include_dirs|['$(TARGET_SYSROOT)/usr/include'] + ['$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include']|g" -e "s/HOST_PLATFORM == 'darwin'/HOST_PLATFORM.startswith('darwin')/" $(BUILD_WORK)/python3.9/setup.py

ifneq ($(wildcard $(BUILD_WORK)/python3.9/.build_complete),)
python3.9:
	@echo "Using previously built python3.9."
else
python3.9: .SHELLFLAGS=-O extglob -c
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
python3.9: python3.9-setup gettext libffi ncurses readline xz openssl libgdbm expat
else
python3.9: python3.9-setup gettext libffi ncurses readline xz openssl libgdbm expat libxcrypt
endif
	cd $(BUILD_WORK)/python3.9 && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-ipv6 \
		--without-ensurepip \
		--with-system-ffi \
		--with-system-expat \
		--enable-shared \
		--with-lto \
		ac_cv_file__dev_ptmx=no \
		ac_cv_file__dev_ptc=no \
		ac_cv_func_sendfile=no \
		ax_cv_c_float_words_bigendian=no \
		ac_cv_working_tzset=yes
	+$(MAKE) -C $(BUILD_WORK)/python3.9
	+$(MAKE) -C $(BUILD_WORK)/python3.9 install \
		DESTDIR=$(BUILD_STAGE)/python3.9
	mkdir -p $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3.9/dist-packages
	sed -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/python3/_sysconfigdata__darwin_darwin.py > $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3.9/_sysconfigdata__darwin_darwin.py
	rm -f $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}/!(*3.9*)
	$(call AFTER_BUILD,copy)
endif

python3.9-package: python3.9-stage
	# python3.9.mk Package Structure
	rm -rf $(BUILD_DIST)/python3{,.9} $(BUILD_DIST)/libpython3.9{,-dev}
	mkdir -p \
		$(BUILD_DIST)/python3{,.9}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/libpython3.9{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX){,$(MEMO_ALT_PREFIX)}/lib \

	# python3.9.mk Prep python3.9
	cp -a $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# python3.9.mk Prep libpython3.9
	cp -a $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libpython3.9.dylib,python3,python3.9} $(BUILD_DIST)/libpython3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# python3.9.mk Prep libpython3.9-dev
	cp -a $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpython3.9-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/python3.9/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libpython3.9-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	rm -f $(BUILD_DIST)/libpython3.9-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/python3{,-embed}.pc

	# python3.9.mk Prep python3
	$(LN_S) 2to3-3.9 $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/2to3
	$(LN_S) idle3.9 $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/idle3
	$(LN_S) pydoc3.9 $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pydoc3
	$(LN_S) python3.9 $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3
	$(LN_S) python3.9 $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python
	$(LN_S) python3.9-config $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3-config

	$(LN_S) python3.9.1.zst $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/python3.1.zst
	$(LN_S) python3.9.1.zst $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/python.1.zst

	# python3.9.mk Sign
	$(call SIGN,python3.9,general.xml)
	$(call SIGN,libpython3.9,general.xml)

	# python3.9.mk Make .debs
	$(call PACK,python3.9,DEB_PYTHON3_V)
	$(call PACK,libpython3.9,DEB_PYTHON3_V)
	$(call PACK,libpython3.9-dev,DEB_PYTHON3_V)
	$(call PACK,python3,DEB_PYTHON3_V)

	# python3.9.mk Build cleanup
	rm -rf $(BUILD_DIST)/python3{,.9} $(BUILD_DIST)/libpython3.9{,-dev}

.PHONY: python3.9 python3.9-package
