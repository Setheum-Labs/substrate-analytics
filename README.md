## Substrate Analytics

\* to connect to substrate-analytics you must whitelist your IP address in `deployment.template.yml`

Comprises a websocket server accepting incoming telemetry from multiple
[Substrate](https://github.com/paritytech/substrate) nodes. substrate-analytics is designed to be resilient (to network errors),
performant and horizontally scalable by deploying more servers.

Telemetry is stored in a PostgreSQL database. Management of the database schema is via `diesel` migrations.

Stored data is purged from the DB according to `LOG_EXPIRY_H`

For convenience there are also some JSON endpoints to make ad-hoc queries, although it is expected that
the data is accessed directly from the database by a suitable dashboard (eg. Grafana).

#### Routes:

- **`/`**
  - incoming telemetry (with expiry as set by `LOG_EXPIRY_H`) (ws) - set with this option in substrate cli: `--telemetry-url 'ws://127.0.0.1:8080 5'`
- **`/audit`**
  - incoming telemetry with no expiry (ws) - set with this option in substrate cli: `--telemetry-url 'ws://127.0.0.1:8080/audit 5'`

JSON endpoints for convenience:
- **`/stats/db`**
  - stats for db showing table / index sizes on disk
- **`/nodes`**
  - list of logged nodes
- **`/nodes/log_stats?peer_id=Qmd5K38Yti1NStacv7fjJwsXDCUZcf1ioKcAuFkq88RKtx`**
  - shows the quantity of each type of log message received
- **`/nodes/logs?peer_id=Qmd5K38Yti1NStacv7fjJwsXDCUZcf1ioKcAuFkq88RKtx&limit=1&msg=tracing.profiling&target=pallet_babe&start_time=2020-03-25T13:17:09.008533`**
  - recent log messages. Required params: `peer_id`, Optional params: `msg, target, start_time, end_time, limit`
- **`/reputation/{peer_id}`**
  - reported reputation for `peer_id` from the POV of other nodes
- **`/reputation/logged`**
  - reported reputation for all peers from the POV of all logged (past/present) nodes
- **`/reputation`**
  - reported reputation for all peers unfiltered 
  (note that this can contain many entries that are not even part of the network)

`peer_counts` and `logs` routes take the following optional parameters (with sensible defaults if not specified):
- `start_time` in the format: `2019-01-01T00:00:00`
- `end_time` in the format: `2019-01-01T00:00:00`
- `limit` in the format: `100`

`reputation` routes take the following optional parameters (with sensible defaults if not specified):
- `max_age_s` in the format: `10`
- `limit` in the format: `100`

#### Monitoring

Substrate Analytics provides a `/metrics` endpoint for Prometheus.

### Set up for development and deployment

- (for development) create a `.env` file in project root containing: (eg)
    - `DATABASE_URL=postgres://username:password@localhost/substrate-analytics`
    - `PORT=8080`
- install [Diesel cli](https://github.com/diesel-rs/diesel/tree/master/diesel_cli)
- you might need [additional packages](https://github.com/diesel-rs/diesel/blob/master/guide_drafts/backend_installation.md)
- run `diesel database setup` to initialise DB
- after any changes to the schema via migrations, you must `diesel migration run`

Optionally specify the following environment variables:

- `HEARTBEAT_INTERVAL` (default: 5)
- `CLIENT_TIMEOUT_S` (default: 10)
- `PURGE_INTERVAL_S` (default: 600)
- `LOG_EXPIRY_H`  (default: 280320)
- `MAX_PENDING_CONNECTIONS` (default: 8192)
- `WS_MAX_PAYLOAD` (default: 524_288)
- `NUM_THREADS` (default: CPUs * 3)
- `DB_POOL_SIZE` (default: `NUM_THREADS`)
- `DB_BATCH_SIZE` (default: 1024) - batch size for insert
- `DB_SAVE_LATENCY_MS` (default: 100) - max latency (ms) for insert
- `CACHE_UPDATE_TIMEOUT_S` (default: 15) - seconds before timeout warning - aborts update after 4* timeout
- `CACHE_UPDATE_INTERVAL_MS` (default: 1000) - time interval (ms) between updates
- `CACHE_EXPIRY_S` (default: 3600) - expiry time (s) of log messages
- `ASSETS_PATH` (default: `./static`) - static files path

To allow logging you must set:

- `RUST_LOG` to some log level

Log messages are batched together before sending off to DB actor for `INSERT`
\- up to `DB_BATCH_SIZE` messages or `DB_SAVE_LATENCY_MS`, whichever is reached sooner.

#### Benchmarking

Substrate-analytics has endpoints to define benchmarks and host systems (that run the benchmarks). This is 
designed to be x-referenced with telemetry data to provide insights into the node and system under test.

JSON endpoints:

- **`/host_systems`**
  - `GET` to list all; `POST` to create new using the format (returns object with newly created `id`):
```json
{ 
   "cpu_clock":2600,
   "cpu_qty":4,
   "description":"Any notes to go here",
   "disk_info":"NVME",
   "os":"freebsd",
   "ram_mb":8192
}
```
- **`/benchmarks`**
  - `GET` to list all, `POST` to create new using the format (returns object with newly created `id`):
```json
{ 
   "benchmark_spec":{ 
      "tdb":"tbd"
   },
   "chain_spec":{ 
      "name":"Development",
      "etc": "more chain spec stuff"
   },
   "description":"notes",
   "host_system_id":2,
   "ts_end":"2019-10-28T14:05:27.618903",
   "ts_start":"1970-01-01T00:00:01"
}
```

