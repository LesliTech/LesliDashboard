# Tasks

LesliDashboard exposes one supported maintenance task.

## Register Dashboards

```shell
bin/rails lesli_dashboard:register
```

The task iterates through every `Lesli::Account`, discovers installed engines through `LesliSystem.engines`, creates a default dashboard for each participating engine, and creates missing component records from that engine's `Dashboard::COMPONENTS` constant.

| Property | Value |
| --- | --- |
| Environment | Any environment with the application and database loaded |
| Reads | Lesli accounts, installed-engine registry, component constants |
| Writes | Dashboard and component records |
| Repeatability | Idempotent for existing engine and component names |

The task skips Lesli Core, LesliBabel, and the host application's `Root` entry. It does not remove retired components or overwrite existing `size`, `position`, or `config` values.

Run it after:

* Installing LesliDashboard into an application with existing accounts
* Installing another engine that registers components
* Adding a new component to an existing engine

Review account counts before running it in a large production database; work is performed synchronously for every account.
