# Tasks

LesliDashboard exposes one supported maintenance task.

New accounts initialize their dashboards automatically. Creating a `Lesli::Account` provisions its `LesliDashboard::Account`, whose `after_create` callback runs `DashboardRegistrationOperator`. The account, dashboards, and initial components are created within the account creation transaction. A provisioning error raises and rolls back the signup.

SaaS registration does not require a Rake task. The task below is for existing accounts, such as after installing LesliDashboard or another participating engine.

## Register Dashboards

```shell
bin/rails lesli_dashboard:register
```

The task processes Core accounts with `find_each`, creates a missing LesliDashboard workspace, and runs `DashboardRegistrationOperator`. The catalog includes installed Lesli engines and explicitly registered custom engines.

For each account, registration creates a dashboard and all its initial components transactionally only when no dashboard has ever been stored for that engine. Existing dashboards, including soft-deleted ones, are left untouched. Errors raise and roll back that account's registration; previously completed accounts remain initialized.

| Property | Value |
| --- | --- |
| Environment | Any environment with the application and database loaded |
| Reads | Lesli accounts, installed-engine registry, component constants |
| Writes | Dashboard and component records |
| Repeatability | Preserves existing dashboards and component instances |

The task skips Lesli Core, LesliBabel, and the host application's `Root` entry. It does not add widgets to existing dashboards, restore removed widgets, or overwrite names, defaults, positions, sizes, or configuration.

Run it after:

* Installing LesliDashboard into an application with existing accounts
* Installing another engine that registers components

New widget definitions become available immediately through the catalog. Add them to an existing dashboard through the component editor.

Review account counts before running it in a large production database; work is performed synchronously for every account.

## Task Output

After successful completion, the task prints one message:

```text
LesliDashboard: Dashboard registration completed.
```

The operator returns its workspace and does not log. Automatic account initialization is silent. Errors still raise, so a failed task does not print the completion message.
