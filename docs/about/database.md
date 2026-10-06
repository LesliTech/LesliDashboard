# Database

LesliDashboard uses collection code `03` and engine code `06`.

| Migration code | Table | Responsibility | Important relationships |
| --- | --- | --- | --- |
| `03.06.00.01.10` | `lesli_dashboard_accounts` | Engine state for a Lesli account | Required core account reference |
| `03.06.05.01.10` | `lesli_dashboard_dashboards` | Dashboard ownership and defaults | Dashboard account, optional core user and role |
| `20260118063343` | `lesli_dashboard_components` | Component name, position, width, and JSON configuration | Required dashboard reference |

Dashboards use soft deletion through `deleted_at`. Components are removed normally and store their options in `config`, with `size` representing the desktop grid width.

The components migration uses a published Rails timestamp rather than a Lesli ten-digit code. Do not rename an applied migration. Future migrations must follow the current [migration versioning standard](/engines/lesli/database/versioning).

```shell
bin/rails lesli:db:prepare
bin/rails db:migrate:status
```

When changing component defaults, remember that registration uses `create_with`; it does not overwrite existing records. Use an explicit migration or maintenance task for persisted layouts.

See [Database Architecture](/engines/lesli/database/structure) for account ownership and shared migration helpers.
