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
