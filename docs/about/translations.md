# Translations

LesliDashboard stores its labels below the `lesli_dashboard` namespace. It ships English, Spanish, French, Italian, and Portuguese locale files.

The current files define time-based greetings:

```yaml
en:
  lesli_dashboard:
    greetings:
      morning: "Good morning"
      afternoon: "Good afternoon"
      evening: "Good evening"
```

Use the complete key and select the final segment in application code:

```ruby
I18n.t("lesli_dashboard.greetings.morning")
```

New labels should remain inside a stable feature bucket such as `greetings`, `components`, or `shared`. Add matching keys to every supported locale and preserve interpolation variables.

When LesliBabel is installed:

```shell
bin/rails lesli_babel:scan
bin/rails lesli_babel:import
```

Review any deployed file changes before committing them. The locale files in LesliDashboard are the source distributed with the gem.
