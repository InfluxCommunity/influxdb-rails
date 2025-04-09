> :warning: You are looking at the README of an unmaintained development branch
> of this gem. If you are using this gem you should have a look at the
> latest [released version (1.0.3)](https://github.com/InfluxCommunity/influxdb-rails/tree/v1.0.3#readme)
> instead.

# influxdb-rails

[![Gem Version](https://badge.fury.io/rb/influxdb-rails.svg)](https://badge.fury.io/rb/influxdb-rails)
[![Build Status](https://github.com/influxdata/influxdb-rails/actions/workflows/spec.yml/badge.svg)](https://github.com/influxdata/influxdb-rails/actions)

Automatically instrument your Ruby on Rails applications and write the metrics directly into
[InfluxDB](https://www.influxdata.com/).

## Table of contents

- [Installation](#installation)
- [Usage](#installation)
- [Configuration](#configuration)
- [Demo](#demo)
- [FAQ](#frequently-asked-questions)
- [Contributing](#contributing)

## Installation

Add the gem to your `Gemfile`:

```console
echo 'gem "influxdb-rails"' >> Gemfile
bundle install
```

To get things set up, create an initializer:

```console
bundle exec rails generate influxdb
```

This creates a file `config/initializers/influxdb_rails.rb`, which allows
configuration of this gem.

## Usage

Out of the box, you'll automatically get reporting for the Ruby on Rails components mentioned
below.

### Action Controller

Reported ActiveSupport instrumentation hooks:

- [start\_processing.action\_controller](https://guides.rubyonrails.org/active_support_instrumentation.html#start-processing-action-controller)
- [process\_action.action\_controller](https://guides.rubyonrails.org/active_support_instrumentation.html#process-action-action-controller)

Reported fields:

```ruby
  controller: 48.467,
  view: 46.848,
  db: 0.157,
  started: 1465839830100400200,
  request_id: "d5bf620b-3494-425b-b7e1-4953597ea744"
```

Reported tags:

```ruby
{
  hook:        "process_action",
  server:      Socket.gethostname,
  app_name:    configuration.application_name,
  method:      "PostsController#index",
  http_method: "GET",
  format:      "html",
  status:      ["500"],
  exception:   "ArgumentError"
}
```

### Action View

Reported ActiveSupport instrumentation hooks:

- [render\_template.action\_view](https://guides.rubyonrails.org/active_support_instrumentation.html#render-template-action-view)
- [render\_partial.action\_view](https://guides.rubyonrails.org/active_support_instrumentation.html#render-partial-action-view)
- [render\_collection.action\_view](https://guides.rubyonrails.org/active_support_instrumentation.html#render-collection-action-view)

Reported fields:

```ruby
  value: 48.467,
  count: 3,
  cache_hits: 0,
  request_id: "d5bf620b-3494-425b-b7e1-4953597ea744"
```

Reported tags:

```ruby
  hook:       ["render_template", "render_partial", "render_collection"],
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "PostsController#index",
  filename:   "/some/file/action.html"
```

### Active Record

Reported ActiveSupport instrumentation hooks:

- [sql.active\_record](https://guides.rubyonrails.org/active_support_instrumentation.html#sql-active-record)
- [instantiation.active\_record](https://guides.rubyonrails.org/active_support_instrumentation.html#instantiation-active-record)

Reported fields:

```ruby
  sql: "SELECT \"posts\".* FROM \"posts\"",
  request_id: "d5bf620b-3494-425b-b7e1-4953597ea744"
```

Reported SQL tags:

```ruby
  hook:       "sql",
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "PostsController#index",
  operation:  "SELECT",
  class_name: "POST",
  name:       "Post Load"
```

Reported instantiation values:

```ruby
  record_count: 1,
  request_id:   "d5bf620b-3494-425b-b7e1-4953597ea744"
  value:        7.689
```

Reported instantiation tags:

```ruby
  hook:       "instantiation",
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "PostsController#index",
  class_name: "POST"
```

### Active Job

Reported ActiveSupport instrumentation hooks:

- [enqueue.active\_job](https://guides.rubyonrails.org/active_support_instrumentation.html#enqueue-active-job)
- [perform.active\_job](https://guides.rubyonrails.org/active_support_instrumentation.html#perform-active-job)

Reported fields:

```ruby
  value: 89.467
```

Reported tags:

```ruby
  hook:       ["enqueue", "perform"],
  state:      ["queued", "succeeded", "failed"],
  job:        "SomeJobClassName",
  queue:      "queue_name"
```

*Note*: Only the measurements with the hook `perform` report a duration in the value.
The enqueue hook is a counter and always reports a value of `1`.

### Action Mailer

Reported ActiveSupport instrumentation hooks:

- [deliver.action\_mailer](https://guides.rubyonrails.org/active_support_instrumentation.html#deliver-action-mailer)

Reported fields:

```ruby
  value: 1
```

Reported tags:

```ruby
  hook:               "deliver",
  mailer:             "SomeMailerClassName"
```

*Note*: The hook is just a counter and always report a value of `1`.

## Configuration

The only settings you actually need to configure are the organization, bucket and access token.

```ruby
InfluxDB::Rails.configure do |config|
  config.client.org = "org"
  config.client.bucket = "bucket"
  config.client.token = "token"
end
```

You'll find all of the configuration settings in the initializer file.

### Custom Tags

You can modify the tags sent to InfluxDB by defining a middleware, which
receives the current tag set as argument and returns a hash in the same
form. The middleware can be any object, as long it responds to `#call`
(like a `Proc`):

```ruby
InfluxDB::Rails.configure do |config|
  config.tags_middleware = lambda do |tags|
    tags.merge(env: Rails.env)
  end
end
```

The `tags` argument is a Hash (mapping Symbol keys to String values). The
actual keys and values depend on the series name (`tags[:series]`, see
next section).

If you want to add dynamically tags or fields *per request*, you can access
`InfluxDB::Rails.current` to do so. For instance, you could add the current
user as tag or redis query time to every data point:

```ruby
class ApplicationController
  before_action :set_influx_data

  def set_influx_data
    InfluxDB::Rails.current.tags = { user: current_user.id }
    InfluxDB::Rails.current.fields = { redis_value: redis_value }
  end
end
```

### Block Instrumentation
If you want to add custom instrumentation, you can wrap any code into a block instrumentation

```ruby
InfluxDB::Rails.instrument "expensive_operation", tags: { }, fields: { } do
  expensive_operation
end
```

Reported tags:

```ruby
  hook:       "block_instrumentation",
  server:     Socket.gethostname,
  app_name:   configuration.application_name,
  location:   "PostsController#index",
  name:       "expensive_operation"
```

Reported fields:
```ruby
  value: 100 # execution time of the block in ms
```

You can also overwrite the `value`

```ruby
InfluxDB::Rails.instrument "user_count", fields: { value: 1 } do
  User.create(name: 'mickey', surname: 'mouse')
end
```

or call it even without a block

```ruby
InfluxDB::Rails.instrument "temperature", fields: { value: 25 }
```

### Custom client configuration

The settings named `config.client.*` are used to construct an `InfluxDB::Client`
instance, which is used internally to transmit the reporting data points
to your InfluxDB server. You can access this client as well, and perform
arbitrary operations on your data:

```ruby
InfluxDB::Rails.write_api.write(
  name: "events",
  tags:   { url: "/foo", user_id: current_user.id, location: InfluxDB::Rails.current.location },
  fields: { value: 0 }
)
```

If you do that, it might be useful to add the current context to these custom
data points which can get accessed with `InfluxDB::Rails.current.location`.

See [influxdb-client](https://github.com/influxdata/influxdb-client-ruby) for a
full list of configuration options and detailed usage.

### Disabling hooks

If you are not interested in certain reports you can disable them in the configuration.

```ruby
InfluxDB::Rails.configure do |config|
  config.ignored_hooks = ['sql.active_record', 'render_template.action_view']
end
```

## Demo
Want to see this in action? Check out our [sample dashboard](https://github.com/influxdata/influxdb-rails/tree/master/sample-dashboard).

## Frequently Asked Questions

### I'm seeing far less requests recorded in InfluxDB than my logs suggest.

By default, this gem writes data points with *millisecond time precision*
to the InfluxDB server. If you have more than 1000 requests/second (and/or
multiple parallel requests), **only the last** data point (within the
same tag set) is stored. See [InfluxDB server docs][duplicate-points] for
further details.

To work around this limitation, set the `config.client.time_precision`
to one of `"us"` (microseconds, 1·10<sup>-6</sup>s) or `"ns"` (nanoseconds,
1·10<sup>-9</sup>s).

Please note: This will only ever reduce the likelihood of data points
overwriting each other, but not eliminate it completely.

[duplicate-points]: https://docs.influxdata.com/influxdb/v1.4/troubleshooting/frequently-asked-questions/#how-does-influxdb-handle-duplicate-points


### How does the measurement influence the response time?

This gem subscribes to various `ActiveSupport::Notifications` hooks.
(cf. [guide][arn-guide] · [docs][arn-docs] · [impl][arn-impl]). The
controller notifications are run *after* a controller action has finished,
and should not impact the response time.

Other notification hooks (rendering and SQL queries) run *inline* in the
request processing. The amount of overhead introduced should be negligible,
though. However reporting of SQL queries relies on Ruby string parsing which
might cause performance issues on traffic intensive applications. Disable it in
the configuration if you are not willing to tolerate this.

By default, this gem performs writes to InfluxDB asynchronously. A single
hook usually only performs some time delta calculations, and then enqueues
the data point into a worker queue (which is processed by a background
thread).

If you, however, use a synchronous client (`config.client.async = false`),
the data points are immediately sent to the InfluxDB server. Depending on
the network link, this might cause the HTTP thread to block a lot longer.

[arn-guide]: http://guides.rubyonrails.org/v5.1/active_support_instrumentation.html#process-action-action-controller
[arn-docs]: http://api.rubyonrails.org/v5.1/classes/ActiveSupport/Notifications.html
[arn-impl]: https://github.com/rails/rails/blob/5-1-stable/actionpack/lib/action_controller/metal/instrumentation.rb#L30-L38

### How does this gem handle an unreachable InfluxDB server?

By default, the InfluxDB client will retry indefinitely, until a write
succeeds (see [client docs][] for details). This has two important
implications, depending on the value of `config.client.async`:

- if the client runs asynchronously (i.e. in a separate thread), the queue
  might fill up with hundreds of megabytes of data points
- if the client runs synchronously (i.e. inline in the request/response
  cycle), it might block all available request threads

In both cases, your application server might become unresponsive and needs
to be restarted.

If you setup a maximum retry value (`Integer === config.client.retry`),
the client will try up to that amount of times to send the data to the server
and (on final error) log an error and discard the values.

[client docs]: https://github.com/influxdata/influxdb-ruby#retry

### What happens, when the InfluxDB client or this gem throws an exception? Will the user see 500 errors?

No. The controller instrumentation is wrapped in a `rescue StandardError`
clause, i.e. this gem will only write the error to the `client.logger`
(`Rails.logger` by default) and not disturb the user experience.

### What happens with unwritten points, when the application restarts?

The data points are simply discarded.

## Contributing

- Fork this repository on GitHub
- Make your changes
  - Add tests.
  - Add an entry in the `CHANGELOG.md` in the "unreleased" section on top.
- Run the tests:
  - Either run them manually:

    ```console
    rake test:all
    ```

  - or wait for [our CI](https://github.com/influxdata/influxdb-rails/actions) to pick up your changes, *after*
    you made a pull request.
- Send a pull request.
- If your changes are looking good, we'll merge them.

### Testing Tasks

```console
rake            # unit tests + Rubocop linting
rake spec       # only unit tests
rake rubocop    # only Rubocop linter
rake test:all   # integration tests with various Rails version
```
