ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif
SUBPROJECTS   += nginx
NGINX_VERSION := 1.21.5
DEB_NGINX_V   ?= $(NGINX_VERSION)

DEFAULT_NGINX_FLAGS := --with-compat \
					   --with-debug \
					   --with-http_addition_module \
					   --with-http_dav_module \
					   --with-http_degradation_module \
					   --with-http_flv_module \
					   --with-http_geoip_module \
					   --with-http_gunzip_module \
					   --with-http_gzip_static_module \
					   --with-http_mp4_module \
					   --with-http_realip_module \
					   --with-http_secure_link_module \
					   --with-http_slice_module \
					   --with-http_ssl_module \
					   --with-http_stub_status_module \
					   --with-http_sub_module \
					   --with-http_v2_module \
					   --with-ipv6 \
					   --with-mail \
					   --with-mail_ssl_module \
					   --with-pcre \
					   --with-pcre-jit \
					   --with-stream \
					   --with-stream_realip_module \
					   --with-stream_ssl_module \
					   --with-stream_ssl_preread_module \

nginx-setup: setup pcre openssl libgeoip
	wget -q -nc -P$(BUILD_SOURCE) https://nginx.org/download/nginx-$(NGINX_VERSION).tar.gz
	$(call EXTRACT_TAR,nginx-$(NGINX_VERSION).tar.gz,nginx-$(NGINX_VERSION),nginx)

ifneq ($(wildcard $(BUILD_WORK)/nginx/.build_complete),)
nginx:
	@echo "Using previously built nginx."
else
nginx: nginx-setup
	# do an config for the build machine and then sed out the cflags
	# because nginxs build system doesnt support cross compiling
	cd $(BUILD_WORK)/nginx && env -i ./configure \
		$(DEFAULT_NGINX_FLAGS) \
		--prefix=$(MEMO_PREFIX)/etc/nginx \
		--sbin-path=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/nginx \
		--conf-path=$(MEMO_PREFIX)/etc/nginx/nginx.conf \
		--pid-path=$(MEMO_PREFIX)/var/nginx/nginx.pid \
		--lock-path=$(MEMO_PREFIX)/var/nginx/nginx.lock \
		--with-cc-opt=-I$(MACOSX_SYSROOT)/include\ -I/opt/procursus/include \
		--with-ld-opt=-L$(MACOSX_SYSROOT)/lib\ -L/opt/procursus/lib

	sed -i 's|CFLAGS =.*|CFLAGS=$(CFLAGS) $(CPPFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile
	sed -i 's|LINK =.*|LINK=$(CC) $(LDFLAGS)|g' $(BUILD_WORK)/nginx/objs/Makefile


	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR=$(BUILD_STAGE)/nginx
	$(call AFTER_BUILD)
endif

nginx-package: nginx-stage
	# nginx.mk Package Structure
	rm -rf $(BUILD_DIST)/nginx

	# nginx.mk Prep nginx
	cp -a $(BUILD_STAGE)/nginx $(BUILD_DIST)

	# nginx.mk Sign
	$(call SIGN,nginx,general.xml)

	# nginx.mk Make .debs
	$(call PACK,nginx,DEB_NGINX_V)

	# nginx.mk Build cleanup
	rm -rf $(BUILD_DIST)/nginx

.PHONY: nginx nginx-package
