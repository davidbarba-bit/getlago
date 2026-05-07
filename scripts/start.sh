#!/bin/bash
rm -f ./tmp/pids/server.pid

if [ -v LAGO_CLICKHOUSE_MIGRATIONS_ENABLED ] && [ "$LAGO_CLICKHOUSE_MIGRATIONS_ENABLED" == "true" ]
then
  bundle exec rails db:migrate:primary
  bundle exec rails db:migrate:clickhouse
else
  bundle exec rails db:migrate
fi

bundle exec rails signup:seed_organization
bundle exec rails s -b 0.0.0.0
