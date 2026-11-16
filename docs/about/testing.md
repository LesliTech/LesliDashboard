# Testing

Run commands from the LesliDashboard directory. Always use a dedicated test database. The suite covers CRUD, account boundaries, default replacement and deletion of the last dashboard, repeated registration, component validation and rollback, Turbo/JSON responses, forms, translations, and rendering through Core.

## Standalone with Published Dependencies

```shell
bundle install
bundle exec rake test
```

The dummy keeps `maintain_test_schema` enabled and includes both Core and
Dashboard migration paths. Keep `test/dummy/db/schema.rb` in version control;
Rails uses it to initialize a fresh test database.

To rebuild a disposable test database explicitly, use the engine's Rake tasks:

```shell
RAILS_ENV=test bundle exec rake app:db:drop app:db:create app:db:migrate
```

This deletes the selected test database. Use `app:db:migrate` alone when its
data should be retained. The engine task wrapper adds Dashboard's migration
paths; do not bypass it with `-f test/dummy/Rakefile`.

## Standalone with Workspace Dependencies

The development workspace must contain `engines/Lesli`, `engines/LesliDashboard`, and the gems listed in `test/Gemfile.workspace`. This manifest uses unreleased dependencies without loading other domain engines. Its lockfile is local and ignored. Use it while preparing a coordinated framework release; the regular Gemfile tests published dependencies instead.

```shell
export BUNDLE_GEMFILE="$PWD/test/Gemfile.workspace"
bundle install
export RAILS_ENV=test
export DATABASE_URL=sqlite3:/tmp/lesli_dashboard_test.sqlite3
bundle exec rake app:db:migrate
bundle exec rake test
```

For PostgreSQL, create a dedicated database, change `DATABASE_URL` to its connection URL, and repeat migration and tests. The development Gemfiles include the `pg` adapter; it is not a runtime dependency of the engine.

```shell
export DATABASE_URL=postgresql://localhost/lesli_dashboard_test
bundle exec rake app:db:migrate
bundle exec rake test
```

Concurrency tests use committed records and two synchronized connections. They are skipped on SQLite, whose locking differs from PostgreSQL. Tests involving LesliAdmin or LesliShield are skipped when those optional engines are absent; run the Builder integration checks to cover them.

## Builder Integration

From the Builder root, using its own bundle and an isolated migrated database:

```shell
RAILS_ENV=test bundle exec bin/rails test engines/LesliDashboard/test test/integration/lesli_modules_test.rb engines/LesliAdmin/test/models/lesli_admin/dashboard_test.rb engines/LesliSupport/test/models/lesli_support/dashboard_test.rb
```

Run this command with both adapters. Core account creation must provision dashboards automatically, and two accounts must retain independent defaults, layouts, and widget configuration after registration is repeated.
