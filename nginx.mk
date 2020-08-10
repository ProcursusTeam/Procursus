ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nginx
NGINX_VERSION := 1.19.1
DEB_NGINX_V   ?= $(NGINX_VERSION)

nginx-setup: setup openssl pcre libgeoip
	wget -q -nc -P $(BUILD_SOURCE) https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
	$(call EXTRACT_TAR,nginx-$(NGINX_VERSION).tar.gz,nginx-$(NGINX_VERSION),nginx)
	$(call DO_PATCH,nginx,nginx,-p0)
	awk -i inplace '!found && /NGX_PLATFORM/ { print "NGX_PLATFORM=Darwin:19.5.0:iPhone10,1"; found=1 } 1' \
		$(BUILD_WORK)/nginx/configure

COMMON_CONFIGURE_FLAGS= \
	--with-cc-opt="$(CFLAGS) $(CPPFLAGS) -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC -DNGX_SYS_NERR=132 -DNGX_HAVE_MAP_ANON=1" \
	--with-ld-opt="$(LDFLAGS)" \
	--sbin-path=/usr/bin/nginx \
	--prefix=/usr/share/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--http-log-path=/var/log/nginx/access.log \
	--error-log-path=/var/log/nginx/error.log \
	--lock-path=/var/lock/nginx.lock \
	--pid-path=/run/nginx.pid \
	--modules-path=/usr/lib/nginx/modules \
	--http-client-body-temp-path=/var/lib/nginx/body \
	--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
	--http-proxy-temp-path=/var/lib/nginx/proxy \
	--http-scgi-temp-path=/var/lib/nginx/scgi \
	--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
	--with-debug \
	--with-pcre-jit \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_realip_module \
	--with-http_auth_request_module \
	--with-http_v2_module \
	--with-http_dav_module \
	--with-http_slice_module \
	--with-threads \
	--with-compat

LIGHT_CONFIGURE_FLAGS= \
	$(COMMON_CONFIGURE_FLAGS) \
	--with-http_gzip_static_module \
	--without-http_browser_module \
	--without-http_geo_module \
	--without-http_limit_req_module \
	--without-http_limit_conn_module \
	--without-http_memcached_module \
	--without-http_referer_module \
	--without-http_split_clients_module \
	--without-http_userid_module
#	--add-dynamic-module=$(MODULESDIR)/http-echo

FULL_CONFIGURE_FLAGS= \
	$(COMMON_CONFIGURE_FLAGS) \
	--with-http_addition_module \
	--with-http_geoip_module=dynamic \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_image_filter_module=dynamic \
	--with-http_sub_module \
	--with-http_xslt_module=dynamic \
	--with-stream=dynamic \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-mail=dynamic \
	--with-mail_ssl_module
#	--add-dynamic-module=$(MODULESDIR)/http-auth-pam \
#	--add-dynamic-module=$(MODULESDIR)/http-dav-ext \
#	--add-dynamic-module=$(MODULESDIR)/http-echo \
#	--add-dynamic-module=$(MODULESDIR)/http-upstream-fair \
#	--add-dynamic-module=$(MODULESDIR)/http-subs-filter

EXTRAS_CONFIGURE_FLAGS= \
	$(FULL_CONFIGURE_FLAGS) \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_perl_module=dynamic \
	--with-http_random_index_module \
	--with-http_secure_link_module
#	--add-dynamic-module=$(MODULESDIR)/http-headers-more-filter \
#	--add-dynamic-module=$(MODULESDIR)/http-auth-pam \
#	--add-dynamic-module=$(MODULESDIR)/http-cache-purge \
#	--add-dynamic-module=$(MODULESDIR)/http-dav-ext \
#	--add-dynamic-module=$(MODULESDIR)/http-ndk \
#	--add-dynamic-module=$(MODULESDIR)/http-echo \
#	--add-dynamic-module=$(MODULESDIR)/http-fancyindex \
#	--add-dynamic-module=$(MODULESDIR)/nchan \
#	--add-dynamic-module=$(MODULESDIR)/http-lua \
#	--add-dynamic-module=$(MODULESDIR)/rtmp \
#	--add-dynamic-module=$(MODULESDIR)/http-uploadprogress \
#	--add-dynamic-module=$(MODULESDIR)/http-upstream-fair \
#	--add-dynamic-module=$(MODULESDIR)/http-subs-filter

ifneq ($(wildcard $(BUILD_WORK)/nginx/.light_build_complete),)
nginx-light:
	@echo "Using previously built nginx-light."
else
nginx-light: nginx-setup
	cd $(BUILD_WORK)/nginx && ./configure $(LIGHT_CONFIGURE_FLAGS)

	+$(MAKE) -C $(BUILD_WORK)/nginx
	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR="$(BUILD_STAGE)/nginx-light"
	touch $(BUILD_WORK)/nginx/.light_build_complete
endif

	echo "#ifndef NGX_HAVE_MAP_ANON" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h
	echo "#define NGX_HAVE_MAP_ANON 1" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h
	echo "#endif" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h

	+$(MAKE) -C $(BUILD_WORK)/nginx
	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR="$(BUILD_STAGE)/nginx-light"
	touch $(BUILD_WORK)/nginx/.light_build_complete
endif
	
nginx-package: nginx-stage
	# nginx.mk Package Structure
	rm -rf $(BUILD_DIST)/nginx
	mkdir -p $(BUILD_DIST)/nginx

	# nginx.mk Prep nginx
	cp -a $(BUILD_STAGE)/nginx/{etc,var,usr} $(BUILD_DIST)/nginx

	mkdir -p $(BUILD_DIST)/nginx/var/lib/nginx

	# nginx.mk Sign
	$(call SIGN,nginx,general.xml)

	# nginx.mk Make .debs
	$(call PACK,nginx,DEB_NGINX_V)

	# nginx.mk Build cleanup
	rm -rf $(BUILD_DIST)/nginx

.PHONY: nginx nginx-package
