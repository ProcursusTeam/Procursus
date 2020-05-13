ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += python3
DOWNLOAD         += https://www.python.org/ftp/python/$(PYTHON3_VERSION)/Python-$(PYTHON3_VERSION).tar.xz{,.asc}
PYTHON3_MAJOR_V  := 3.8
PYTHON3_VERSION  := $(PYTHON3_MAJOR_V).2
DEB_PYTHON3_V    ?= $(PYTHON3_VERSION)

ifeq ($(call HAS_COMMAND,python$(PYTHON3_MAJOR_V)),1)
else ifeq ($(call HAS_COMMAND,$(shell brew --prefix)/opt/python@$(PYTHON3_MAJOR_V)/bin/python$(PYTHON3_MAJOR_V)),1)
PATH := $(shell brew --prefix)/opt/python@$(PYTHON3_MAJOR_V)/bin:$(PATH) 
else
$(error Install Python $(PYTHON3_MAJOR_V))
endif

python3-setup: setup
	$(call PGP_VERIFY,Python-$(PYTHON3_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,Python-$(PYTHON3_VERSION).tar.xz,Python-$(PYTHON3_VERSION),python3)
	$(SED) -i 's/-vxworks/-darwin/g' $(BUILD_WORK)/python3/configure.ac
	$(SED) -i 's/system=VxWorks/system=Darwin/g' $(BUILD_WORK)/python3/configure.ac
	$(SED) -i '/readelf for/d' $(BUILD_WORK)/python3/configure.ac
	$(SED) -i "s|self.compiler.library_dirs|['$(SYSROOT)/usr/lib'] + ['$(BUILD_BASE)/usr/lib']|g" $(BUILD_WORK)/python3/setup.py
	$(SED) -i "s|self.compiler.include_dirs|['$(SYSROOT)/usr/include'] + ['$(BUILD_BASE)/usr/include']|g" $(BUILD_WORK)/python3/setup.py
	$(SED) -i 's|LIBFFI_INCLUDEDIR=.*|LIBFFI_INCLUDEDIR="$(BUILD_BASE)/usr/include"|g' $(BUILD_WORK)/python3/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/python3/.build_complete),)
python3:
	@echo "Using previously built python3."
else
python3: .SHELLFLAGS=-O extglob -c
python3: python3-setup gettext libffi ncurses readline xz openssl libgdbm
	cd $(BUILD_WORK)/python3 && autoconf -f
	cd $(BUILD_WORK)/python3 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--build=$(shell $(BUILD_WORK)/python3/config.guess) \
		--prefix=/usr \
		--enable-ipv6 \
		--without-ensurepip \
		--with-system-ffi \
		--enable-shared \
		ac_cv_file__dev_ptmx=no \
		ac_cv_file__dev_ptc=no \
		ac_cv_func_sendfile=no
	+$(MAKE) -C $(BUILD_WORK)/python3
	+$(MAKE) -C $(BUILD_WORK)/python3 install \
		DESTDIR=$(BUILD_STAGE)/python3
	rm -f $(BUILD_STAGE)/python3/usr/{bin,share/man/man1}/!(*$(PYTHON3_MAJOR_V)*)
	touch $(BUILD_WORK)/python3/.build_complete
endif

python3-package: python3-stage
	# python3.mk Package Structure
	rm -rf $(BUILD_DIST)/python{$(PYTHON3_MAJOR_V),3}
	mkdir -p $(BUILD_DIST)/python{$(PYTHON3_MAJOR_V),3}
	
	# python3.mk Prep python$(PYTHON3_MAJOR_V)
	cp -a $(BUILD_STAGE)/python3/usr $(BUILD_DIST)/python$(PYTHON3_MAJOR_V)
	
	# python3.mk Sign
	$(call SIGN,python$(PYTHON3_MAJOR_V),general.xml)
	
	# python3.mk Make .debs
	$(call PACK,python$(PYTHON3_MAJOR_V),DEB_PYTHON3_V)
	$(call PACK,python3,DEB_PYTHON3_V)	

	# python3.mk Build cleanup
	rm -rf $(BUILD_DIST)/python{$(PYTHON3_MAJOR_V),3}

.PHONY: python3 python3-package
