# AsyncTaskDemo

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

To check API documentation and create task, run:
```
$ curl http://localhost:4000/api/openapi | jq
```
Task type, priority, max attempts and data to execute task can be defined in payload
Check required and optional parameters with open api specification

```
url -X POST http://localhost:4000/api/users -H "Content-Type: application/json" -d '{"max_attempts": 10, "type": "finances", "priority": "high", "data": {}}'
```

**Storage**

Postgres is used a a persistent storage for tasks 

**Workers**

Concurrently executing tasks per queue
In `config.exs` paralel processes to execute tasks by prioary can be configured

Queues based on priority and anuber in config defined how many GenServers is created for priority

For example, 
```
config :async_task_demo,
  priority_queues: [
      high: 4,
      normal: 2,
      low: 1
  ]
```

**Important**

DB pool size should be bigger than sum of workers for each queue (4 + 2 + 1) in this case
Otherwise genserver workers can fail because of lack of db connections

GenServer module thant handles tasks is `AsyncTaskDemo.Workers.Worker`

defines that 4 GenServer with names `high_1`, `high_2`, `high_3`, `high_4` handle tasks with high priority, 2 GenServers with names `normal_1`, `normal_2` handle tasks with normal priority and only 1 GenServer named `low_1` handles tasks with low  priority

When new task is created, corresponding by priority worker is notified
Also, workers check every `timeout_milliseconds` for a new task or task to retry

**Retry**

```
config :async_task_demo,
  max_attempts: 5,
  timeout_milliseconds: 1000,

```

Value `timeout_milliseconds` defines how many milliseconds between retries apllication should wait if task execution failed

By default, tasks rerty number is 5; when task created, any `non_neg_integer` such as `1` or `1000000` can be defined (check api documentaton)

**Local testing of queue execution with dev env**

To fill data in psql, run: 
```
INSERT INTO tasks (priority, type, data, inserted_at, updated_at) select 1, 'report', '{}', now(), now() from generate_series(1,1000000);
INSERT 0 1000000
```

In another console tab, run
```
mix phx.server
```

Check code specifications (credo, dialyxir):
```
mix quality
```

Test coverage
```
MIX_ENV=test mix coveralls
```

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
