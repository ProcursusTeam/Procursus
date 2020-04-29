ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += uuid
DOWNLOAD      += http://deb.debian.org/debian/pool/main/o/ossp-uuid/ossp-uuid_$(UUID_VERSION).orig.tar.gz
UUID_VERSION  := 1.6.2
DEB_UUID_V    ?= $(UUID_VERSION)

uuid-setup: setup file-setup
	$(call EXTRACT_TAR,ossp-uuid_$(UUID_VERSION).orig.tar.gz,uuid-$(UUID_VERSION),uuid)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/uuid
	$(SED) -i 's/-c -s -m/-c -m/g' $(BUILD_WORK)/uuid/Makefile.in

ifneq ($(wildcard $(BUILD_WORK)/uuid/.build_complete),)
uuid:
	@echo "Using previously built uuid."
else
uuid: uuid-setup
	cd $(BUILD_WORK)/uuid && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		ac_cv_va_copy=yes \
		CC="$(CC) $(CFLAGS)" \
		CXX="$(CXX) $(CXXFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/uuid
	+$(MAKE) -C $(BUILD_WORK)/uuid install \
		DESTDIR=$(BUILD_STAGE)/uuid
	touch $(BUILD_WORK)/uuid/.build_complete
endif

uuid-package: uuid-stage
	# uuid.mk Package Structure
	rm -rf $(BUILD_DIST)/uuid
	mkdir -p $(BUILD_DIST)/uuid
	
	# uuid.mk Prep uuid
	cp -a $(BUILD_STAGE)/uuid/usr $(BUILD_DIST)/uuid
	
	# uuid.mk Sign
	$(call SIGN,uuid,general.xml)
	
	# uuid.mk Make .debs
	$(call PACK,uuid,DEB_UUID_V)
	
	# uuid.mk Build cleanup
	rm -rf $(BUILD_DIST)/uuid

.PHONY: uuid uuid-package
