# Installation

LesliDashboard provides persisted, account-scoped dashboards and the shared component renderer used by Lesli engines. It requires Lesli `~> 5.1.0`.

## Install and Mount

```shell
bundle add lesli_dashboard
```

The standard router mounts it at `/dashboard`:

```ruby
Rails.application.routes.draw do
  Lesli::Router.mount(self)
end
```

For a manual mount:

```ruby
Rails.application.routes.draw do
  mount LesliDashboard::Engine => "/dashboard"
end
```

Prepare the database and initialize installed engines:

```shell
bin/rails lesli:db:prepare
```

Register missing dashboard and component records for existing accounts:

```shell
bin/rails lesli_dashboard:register
```

## Verify the Installation

```shell
bin/rails routes -g dashboard
bin/rails server
```

Visit `http://127.0.0.1:3000/dashboard`. See [Dashboards](/engines/dashboard/about/dashboards) for the component contract and [Tasks](/engines/dashboard/about/tasks) for registration behavior.
