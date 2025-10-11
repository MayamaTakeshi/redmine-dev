#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [[ ! -e /.dockerenv ]]
then
    echo "You are not inside a docker container!. Aborting."
    exit 1
fi

echo "Waiting a little to not get spurious mariadb process"
sleep 1

echo "Waiting for mariadb to start"
while [[ ! `ps -e |grep mariadb` ]]
do
    echo "Waiting..."
    sleep 1
done

set +o errexit
if [[ `mysql -uroot -p1234 -e 'show databases'` ]]
then 
    echo "mariadb root password is already set"
    set -o errexit
else
    echo "Setting mysql root password"
    # it seems there is error even if setting password is successful so we need to ignore errors here too.
    mysql -uroot -e "use mysql; ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('1234')"
    set -o errexit

    if [[ ! `mysql -uroot -p1234 -e 'show databases'` ]]
    then 
        echo "could not set mariadb root password"
        exit 1
    fi
fi

if [[ `mysql -u root -p1234 -e 'show databases' | grep redmine` ]]
then 
    echo "database redmine already exists"
else
    mysql -u root -p1234 <<EOL
CREATE DATABASE redmine CHARACTER SET utf8mb4;
CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'redmine';
GRANT ALL PRIVILEGES ON redmine.* TO 'redmine'@'localhost';
EOL
fi

cd ~/src/git/redmine
cp config/database.yml.example config/database.yml
sed -i -r 's|database: redmine.*$|database: redmine|g' config/database.yml
sed -i -r 's|password: ""|password: "1234"|g' config/database.yml
sed -i -r 's|host: localhost|host: "127.0.0.1"|g' config/database.yml

# workaround for mariadb server version issues
sed -i -r 's|transaction_isolation|tx_isolation|g' config/database.yml

echo <<EOF
Applying workaround for 'bundle exec rake generate_secret_token'
that will result in:

NameError: uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger

    Logger::Severity.constants.each do |severity|
EOF

cat <<EOF > Gemfile.local
gem "mysql2", "~> 0.5.0"
gem 'concurrent-ruby', '1.3.4'
gem 'logger'
gem 'mutex_m'
gem 'bigdecimal'
gem 'benchmark'
gem 'ostruct'
gem 'webrick'
EOF

bundle config set --local without 'test'

bundle install --with development --path ./bundle-data

bundle exec rake generate_secret_token

RAILS_ENV=production bundle exec rake db:migrate

RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data

cat <<EOF

redpmine preparation success
Now you can start redmine by doing:

cd ../redmine
bundle exec rails server -e development -b 0.0.0.0
EOF
