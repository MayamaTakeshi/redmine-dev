#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd ~/src/git/redmine
cp config/database.yml.example config/database.yml
sed -i -r 's|database: redmine.*$|database: redmine|g' config/database.yml
sed -i -r 's|password: ""|password: "1234"|g' config/database.yml

# workaround for mariadb server version issues
sed -i -r 's|transaction_isolation|tx_isolation|g' config/database.yml

# start mariadb server
sudo /etc/init.d/mariadb start

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

bundle install --with development

bundle exec rake generate_secret_token

RAILS_ENV=production bundle exec rake db:migrate

RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data

cat <<EOF

redpmine preparation success
Now you can start redmine by doing:

cd ../redmine
bundle exec rails server -e development
EOF
