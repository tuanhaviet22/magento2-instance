.SILENT:
## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

.PHONY: help

help:
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'

dev := ''
prod := ''

#Information dev database
db_dev 		:= ''
user_db_dev := ''
host_db_dev := ''
port_db_dev := ''

#Information dev database
db_local 		:= 'instance_m2'
user_db_local 	:= 'root'
host_db_local 	:= '127.0.0.1'
url_local		:= 'http://instance.magento2.local/'

db_prod := ''
theme 	:= ''

PHP := 'php'

## SSH to dev site
ssh_dev:
ifneq ($(dev), '')
	ssh $(dev)
else
	echo "${COLOR_COMMENT}Please define dev on Makefile"
endif

deploy: ## Full deploy Magento
	$(PHP) bin/magento se:up
	$(PHP) bin/magento s:d:c
	$(PHP) bin/magento s:s:d -f

maintenance_enable: ## Enable maintenance mode
	$(PHP) bin/magento maintenance:enable

maintenance_disable: ## Disable maintenance mode
	$(PHP) bin/magento maintenance:disable

deploy_front_theme: ## Deploy Magento frontend, only frontend area and theme development
	$(PHP) bin/magento s:s:d -f -a frontend -t $(theme)

download_db_dev: ## Pull SQL file from dev server
	ssh $(dev) "mysqldump --single-transaction $(db_dev) -u$(user_db_dev) --port=$(port_db_dev) --host=$(host_db_dev) | gzip -9 -" > $(db_dev).sql.gz
	gzip -d $(db_dev).sql.gz

import_db_dev: ## Import SQL to local database
	mysql -u$(user_db_local) -h$(host_db_local) $(db_local) < $(db_dev).sql

sync_vendor_from_dev: ## Pull vendor dir from dev server
	rsync -azP $(dev):public_html/vendor .

install: ## Install Magento
	$(PHP) bin/magento setup:install \
	--base-url=$(url_local) \
	--db-host=$(host_db_local) \
	--db-name=$(db_local) \
	--db-user=$(user_db_local) \
	--db-password=root \
	--admin-firstname=admin \
	--admin-lastname=admin \
	--admin-email=admin@admin.com \
	--admin-user=admin \
	--admin-password=admin123 \
	--language=en_US \
	--currency=USD \
	--timezone=America/Chicago \
	--use-rewrites=1 \
	--search-engine=elasticsearch7 \
	--elasticsearch-host=localhost \
	--elasticsearch-port=9200 \
	--elasticsearch-index-prefix=magento2 \
	--elasticsearch-timeout=15

install_sample_data: ## Add Sample Data
	$(PHP) bin/magento sampledata:deploy
