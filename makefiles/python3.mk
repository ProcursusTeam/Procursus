ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += python3
PYTHON3_MAJOR_V  := 3.9
PYTHON3_VERSION  := $(PYTHON3_MAJOR_V).5
DEB_PYTHON3_V    ?= $(PYTHON3_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
PYTHON3_CONFIGURE_ARGS := LIBS="-L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -liosexec"
else
PYTHON3_CONFIGURE_ARGS :=
endif

python3-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.python.org/ftp/python/$(PYTHON3_VERSION)/Python-$(PYTHON3_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,Python-$(PYTHON3_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,Python-$(PYTHON3_VERSION).tar.xz,Python-$(PYTHON3_VERSION),python3)
	$(call DO_PATCH,python3,python3,-p1)
	$(SED) -i -e 's/-vxworks/-darwin/g' -e 's/system=VxWorks/system=Darwin/g' -e '/readelf for/d' -e 's|LIBFFI_INCLUDEDIR=.*|LIBFFI_INCLUDEDIR="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include"|g' $(BUILD_WORK)/python3/configure.ac
	$(SED) -i -e "s|self.compiler.library_dirs|['$(TARGET_SYSROOT)/usr/lib'] + ['$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib']|g" -e "s|self.compiler.include_dirs|['$(TARGET_SYSROOT)/usr/include'] + ['$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include']|g" -e "s/HOST_PLATFORM == 'darwin'/HOST_PLATFORM.startswith('darwin')/" $(BUILD_WORK)/python3/setup.py
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(SED) -i '1s/^/#include <libiosexec.h>\n/' $(BUILD_WORK)/python3/Modules/_posixsubprocess.c
endif

ifneq ($(wildcard $(BUILD_WORK)/python3/.build_complete),)
python3:
	@echo "Using previously built python3."
else
python3: .SHELLFLAGS=-O extglob -c
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
python3: python3-setup gettext libffi ncurses readline xz openssl libgdbm expat
else
python3: python3-setup gettext libffi ncurses readline xz openssl libgdbm expat libxcrypt libiosexec
endif
	cd $(BUILD_WORK)/python3 && autoreconf -fi
	cd $(BUILD_WORK)/python3 && ./configure -C \
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
		$(PYTHON3_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/python3
	+$(MAKE) -C $(BUILD_WORK)/python3 install \
		DESTDIR=$(BUILD_STAGE)/python3
	+$(MAKE) -C $(BUILD_WORK)/python3 install \
		DESTDIR=$(BUILD_BASE)
	mkdir -p $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/dist-packages
	$(SED) -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' < $(BUILD_MISC)/python3/_sysconfigdata__darwin_darwin.py > $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python$(PYTHON3_MAJOR_V)/_sysconfigdata__darwin_darwin.py
	rm -f $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}/!(*$(PYTHON3_MAJOR_V)*)
	touch $(BUILD_WORK)/python3/.build_complete
endif

python3-package: python3-stage
	# python3.mk Package Structure
	rm -rf $(BUILD_DIST)/python{$(PYTHON3_MAJOR_V),3} $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V){,-dev}
	mkdir -p \
		$(BUILD_DIST)/python{$(PYTHON3_MAJOR_V),3}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V){,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX){,$(MEMO_ALT_PREFIX)}/lib \
		$(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# python3.mk Prep python$(PYTHON3_MAJOR_V)
	cp -a $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/python$(PYTHON3_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# python3.mk Prep libpython$(PYTHON3_MAJOR_V)
	cp -a $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/python$(PYTHON3_MAJOR_V) $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib
	cp -a $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libpython$(PYTHON3_MAJOR_V).dylib,python3,python$(PYTHON3_MAJOR_V)} $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# python3.mk Prep libpython$(PYTHON3_MAJOR_V)-dev
	cp -a $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	rm -f $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V)-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/python3{,-embed}.pc

	# python3.mk Prep python3
	ln -s 2to3-$(PYTHON3_MAJOR_V) $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/2to3
	ln -s idle$(PYTHON3_MAJOR_V) $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/idle3
	ln -s pydoc$(PYTHON3_MAJOR_V) $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pydoc3
	ln -s python$(PYTHON3_MAJOR_V) $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3
	ln -s python$(PYTHON3_MAJOR_V) $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python
	ln -s python$(PYTHON3_MAJOR_V)-config $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3-config

	ln -s python$(PYTHON3_MAJOR_V).1.zst $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/python3.1.zst
	ln -s python$(PYTHON3_MAJOR_V).1.zst $(BUILD_DIST)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/python.1.zst

	# python3.mk Sign
	$(call SIGN,python$(PYTHON3_MAJOR_V),general.xml)
	$(call SIGN,libpython$(PYTHON3_MAJOR_V),general.xml)

	# python3.mk Make .debs
	$(call PACK,python$(PYTHON3_MAJOR_V),DEB_PYTHON3_V)
	$(call PACK,libpython$(PYTHON3_MAJOR_V),DEB_PYTHON3_V)
	$(call PACK,libpython$(PYTHON3_MAJOR_V)-dev,DEB_PYTHON3_V)
	$(call PACK,python3,DEB_PYTHON3_V)

	# python3.mk Build cleanup
	rm -rf $(BUILD_DIST)/python{$(PYTHON3_MAJOR_V),3} $(BUILD_DIST)/libpython$(PYTHON3_MAJOR_V){,-dev}

.PHONY: python3 python3-package
