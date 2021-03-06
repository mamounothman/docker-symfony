ARG PHP_VERSION

FROM php:${PHP_VERSION}-fpm

ARG DEFAULT_TIMEZONE
ARG PHP_MEMORY_LIMIT

ARG NODE_JS_VERSION

ARG USER_ID
ARG GROUP_ID

ARG XDEBUG_REMOTE_PORT
ARG XDEBUG_REMOTE_AUTOSTART
ARG XDEBUG_REMOTE_ENABLE
ARG XDEBUG_REMOTE_HOST
ARG XDEBUG_REMOTE_CONNECT_BACK

MAINTAINER Vasilij Dusko <vasilij@prado.lt>

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    gnupg1 openssl git unzip libzip-dev nano libpng-dev libmagickwand-dev curl xauth xvfb openssh-client less inkscape cron libmcrypt-dev

# Install PHP extensions. Type docker-php-ext-install to see available extensions
RUN docker-php-ext-configure zip --with-libzip && \
    docker-php-ext-install -j$(nproc) \
    pdo pdo_mysql opcache zip gd mysqli exif bcmath calendar

RUN apt-get install -y libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl

RUN pecl install \
    imagick xdebug apcu apcu_bc mcrypt

RUN docker-php-ext-enable \
    imagick mysqli calendar exif bcmath xdebug apcu mcrypt

# Set timezone
RUN ln -snf /usr/share/zoneinfo/${DEFAULT_TIMEZONE} /etc/localtime && echo ${DEFAULT_TIMEZONE} > /etc/timezone && \
    printf '[PHP]\ndate.timezone = "%s"\n' ${DEFAULT_TIMEZONE} > $PHP_INI_DIR/conf.d/tzone.ini

RUN printf '[CUSTOM]\nmemory_limit = "%s"\n' ${PHP_MEMORY_LIMIT} >> $PHP_INI_DIR/conf.d/custom.ini

RUN echo 'extension=apc.so' >> $PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer
RUN mkdir -p /var/www/.composer
COPY composer/config.json /var/www/.composer/config.json
RUN chown -R ${USER_ID}:${GROUP_ID} /var/www/.composer && \
    chown ${USER_ID}:${GROUP_ID} /var/www

# npm & node
RUN mkdir -p /var/www/.npm && \
    chown -R ${USER_ID}:${GROUP_ID} /var/www/.npm && \
    printf 'Package: *\nPin: origin deb.nodesource.com\nPin-Priority: 600' > /etc/apt/preferences.d/nodejs && \
    curl -sL https://deb.nodesource.com/setup_${NODE_JS_VERSION} | bash && \
    apt-get install -y nodejs && \
    update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10 && \
    npm install -g grunt-cli yargs async sass gulp requirejs

# bugfix: remove cmdtest to install yarn correctly.
RUN apt-get remove -y cmdtest

# yarn package manager
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y yarn

RUN apt-get remove --purge -y gnupg1 && apt-get -y --purge autoremove && rm -rf /var/lib/apt/lists/*

# Copy xdebug and php config.
COPY conf.d/* /usr/local/etc/php/conf.d/

RUN sed -i 's#${XDEBUG_REMOTE_PORT}#'"${XDEBUG_REMOTE_PORT}"'#g' $PHP_INI_DIR/conf.d/xdebug.ini && \
    sed -i 's#${XDEBUG_REMOTE_AUTOSTART}#'"${XDEBUG_REMOTE_AUTOSTART}"'#g' $PHP_INI_DIR/conf.d/xdebug.ini && \
    sed -i 's#${XDEBUG_REMOTE_ENABLE}#'"${XDEBUG_REMOTE_ENABLE}"'#g' $PHP_INI_DIR/conf.d/xdebug.ini && \
    if [ ! -z ${XDEBUG_REMOTE_HOST} ]; then printf '\nxdebug.remote_host = %s\n' ${XDEBUG_REMOTE_HOST} >> $PHP_INI_DIR/conf.d/xdebug.ini; fi && \
    if [ ! -z ${XDEBUG_REMOTE_CONNECT_BACK} ]; then printf '\nxdebug.remote_connect_back = %s\n' ${XDEBUG_REMOTE_CONNECT_BACK} >> $PHP_INI_DIR/conf.d/xdebug.ini; fi

# Install wkhtmltopdf
RUN curl -o wkhtmltox-0.12.4_linux-generic-amd64.tar.xz -sL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz  && \
    echo '3f923f425d345940089e44c1466f6408b9619562 wkhtmltox-0.12.4_linux-generic-amd64.tar.xz' | sha1sum -c - && \
    tar -xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz && \
    cp wkhtmltox/lib/* /usr/lib/ && \
    cp wkhtmltox/bin/* /usr/bin/ && \
    cp -r wkhtmltox/share/man/man1 /usr/share/man/ && \
    chmod a+x /usr/bin/wkhtmltopdf && \
    chmod a+x /usr/bin/wkhtmltoimage

# Map user id from host user when it's provided
RUN if [ ! -z ${USER_ID} ] && [ ${USER_ID} -ne 0 ]; then usermod -u ${USER_ID} www-data; fi
RUN if [ ! -z ${GROUP_ID} ] && [ ${GROUP_ID} -ne 0 ]; then groupmod -g ${GROUP_ID} www-data; fi

RUN echo 'alias sf="php bin/console"' >> /var/www/.bashrc && \
    echo 'alias sf2="php app/console"' >> /var/www/.bashrc && \
    echo 'alias sf3="php bin/console"' >> /var/www/.bashrc && \
    echo 'alias sf4="php bin/console"' >> /var/www.bashrc

# set default user and working directory
USER ${USER_ID}
WORKDIR /var/www/project