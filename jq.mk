ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += jq
JQ_VERSION   := 1.6
DEB_JQ_V     ?= $(JQ_VERSION)

jq-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/stedolan/jq/releases/download/jq-$(JQ_VERSION)/jq-$(JQ_VERSION).tar.gz
	$(call EXTRACT_TAR,jq-$(JQ_VERSION).tar.gz,jq-$(JQ_VERSION),jq)

ifneq ($(wildcard $(BUILD_WORK)/jq/.build_complete),)
jq:
	@echo "Using previously built jq."
else
jq: jq-setup liboniguruma
	cd $(BUILD_WORK)/jq && autoreconf -fi && CFLAGS="$(CFLAGS) -D_REENTRANT" ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--enable-shared=yes \
		--enable-static=no \
		--with-oniguruma=$(BUILD_STAGE)/liboniguruma/usr \
		--disable-docs \
		--disable-maintainer-mode
	+$(MAKE) -C $(BUILD_WORK)/jq install \
		DESTDIR=$(BUILD_STAGE)/jq
	touch $(BUILD_WORK)/jq/.build_complete
endif

jq-package: jq-stage
	# jq.mk Package Structure
	rm -rf $(BUILD_DIST)/jq
	mkdir -p $(BUILD_DIST)/jq

	# jq.mk Prep jq
	cp -a $(BUILD_STAGE)/jq/usr $(BUILD_DIST)/jq

	# jq.mk Sign
	$(call SIGN,jq,general.xml)

	# jq.mk Make .debs
	$(call PACK,jq,DEB_JQ_V)

	# jq.mk Build cleanup
	rm -rf $(BUILD_DIST)/jq

.PHONY: jq jq-package
