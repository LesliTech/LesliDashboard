# Database

LesliDashboard uses collection code `03` and engine code `06`.

This page describes the current schema. The [Dashboard Contract](/engines/dashboard/about/contract) defines the target data model and lifecycle for the dashboard management implementation. The original migrations now include the required name, component defaults, lookup indexes, and a unique active default per account and engine. Rebuild disposable development/test databases to apply these changes to already-created tables.

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

Deleting a dashboard through the service retains its components and promotes the oldest remaining dashboard in the same account and engine. Controller and component access restrictions are scheduled for the next implementation phases.
