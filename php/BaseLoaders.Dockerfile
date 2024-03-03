ARG VERSION

# Extend from the PHP Base Image
FROM panosru/php:$VERSION-base

# Install ioncube loader
RUN php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && php_additional_ini=$(php -i | grep 'additional .ini files' | pcregrep -o1 '=> (.+)') \
    && cd /tmp \
    && curl -fSL 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz' -o ioncube.tar.gz \
    && mkdir -p ioncube \
    && tar -xf ioncube.tar.gz -C ioncube --strip-components=1 \
    && rm ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_$php_version.so $php_extension_dir/ioncube_loader_lin_$php_version.so \
    && rm -r ioncube \
    && echo "zend_extension=$php_extension_dir/ioncube_loader_lin_$php_version.so" > $php_additional_ini/00-ioncube.ini

# Instal SourceGuardian loader
RUN php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
    && php_extension_dir=$(php -r "echo ini_get('extension_dir');") \
    && php_additional_ini=$(php -i | grep 'additional .ini files' | pcregrep -o1 '=> (.+)') \
    && cd /tmp \
    && curl -fSL 'https://www.sourceguardian.com/loaders/download/loaders.linux-x86_64.tar.gz' -o sg.tar.gz \
    && mkdir -p sg \
    && tar -xf sg.tar.gz -C sg \
    && rm sg.tar.gz \
    && mv sg/ixed.$php_version.lin $php_extension_dir/sourceguardian_$php_version.so \
    && rm -r sg \
    && echo "extension=$php_extension_dir/sourceguardian_$php_version.so" > $php_additional_ini/15-sourceguardian.ini

# Clean up
RUN rm -Rf /tmp/*
