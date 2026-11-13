# Dashboard Components

LesliDashboard stores dashboards and their component configuration, renders components through their owning engine, and provides a set of general demonstration widgets.

This page describes the current component integration. The [Dashboard Contract](/engines/dashboard/about/contract) defines the agreed management behavior to implement, including multiple dashboards, default selection, soft deletion, and independent instances of the same widget.

## Register Components in an Engine

An engine declares component names in a dashboard model:

```ruby
module MyEngine
  class Dashboard < Lesli::Shared::Dashboard
    COMPONENTS = [
      :summary,
      { activity: { size: 8, position: 2, config: { limit: 10 } } }
    ].freeze
  end
end
```

Symbols use `size: 4`, their one-based declaration position, and `config: {}`. A hash supplies initial values for newly created component records.

Each name requires a matching partial in the owning engine:

```text
app/views/my_engine/dashboards/_component-summary.html.erb
app/views/my_engine/dashboards/_component-activity.html.erb
```

The renderer converts underscores to dashes and passes the persisted record as the `component` local. Components stack on small screens and use their stored width on the twelve-column desktop grid.

## Built-in Demonstration Components

LesliDashboard registers:

| Component | View component |
| --- | --- |
| `count` | `LesliView::Widgets::Count` |
| `chart_bar` | Bar chart |
| `chart_line` | Line chart |
| `calendar` | Calendar widget |
| `date` | Date widget |
| `weather` | Weather widget |

Several built-in partials intentionally use demonstration values. Replace those values with account-scoped services before presenting them as production metrics. A domain engine should normally register its own components instead of modifying these examples.

## Component Requirements

A production component should define:

* Its account-scoped data source
* Supported values in `component.config`
* Empty and error states
* A useful default width and position
* Authorization requirements
* Rendering and service tests

Registration initializes new dashboards only. New widget definitions are available in the catalog without modifying existing layouts.

## Selecting a Dashboard

The engine entry point displays the current account's default for that engine. Use `?dashboard_id=123` to select another active dashboard belonging to the same account and engine. Missing, deleted, or out-of-scope identifiers return not found. Viewing the page does not create dashboards.

Components are ordered by `position`, then `id`. The shared presenter resolves their partials from the dashboard's owning engine and maps widths to the responsive grid. An absent dashboard or a dashboard without components displays the translated empty state.

## Widget Catalog

When a Core account is created, its LesliDashboard workspace automatically initializes dashboards and widgets from this catalog. Register custom providers during application initialization so they are available before SaaS account creation. Existing accounts can be initialized through the [maintenance task](/engines/dashboard/about/tasks).

`LesliDashboard::WidgetCatalog.widgets("MyEngine")` returns definitions with `identifier`, `name_key`, translated `name`, `partial`, and initial `options`. Only server-side declarations populate this catalog. Stored component instances reference an identifier; their IDs remain independent.

An engine may customize its declarations:

```ruby
COMPONENTS = [
    :summary,
    { activity: {
        name_key: "my_engine.widgets.activity",
        partial: "my_engine/dashboards/component-activity",
        size: 8,
        config: { limit: 10 }
    } }
].freeze
```

Names default to `<engine_namespace>.widgets.<identifier>`, with a humanized identifier when no translation exists. Partials default to `<engine_namespace>/dashboards/component-<identifier-with-dashes>`.

For a custom engine, register in its initializer or the host application's `config/initializers/dashboards.rb`:

```ruby
LesliDashboard::WidgetCatalog.register("MyEngine") do
    MyEngine::Dashboard::COMPONENTS
end
```

The block is evaluated when reading the catalog, so it resolves the current constants after Rails reloads. Registering the same engine again replaces its provider. No database writes happen during catalog registration. The shared presenter uses the catalog's partial path.

## Dashboard Management

The standard mount exposes management at `/dashboard/dashboards`. The **Manage dashboards** link in the shared header opens this list when the user can access it. Engine entry points such as `/support` continue to display their own default dashboard.

| Request | Operation |
| --- | --- |
| `GET /dashboard/dashboards` | List the current account's dashboards |
| `GET /dashboard/dashboards/new` | Show the creation form |
| `POST /dashboard/dashboards` | Create a dashboard |
| `GET /dashboard/dashboards/:id` | Show a selected dashboard and its widgets |
| `GET /dashboard/dashboards/:id/edit` | Show the edit form |
| `PATCH /dashboard/dashboards/:id` | Update the name or default selection |
| `DELETE /dashboard/dashboards/:id` | Soft-delete the dashboard and replace its default if needed |

Routes use the `managed_dashboards` helper prefix to preserve the existing singular `dashboard_path` helper. Submitted attributes use the `dashboard` parameter with `name`, `engine`, and `default`. The account comes from the authenticated user. Engines must be in the server catalog when creating a dashboard; updates accept only name and default selection.

The first active dashboard for an engine becomes its default automatically. To change the default, select another dashboard as default. Clearing the current default alone returns a validation error. A new dashboard starts empty; use **Edit widgets** to compose it.

HTML and Turbo mutations redirect with status 303 on success. JSON creation returns the dashboard with status 201; updates and deletion return status 200. Invalid forms return status 422, preserve submitted values, and expose validation errors. Missing or inaccessible records return 404.

When LesliShield is installed, the inherited authentication and authorization checks protect every action under `lesli_dashboard/dashboards`. Grant the required CRUD actions through the usual LesliShield role configuration. Existing installations must refresh their resource/action configuration to include the new routes. The standard preparation task rebuilds resources and synchronizes roles and privileges:

```shell
bin/rails lesli:db:prepare
```

Custom roles still need the appropriate action grants in LesliShield.

## Component Editor

Open **Edit widgets** from a dashboard's detail or edit page. The editor uses LesliView forms and buttons to add widget instances, change widths, move instances up or down, and remove them. Multiple instances of the same widget are independent. New instances append after the last position. Reordering runs transactionally and normalizes existing position ties. Moving beyond the first or last position is a no-op.

The endpoints are relative to the engine mount:

| Request | Operation |
| --- | --- |
| `GET /dashboards/:dashboard_id/components` | List instances and render the catalog/editor |
| `POST /dashboards/:dashboard_id/components` | Add the widget specified by `component[component]` |
| `PATCH /dashboards/:dashboard_id/components/:id` | Update `component[size]` and declared `component[config]` fields |
| `PATCH /dashboards/:dashboard_id/components/:id/move` | Move with `direction=up` or `direction=down` |
| `DELETE /dashboards/:dashboard_id/components/:id` | Remove one instance permanently |

Parents are resolved within the current account, then instances through that parent. Missing, deleted, foreign-account parents and components from another dashboard return 404. LesliShield authorizes the `index`, `create`, `update`, `move`, and `destroy` actions on `lesli_dashboard/components`. Refresh resource/role configuration after introducing these routes.

Turbo creation refreshes the list and resets the add form. Updates replace only the edited instance. Reordering and deletion refresh the list, including its empty state. Validation errors return 422 and preserve submitted values. HTML mutations redirect to the editor; JSON mutations return `{ component: ..., components: [...] }`, with status 201 for creation and 200 otherwise. JSON validation errors return `{ errors: ... }`.

### Editable Widget Options

Declare editable options in the widget's server-side `settings` map. Options omitted from this map cannot be changed through the editor, even when they are present in the initial `config`.

```ruby
COMPONENTS = [
    { summary: {
        config: { title: "Summary", limit: 10, compact: false, period: "week" },
        settings: {
            title: { type: :text, label_key: "my_engine.widgets.summary_title" },
            limit: { type: :integer },
            compact: { type: :boolean },
            period: { type: :select, choices: %w[week month] }
        }
    } }
].freeze
```

Supported controls are text, integer, checkbox, and select. Integers and booleans are converted to their JSON types; select values must match the declared string choices. Widget-specific business restrictions remain the responsibility of the widget. There is no arbitrary JSON editor.

Field labels default to `<engine>.widgets.<widget>_<setting>` and select labels to `<engine>.widgets.<widget>_<setting>_<value>`, with humanized fallbacks. The built-in calendar implements the `week_starts_on` option with `sunday` and `monday` choices. Widget partials consume saved configuration through the `component` local.

Components whose definitions were retired can still be resized, moved, or removed from the editor; no configuration fields are exposed for them.

### Navigation and empty states

The shared dashboard view lists other dashboards for the current account and engine when more than one is available. The selected dashboard is highlighted. Engine entry points such as `/support` preserve their path and select a dashboard through `dashboard_id`; management pages link to the corresponding managed dashboard.

An empty dashboard offers **Add widget**. When an engine has no dashboards, **Create dashboard** opens the form with that engine selected. These actions use LesliView buttons and the existing controller authorization. The responsive twelve-column grid and LesliView widgets remain unchanged.
