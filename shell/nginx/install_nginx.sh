#!/bin/bash

[[ -z $BASH_SOURCE ]] && echo "请下载脚本运行" && exit

CENTOS_VERSION=$(rpm -qa|grep -E  "centos-release-[567]"|cut -d'-' -f3)
WORK_DIR='/opt/src/'
NAME='nginx'
#VERSION='1.12.2'
LOG_FILE="/tmp/`basename ${0} .sh`.log"
wget_cmd='wget -t 3 -w 5 -T 10 -q'
wget_cmd='wget -t 3 -w 5 -T 10 -nv'

echo "-------------------------------------------------"
echo "请选择要安装的nginx版本:"
while true; do
    select VERSION in 1.12.2 1.13.9 1.14.0
    do
        break
    done
    [[ -n ${VERSION} ]] && break
done

_check_installed_version() {
    OLD_VERSION=$(/opt/app/nginx/sbin/nginx -v 2>&1 |grep version|cut -d'/' -f2)
    if [[ -n "${OLD_VERSION}" ]]; then
        echo "-------------------------------------------------"
        echo "The ${NAME} version ${OLD_VERSION} is installed"
        while true; do
            read -r -p "Do you want overwrite install ${NAME} ${VERSION} (Y/n):" input
            case $input in 
                [yY][eE][sS]|[yY]|"")
                    break
                    ;;
                [nN][oO]|[nN])
                    exit
                    ;;
                *)
                    echo "Invalid input..."
                    ;;
            esac
        done
    fi
}

_install_lua() {
    while true; do
        echo "-------------------------------------------------"
        read -r -p "Install nginx lua module (y/N):" input
        case $input in
            [yY][eE][sS]|[yY])
                LUA_FLAG=1
                break
                ;;
            [nN][oO]|[nN]|"")
                LUA_FLAG=0
                break
                ;;
            *)
                echo "Invalid input..."
                ;;
        esac
    done
}

_install_nginx() {
    yum -y install gcc make pcre-devel zlib-devel wget zip unzip patch >> ${LOG_FILE} 2>&1
    [[ -d ${WORK_DIR} ]] || mkdir -p ${WORK_DIR}
    if [[ ${LUA_FLAG} -eq 1 ]]; then
        echo "-------------------------------------------------"
        echo "Start install luajit ..."
        { 
        cd ${WORK_DIR}
        ${wget_cmd} -O LuaJIT-2.1.0-beta3.tar.gz http://183.136.203.103:889/app_install/source/LuaJIT-2.1.0-beta3.tar.gz
        ${wget_cmd} -O ngx_devel_kit-0.3.1rc1.tar.gz http://183.136.203.103:889/app_install/source/nginx_modules/ngx_devel_kit-0.3.1rc1.tar.gz
        ${wget_cmd} -O lua-nginx-module-0.10.12rc2.tar.gz http://183.136.203.103:889/app_install/source/nginx_modules/lua-nginx-module-0.10.12rc2.tar.gz
        tar xf lua-nginx-module-0.10.12rc2.tar.gz
        tar xf ngx_devel_kit-0.3.1rc1.tar.gz
        tar xf LuaJIT-2.1.0-beta3.tar.gz && cd LuaJIT-2.1.0-beta3
        make clean
        [[ ${CENTOS_VERSION} -eq 5 ]] && make CC="gcc -std=gnu99" PREFIX=/opt/app/luajit
        [[ ${CENTOS_VERSION} -gt 5 ]] && make PREFIX=/opt/app/luajit
        make install PREFIX=/opt/app/luajit
        } >> ${LOG_FILE} 2>&1
        
        if [[ "$?" == "0" ]]; then 
          export LUAJIT_LIB=/opt/app/luajit/lib
          export LUAJIT_INC=/opt/app/luajit/include/luajit-2.1
	      export OPTION='--add-module=../ngx_devel_kit-0.3.1rc1 --add-module=../lua-nginx-module-0.10.12rc2 --with-ld-opt=-Wl,-rpath,/opt/app/luajit/lib'
          echo "Install luajit successfully !!!"
        else
          echo "Install luajit failure !!!"
        fi
    fi
    
    echo "-------------------------------------------------"
    echo "Start install ${NAME} ${VERSION} ..."
    {
    cd ${WORK_DIR}
    ${wget_cmd} -O ${NAME}-${VERSION}.tar.bz2 http://183.136.203.103:889/app_install/source/${NAME}-${VERSION}.tar.gz
    ${wget_cmd} -O openssl-1.0.2o.tar.gz http://183.136.203.103:889/app_install/source/openssl-1.0.2o.tar.gz

    tar xf openssl-1.0.2o.tar.gz
    tar xf ${NAME}-${VERSION}.tar.bz2
    
    cd ${NAME}-${VERSION}
    make clean &>/dev/null
    ./configure \
      --prefix=/opt/app/nginx \
      --modules-path=/opt/app/nginx/modules \
      --http-client-body-temp-path=/opt/app/nginx/cache/client_temp \
      --http-proxy-temp-path=/opt/app/nginx/cache/proxy_temp \
      --http-fastcgi-temp-path=/opt/app/nginx/cache/fastcgi_temp \
      --http-uwsgi-temp-path=/opt/app/nginx/cache/uwsgi_temp \
      --http-scgi-temp-path=/opt/app/nginx/cache/scgi_temp \
      --with-file-aio \
      --with-threads \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_slice_module \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_sub_module \
      --with-http_v2_module \
      --with-stream \
      --with-stream_ssl_module \
      --with-openssl=../openssl-1.0.2o/ \
      --with-openssl-opt='enable-ssl2' \
      --with-debug \
      ${OPTION}
 
    make -j4 && make install
    } >> ${LOG_FILE} 2>&1
    
    if [[ $? == 0 ]]; then
        {
        mkdir -p /opt/app/nginx/cache /opt/logs/nginx
        ${wget_cmd} -O /opt/app/nginx/conf/nginx.conf.tpl http://183.136.203.103:889/app_install/source/nginx.conf
        } >> ${LOG_FILE} 2>&1
        echo "Install ${NAME} ${VERSION} successfully !!!"
    else
        echo "Install ${NAME} ${VERSION} failure !!!"
    fi
}

:> ${LOG_FILE}
_check_installed_version
_install_lua
_install_nginx
echo "-------------------------------------------------"
echo "The install log file is ${LOG_FILE}"
echo "-------------------------------------------------"
exit
