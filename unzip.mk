ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

UNZIP_VERSION  := 6.0
DEBIAN_UNZIP_V := $(UNZIP_VERSION)-25
DEB_UNZIP_V    ?= $(DEBIAN_UNZIP_V)

ifneq ($(wildcard $(BUILD_WORK)/unzip/.build_complete),)
unzip:
	@echo "Using previously built unzip."
else
unzip: setup
	cd $(BUILD_WORK)/unzip && $(MAKE) -f unix/Makefile unzips \
		CC=$(CC) \
		CF='$(CFLAGS) -Wall -I. -DBSD -DUNIX -DACORN_FTYPE_NFS -DWILD_STOP_AT_DIR \
    	-DLARGE_FILE_SUPPORT -DUNICODE_SUPPORT -DUNICODE_WCHAR -DUTF8_MAYBE_NATIVE \
    	-DNO_LCHMOD -DDATE_FORMAT=DF_YMD -DUSE_BZIP2 -DIZ_HAVE_UXUIDGID ' \
    	LF2= L_BZ2=-lbz2
	cd $(BUILD_WORK)/unzip && $(MAKE) -f unix/Makefile install \
		prefix=$(BUILD_STAGE)/unzip/usr 
	touch $(BUILD_WORK)/unzip/.build_complete
endif

unzip-package: unzip-stage
	# unzip.mk Package Structure
	rm -rf $(BUILD_DIST)/unzip
	mkdir -p $(BUILD_DIST)/unzip
	
	# unzip.mk Prep unzip
	$(FAKEROOT) cp -a $(BUILD_STAGE)/unzip/usr $(BUILD_DIST)/unzip
	$(FAKEROOT) rm -rf $(BUILD_DIST)/unzip/usr/man
	
	# unzip.mk Sign
	$(call SIGN,unzip,general.xml)
	
	# unzip.mk Make .debs
	$(call PACK,unzip,DEB_UNZIP_V)
	
	# unzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/unzip

.PHONY: unzip unzip-package
