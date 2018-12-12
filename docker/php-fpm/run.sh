#!/usr/bin/env bash

chown ${APP_RUN_PUID}:${APP_RUN_PGID} -R ${CONTAINER_CODE_PATH}

if [[ "${RUN_ENV}" = 'production' || "${RUN_ENV}" = "" ]]; then
    PHP_FPM_CONF_PATH="${CONTAINER_DOCKER_PATH}/php-fpm/config-production"
else
    PHP_FPM_CONF_PATH="${CONTAINER_DOCKER_PATH}/php-fpm/config-${RUN_ENV}"
fi

PHP_FPM_RUN_CONF_PATH="${CONTAINER_DOCKER_PATH}/php-fpm/run-config"

# clean run config
rm -rf ${PHP_FPM_RUN_CONF_PATH}
mkdir -p "${PHP_FPM_RUN_CONF_PATH}/fpm.d"

# php.ini
cp "${PHP_FPM_CONF_PATH}/php.ini" "${PHP_FPM_RUN_CONF_PATH}/php.ini"

# fpm replace
cat "${PHP_FPM_CONF_PATH}/php-fpm.conf" \
| sed "s#\${CONTAINER_DOCKER_PATH}#${CONTAINER_DOCKER_PATH}#g" \
> "${PHP_FPM_RUN_CONF_PATH}/php-fpm.conf"

# fpm.d conf replace
for CURRENT_FILE in $(ls "${PHP_FPM_CONF_PATH}/fpm.d")
do
    if test -f "${PHP_FPM_CONF_PATH}/fpm.d/${CURRENT_FILE}"
    then
        cat "${PHP_FPM_CONF_PATH}/fpm.d/${CURRENT_FILE}" \
        | sed "s#\${APP_RUN_NAME}#${APP_RUN_NAME}#g" \
        | sed "s#\${APP_RUN_GROUP}#${APP_RUN_GROUP}#g" \
        > "${PHP_FPM_RUN_CONF_PATH}/fpm.d/${CURRENT_FILE}"
        #$(basename ${CURRENT_FILE})
    fi
done

# clean opcache
php -r 'if(function_exists("opcache_reset")) {opcache_reset();}'

# run
php-fpm -c ${PHP_FPM_RUN_CONF_PATH}/php.ini -y ${PHP_FPM_RUN_CONF_PATH}/php-fpm.conf