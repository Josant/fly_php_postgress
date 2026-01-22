FROM php:8.2-apache

# 1. Instalar dependencias de Postgres
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Tu cadena de conexión directa
ENV DATABASE_URL="postgresql://fly-user:tPZ1lHoJxuKM7vHh3KbEB9Xh@pgbouncer.z23750v7myl096d1.flympg.net/fly-db"

# 3. Configurar puerto 8080 para Fly.io
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf

# 4. Configurar el DocumentRoot a /var/www/html/src
ENV APACHE_DOCUMENT_ROOT /var/www/html/src

# Cambiamos la configuración de los sitios disponibles
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# --- ESTA PARTE ELIMINA EL ERROR 403 ---
# Le decimos a Apache que permita el acceso total a la carpeta /var/www/html/src
RUN echo '<Directory /var/www/html/src>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# 5. Copiar archivos del proyecto
COPY . /var/www/html/

# 6. Asegurar que el usuario de Apache (www-data) sea el dueño de los archivos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html/src

# 7. Script de entrada para el SQL
RUN echo '#!/bin/bash\n\
if [ -f /var/www/html/sql/init.sql ]; then\n\
  psql "$DATABASE_URL" -f /var/www/html/sql/init.sql\n\
fi\n\
apache2-foreground' > /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

CMD ["/usr/local/bin/docker-entrypoint.sh"]
