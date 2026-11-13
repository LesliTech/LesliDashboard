# Database

LesliDashboard uses collection code `03` and engine code `06`.

This page describes the current schema. The [Dashboard Contract](/engines/dashboard/about/contract) defines the data model and lifecycle for the dashboard management implementation. The original migrations now include the required name, component defaults, lookup indexes, and a unique active default per account and engine. Rebuild disposable development/test databases to apply these changes to already-created tables.

| Migration code | Table | Responsibility | Important relationships |
| --- | --- | --- | --- |
| `03.06.00.01.10` | `lesli_dashboard_accounts` | Engine state for a Lesli account | Required core account reference |
| `03.06.05.01.10` | `lesli_dashboard_dashboards` | Dashboard ownership and defaults | Required dashboard account and engine; user and role ownership removed |
| `20260118063343` | `lesli_dashboard_components` | Component name, position, width, and JSON configuration | Required dashboard reference |

Dashboards use soft deletion through `deleted_at`. Components are removed normally and store their options in `config`, with `size` representing the desktop grid width.

The components migration uses a published Rails timestamp rather than a Lesli ten-digit code. Do not rename an applied migration. Future migrations must follow the current [migration versioning standard](/engines/lesli/database/versioning).

```shell
bin/rails lesli:db:prepare
bin/rails db:migrate:status
```

When changing component defaults, remember that registration initializes only engines without any stored dashboard, including deleted records; it does not modify existing layouts. Use an explicit migration or maintenance task for persisted layouts.

See [Database Architecture](/engines/lesli/database/structure) for account ownership and shared migration helpers.

## Explicit Lifecycle Operations

`LesliDashboard::DashboardService` provides `create!(account:, engine:, name:, default: false)`, `make_default!(dashboard)`, and `destroy!(dashboard)`. These operations lock the workspace and run transactionally. Use them for default lifecycle changes; direct model writes do not perform replacement or promotion. The database index prevents multiple active defaults but cannot require one to exist.

Deleting a dashboard through the service retains its components and promotes the oldest remaining dashboard in the same account and engine. Controllers scope dashboards to the authenticated account and components to their parent dashboard. Missing, deleted, and inaccessible parents return 404.

## Breaking Changes

This development release modifies the original migrations. Running `db:migrate` does not update a table whose original migration has already run. Rebuild only disposable development/test databases; retain backups and write an explicit data migration if an existing database must be preserved.

- Dashboards now require `name`, `engine`, and their local engine `account_id`.
- User/role ownership columns and the nested `Dashboard::Component` implementation are removed. Use `LesliDashboard::Component` and `dashboard.components`.
- Components require an identifier, positive integer position, width from 1 to 12, and JSON object configuration.
- The partial unique index permits at most one non-deleted default per account and engine on SQLite and PostgreSQL. Service operations maintain the lifecycle; direct writes can still leave no default.
- Dashboard deletion is soft; its components remain stored. Removing an individual widget permanently deletes that instance.
- Registration no longer reconciles existing layouts. Removing or renaming a widget definition requires explicitly migrating or removing stored instances before rendering those dashboards. The editor permits removing retired instances, but their dashboard partial cannot be resolved from a missing catalog definition.

Workspace transactions serialize registration and default changes using row locks on PostgreSQL. SQLite permits a single writer and does not provide equivalent row locks; contending writers may need retrying after a busy/locked response. The unique default index protects against duplicate defaults on both adapters.
