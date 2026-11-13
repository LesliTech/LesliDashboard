# Dashboard Contract

This page defines the agreed behavior for the first dashboard management version. The model and original migration changes are implemented, together with explicit service operations for creation, promotion, and deletion. Dashboard CRUD, scoped selection, and presentation are implemented. The component editor and its mutation endpoints remain pending. The [Database](/engines/dashboard/about/database) and [Tasks](/engines/dashboard/about/tasks) pages describe the current implementation.

## Ownership and Scope

Every dashboard belongs to one `LesliDashboard::Account` and one participating engine. Its `account_id` references `lesli_dashboard_accounts`, whose `account_id` references the Core account.

The standard entry point remains:

```ruby
current_user.account.dashboard.dashboards
```

The engine is stored by its canonical name, such as `LesliSupport`. Account and engine are assigned at creation and remain unchanged during editing. A dashboard is shared by authorized users of that account; access continues to follow the application's authorization rules.

A single account can have several dashboards for the same engine. Selection, default changes, and replacement after deletion always operate within the same account and engine. Engine-specific dashboard classes share a table, so their class names alone do not restrict queries to an engine.

## Dashboard Data

| Field | Contract |
| --- | --- |
| `id` | Identifies a dashboard independently of its display name. |
| `account_id` | Required reference to the local LesliDashboard account. |
| `engine` | Required name of the participating engine. |
| `name` | Required display name. Trim surrounding whitespace and reject an empty result. Names may repeat; record identity uses `id`. |
| `default` | Required boolean. Its value follows the lifecycle rules below. |
| `deleted_at` | `nil` for active dashboards; a timestamp for soft-deleted dashboards. |
| `created_at`, `updated_at` | Standard record timestamps. |

User and role ownership are outside this version. A dashboard's name is user-provided content; interface labels and names supplied by initialization use I18n.

## Default Dashboard Lifecycle

For each account and engine, zero active dashboards means zero defaults. One or more active dashboards means exactly one default. Deleted dashboards never participate in selection or replacement.

| Operation | Required behavior |
| --- | --- |
| Create the first active dashboard | Make it the default, even if `default: false` was supplied. |
| Create an additional dashboard | Keep the existing default unless the new dashboard is explicitly selected as default. |
| Select another default | Set the selected dashboard as default and clear the previous one within the same account and engine. |
| Clear the current default without selecting a replacement | Reject the change and retain the current default. |
| Rename or edit components | Keep the current default unchanged. |
| Delete a non-default dashboard | Soft-delete it and keep the current default. |
| Delete the default while others remain | Soft-delete it, clear its default flag, and promote the oldest remaining active dashboard. |
| Delete the last active dashboard | Soft-delete it, clear its default flag, and leave the account and engine with no active dashboard. |
| Create a dashboard after deleting all previous ones | Treat it as the first active dashboard and make it the default. |

The replacement order is `created_at ASC, id ASC`. The identifier breaks ties when creation timestamps are equal.

Creation, default changes, and deletion with replacement must preserve these rules in one transaction. A failed operation leaves the previous state intact. Concurrent operations must also preserve the single-default rule.

## Selection and Empty States

An engine's dashboard entry point selects its active default within the current account. An explicit dashboard selection must belong to that same account and the requested engine.

If no active dashboard exists, show an empty state with a create action when authorized. Opening the page does not create a replacement dashboard. If a dashboard exists without components, show an empty dashboard with an add-component action when authorized.

Requests for missing, deleted, or out-of-scope dashboard identifiers return not found. They do not silently select another dashboard.

## Deletion and Components

Soft-deleting a dashboard preserves its component records, positions, sizes, and configuration. Component reads and mutations must go through an accessible active parent dashboard, so retained components cannot be viewed or changed through their identifiers after the parent is deleted.

Removing a component from an active dashboard permanently deletes only that component instance. It does not delete the widget definition or any business records displayed by the widget.

If permanent dashboard removal is introduced, it must remove the dashboard's component records as well. A restore interface is outside this version; any future restore operation must reapply the default rules instead of blindly restoring a previous default flag.

## Widget Definitions and Component Instances

A widget definition describes an available widget supplied by an engine. A component is one persisted instance of that widget inside a dashboard.

The same widget may appear several times in one dashboard. Each instance has its own `id`, position, size, and configuration. Updating or removing one instance leaves the others unchanged. The pair `(dashboard_id, component)` must therefore not be unique.

| Component field | Contract |
| --- | --- |
| `dashboard_id` | Required parent dashboard. Account and engine come from this parent. |
| `component` | Required identifier of a widget available to the dashboard's engine when adding it. |
| `position` | Positive integer. New instances append after the current last position. Display order is `position ASC, id ASC`. |
| `size` | Integer from 1 to 12 on the desktop grid. Initial width comes from the widget definition, with 4 as the general default. |
| `config` | JSON object. Initial options come from the widget definition, with an empty object as the general default. Supported options belong to each widget's contract. |

Position ties have a deterministic display order and do not require a uniqueness constraint. Components inherit the dashboard's account and engine rather than storing another ownership reference.

## Existing Consumer Review

The Phase 1 review of LesliBuilder, its local engines, and supporting gems found:

* The dashboard migration declares optional `user_id` and `role_id` references. The shared model declares an optional `belongs_to :user`, but no role association.
* No code consuming those references for persisted-dashboard ownership, selection, or editing was found in the reviewed workspace. LesliAudit's user analytics dashboard is a separate reporting feature.
* Registration and the shared renderer currently use engine-based dashboard selection. The default callback currently scopes only by account and must be corrected to include the engine.
* Registration currently matches components by widget name. That matching must not be used as the identity of editable component instances.
* Several engine account models declare `has_many :dashboards`. Their foreign keys must be reviewed because dashboard ownership uses the LesliDashboard account identifier.
* LesliAdmin currently invokes registration while displaying its dashboard. That integration must be revised to respect the rule that viewing an empty dashboard does not recreate it.

The `user_id` and `role_id` references and the unused user association are candidates for removal in the data-model phase. This phase does not remove columns or change existing records. Migration planning must account for installed consumers and existing data outside the reviewed workspace.

## Implementation Principles

Prefer small, readable methods and explicit account and engine scopes. Keep basic associations and validations in models, CRUD orchestration in services, and initialization in an operator. Introduce abstractions only when they remove demonstrated duplication or clarify a responsibility.

Comment decisions that are not obvious from the code, especially the default replacement order, transaction boundaries, and retention of components after soft deletion. Comments should explain why a rule exists without repeating straightforward statements. If an invariant requires more involved code, document the invariant beside that implementation.

## Acceptance Scenarios

These scenarios define the tests to add during the implementation phases:

1. Creating dashboards in two accounts keeps ownership and selection independent.
2. Creating dashboards for two engines in one account gives each engine its own default.
3. Creating the first dashboard with `default: false` still makes it the default.
4. Creating an additional dashboard preserves the existing default unless promotion is requested.
5. Promoting a dashboard changes only the previous default in the same account and engine.
6. Clearing the only default without a replacement fails without changing persisted data.
7. Deleting the default promotes the oldest remaining active dashboard, using `id` to break timestamp ties.
8. Deleting a non-default dashboard leaves the default unchanged.
9. Deleting the last dashboard leaves an empty state; subsequent reads do not create records.
10. Soft deletion preserves components while preventing direct access and mutation through the deleted parent.
11. Creating a dashboard after all previous ones were deleted establishes a new default.
12. Adding the same widget twice produces independently editable and removable instances.
13. Blank names fail validation; repeated nonblank names remain valid.
14. A failed creation, promotion, or deletion rolls back all changes in that operation.
15. Concurrent creation or promotion preserves exactly one active default per account and engine.
