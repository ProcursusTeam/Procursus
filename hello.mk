ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += hello
HELLO_VERSION := 2.10
DEB_HELLO_V   ?= $(HELLO_VERSION)

hello-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://ftpmirror.gnu.org/gnu/hello/hello-$(HELLO_VERSION).tar.gz
	$(call EXTRACT_TAR,hello-$(HELLO_VERSION).tar.gz,hello-$(HELLO_VERSION),hello)
	$(call DO_PATCH,hello,hello,-p1)

ifneq ($(wildcard $(BUILD_WORK)/hello/.build_complete),)
hello:
	@echo "Using previously built hello."
else
hello: hello-setup
	cd $(BUILD_WORK)/hello && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/hello
	+$(MAKE) -C $(BUILD_WORK)/hello install \
		DESTDIR=$(BUILD_STAGE)/hello
	touch $(BUILD_WORK)/hello/.build_complete
endif

hello-package: hello-stage
	# hello.mk Package Structure
	rm -rf $(BUILD_DIST)/hello
	mkdir -p $(BUILD_DIST)/hello
	
	# hello.mk Prep hello
	cp -a $(BUILD_STAGE)/hello $(BUILD_DIST)
	
	# hello.mk Sign
	$(call SIGN,hello,general.xml)
	
	# hello.mk Make .debs
	$(call PACK,hello,DEB_HELLO_V)
	
	# hello.mk Build cleanup
	rm -rf $(BUILD_DIST)/hello

.PHONY: hello hello-package
