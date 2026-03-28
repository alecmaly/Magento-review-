#!/usr/bin/env bash
# Run from project root: bash docker/install.sh
set -e

echo "==> Installing Composer dependencies..."
docker compose exec php composer install --no-interaction

echo "==> Running Magento setup:install..."
docker compose exec php php bin/magento setup:install \
  --base-url="http://localhost:8080/" \
  --db-host=db \
  --db-name=magento \
  --db-user=magento \
  --db-password=magento \
  --admin-firstname=Admin \
  --admin-lastname=User \
  --admin-email=admin@example.com \
  --admin-user=admin \
  --admin-password='Admin1234!' \
  --backend-frontname=admin \
  --language=en_US \
  --currency=USD \
  --timezone=America/Chicago \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch \
  --opensearch-port=9200 \
  --opensearch-index-prefix=magento2 \
  --opensearch-enable-auth=0 \
  --opensearch-timeout=15 \
  --session-save=redis \
  --session-save-redis-host=redis \
  --session-save-redis-port=6379 \
  --session-save-redis-db=2 \
  --cache-backend=redis \
  --cache-backend-redis-server=redis \
  --cache-backend-redis-port=6379 \
  --cache-backend-redis-db=0 \
  --cleanup-database

echo "==> Setting developer mode..."
docker compose exec php php bin/magento deploy:mode:set developer

echo "==> Disabling 2FA..."
docker compose exec php php bin/magento module:disable \
    Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth 2>/dev/null || true

echo "==> Configuring mail to use Mailpit..."
docker compose exec php php bin/magento config:set system/smtp/host mailpit
docker compose exec php php bin/magento config:set system/smtp/port 1025

echo "==> Flushing cache..."
docker compose exec php php bin/magento cache:flush

echo ""
echo "=================================="
echo "  Storefront  http://localhost:8080"
echo "  Admin       http://localhost:8080/admin  (admin / Admin1234!)"
echo "  Mailpit     http://localhost:8025"
echo "  MySQL       localhost:3306  (magento / magento)"
echo "  Redis       localhost:6379"
echo "=================================="
