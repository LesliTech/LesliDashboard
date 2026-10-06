# Dashboard Components

LesliDashboard stores dashboards and their component configuration, renders components through their owning engine, and provides a set of general demonstration widgets.

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

Symbols use the defaults `size: 4`, `position: 1`, and `config: {}`. A hash supplies initial values for newly created component records.

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

Run `bin/rails lesli_dashboard:register` after adding a component. Registration creates missing records without overwriting a user's existing layout.
