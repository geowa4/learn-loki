autoscale: true
slidenumbers: true
slidecount: true
slide-dividers: #

# Automated Incident Response with Osquery and Loki

George Adams IV & Ed Welch

# Use Case

Detecting and alerting SSH connections.

^This is the end goal we'll build towards as we learn a little more along the way.

# Follow Along

[https://github.com/geowa4/learn-loki](https://github.com/geowa4/learn-loki)

# Osquery

## Released by Facebook in 2014

```plaintext
commit 73a32b729403b2f5a7c204b0f7cfb86fdfdd0a85
Author: mike@arpaia.co <mike@arpaia.co>
Date:   Wed Jul 30 17:35:19 2014 -0700

    Initial commit
```

# Osquery

## Works on my machine

![inline fill](media/windows_logo.png)![inline fill](media/apple_logo.png)![inline fill](media/tux_logo.png)

# Osquery

## SQL interface to your endpoints

```sql
.schema processes
```

```sql
CREATE TABLE processes(
  `pid` BIGINT, `name` TEXT, `path` TEXT, `cmdline` TEXT,
  `disk_bytes_read` BIGINT, `disk_bytes_written` BIGINT,
  ...
  PRIMARY KEY (`pid`)
) WITHOUT ROWID;
```

# Osquery

```sql
select max(disk_bytes_read), pid, name, cmdline, cwd from processes;
```

```plaintext
+----------------------+------+------+---------+---------------+
| max(disk_bytes_read) | pid  | name | cmdline | cwd           |
+----------------------+------+------+---------+---------------+
| 10465280             | 5478 | bash | -bash   | /vagrant/demo |
+----------------------+------+------+---------+---------------+
```

^Who remembers how the command to list what processes are listening on which ports?

# Osquery

```sql
select p.name, l.port, l.protocol
from processes p inner join listening_ports l on p.pid = l.pid
where p.name = 'VBoxHeadless' and l.port <> 0;
```

```plaintext
+--------------+------+----------+
| name         | port | protocol |
+--------------+------+----------+
| VBoxHeadless | 3000 | 6        |
| VBoxHeadless | 3100 | 6        |
| VBoxHeadless | 9080 | 6        |
| VBoxHeadless | 9090 | 6        |
| VBoxHeadless | 2222 | 6        |
+--------------+------+----------+
```

# Osquery

```sql
select c.name, p.port, p.host_port
from docker_containers c inner join docker_container_ports p
on c.id = p.id;
```

```plaintext
+--------------------+------+-----------+
| name               | port | host_port |
+--------------------+------+-----------+
| /demo_loki_1       | 80   | 0         |
| /demo_loki_1       | 3100 | 3100      |
| /demo_grafana_1    | 3000 | 3000      |
| /demo_prometheus_1 | 9090 | 9090      |
| /demo_promtail_1   | 9080 | 9080      |
+--------------------+------+-----------+
```

# Osquery

```sql
.schema last
```

```sql
CREATE TABLE last(
  `username` TEXT, `time` INTEGER, `host` TEXT,
  `pid` INTEGER, `tty` TEXT, `type` INTEGER
);
```

# Osquery

```sql
select * from last;
```

```plaintext
+----------+-------+------+------+------------+-------------------+
| username | tty   | pid  | type | time       | host              |
+----------+-------+------+------+------------+-------------------+
| reboot   | ~     | 0    | 2    | 1566866107 | 4.15.0-52-generic |
| runlevel | ~     | 53   | 1    | 1566866118 | 4.15.0-52-generic |
|          | ttyS0 | 859  | 5    | 1566866119 |                   |
| LOGIN    | ttyS0 | 859  | 6    | 1566866119 |                   |
|          | tty1  | 879  | 5    | 1566866119 |                   |
| LOGIN    | tty1  | 879  | 6    | 1566866119 |                   |
| vagrant  | pts/0 | 5396 | 7    | 1566869034 | 10.0.2.2          |
| vagrant  | pts/1 | 6465 | 7    | 1566870878 | 10.0.2.2          |
|          | pts/1 | 6465 | 8    | 1566870880 |                   |
| vagrant  | pts/1 | 6571 | 7    | 1566870886 | 10.0.2.2          |
|          | pts/1 | 6571 | 8    | 1566870910 |                   |
+----------+-------+------+------+------------+-------------------+
```

# Osquery - Packs

```json
{
  "queries": {
    "last": {
      "query": "select * from last;",
      "interval": "60",
      "platform": "posix",
      "version": "1.4.5",
      "description": "..."
    }
  }
}
```

# Osquery - Decorators

```json
{
  "decorators": {
    "load": [
      "SELECT uuid AS host_uuid FROM system_info;",
      "SELECT user AS username FROM logged_in_users ORDER BY time DESC LIMIT 1;"
    ]
  }
}
```

^Decorator results are added to pack results.
If you're on AWS, you can add a query for your EC2's tags.

# Osquery - Results

`/var/log/osquery/osqueryd.results.log`

```json
{
  "name": "pack_incident-response_last",
  "hostIdentifier": "ubuntu-bionic",
  "calendarTime": "Tue Aug 27 01:55:13 2019 UTC",
  "decorations": {
    "host_uuid": "2401CCE9-23EA-4D4D-8C84-D5C8437EBE15",
    "username": "vagrant"
  },
  "columns": {
    "host": "10.0.2.2",
    "pid": "6465",
    "time": "1566870878",
    "tty": "pts/1",
    "type": "7",
    "username": "vagrant"
  },
  "action": "added"
}
```

# Osquery - Recap

It's been around a while

Cross-platform

It's just SQL

Schedule queries with "packs"

# Loki

Cloud-native log aggregation

Made by Grafana

# Loki

> Prometheus-inspired logging for cloud natives.

^To know what this means, let's take a quick detour to Prometheus.

# Prometheus

Metrics collection via "pull"

Time-series data store

Queryable via PromQL

# Prometheus - Push vs. Pull

^TODO: diagram push vs pull

# Prometheus - Scraping

```yaml
scrape_configs:
  - job_name: "promtail"
    static_configs:
      - targets:
          - promtail:9080
```

# Prometheus - Data Structure

Metrics have labels in addition to values.

```plaintext
rss_enjoyment{track="tech", talk="osquery_loki"} 11
```

# Loki - Data Structure

Log entries have labels, too.

```plaintext
{track="tech", talk="osquery_loki"} "best talk ever"
{track="tech", talk="osquery_loki"} "i want to know more"
{track="tech", talk="osquery_loki"} "i hear that one guy runs rocdev"
```

# Loki - Labels

The matching labels allow us to switch back and forth freely.

# Loki - Query

LogQL

```bash
$ logcli query --tail '{name="pack_incident-response_last"}'
2019-08-29T03:01:37Z
{filename="/var/log/osquery/osqueryd.results.log", job="osquery_results", name="pack_incident-response_last"}
{
  "name":"pack_incident-response_last",
  "hostIdentifier":"ubuntu-bionic",
  "calendarTime":"Thu Aug 29 03:01:37 2019 UTC",
  "unixTime":1567047697,
  "epoch":0,
  "counter":115,
  "decorations":{"host_uuid":"661449FD-E11A-462B-9EA9-63A3EE8F9BDC","username":"vagrant"},
  "columns":{"host":"10.0.2.2","pid":"7404","time":"1567047680","tty":"pts/1","type":"7","username":"vagrant"},
  "action":"added"
}
```

^This is why Loki is like Prometheus.
We read from them the same way with the same labels.
But there's one more link with Prometheus and Loki: metrics extraction.

# Loki - Collection

Promtail

^We've seen how Osquery generates logs.
We've seen how to read logs.
But how did they get there?

# Promtail

Forwards logs
_and_
Extracts metrics

# Promtail - Scraping

```yaml
clients:
  - url: http://loki:3100/api/prom/push
scrape_configs:
  - job_name: osquery
    static_configs:
      - targets:
          - localhost
        labels:
          job: osquery_results
          __path__: /var/log/osquery/osqueryd.results.log
```

^Anything Osquery reports will be forwarded to Loki

# Promtail - Result Reminder

```json
{
  "name": "pack_incident-response_last",
  "hostIdentifier": "ubuntu-bionic",
  "calendarTime": "Thu Aug 29 03:01:37 2019 UTC",
  "unixTime": 1567047697,
  "epoch": 0,
  "counter": 115,
  "decorations": {
    "host_uuid": "661449FD-E11A-462B-9EA9-63A3EE8F9BDC",
    "username": "vagrant"
  },
  "columns": {
    "host": "10.0.2.2",
    "pid": "7404",
    "time": "1567047680",
    "tty": "pts/1",
    "type": "7",
    "username": "vagrant"
  },
  "action": "added"
}
```

# Promtail - Pipelines

```yaml
pipeline_stages:
  - json:
      expressions:
        timestamp: unixTime
        ip: columns.host
        name: name
        username: columns.username
  - timestamp:
      source: timestamp
      format: Unix
  - labels:
      name: name
```

# Promtail - Metrics

```yaml
pipeline_stages:
  - ...
  - metrics:
      last_logins:
        type: Counter
        description: count last logins
        source: name
        config:
          value: pack_incident-response_last
          action: inc
```

# Promtail - Prometheus

```yaml
scrape_configs:
  - job_name: "promtail"
    static_configs:
      - targets:
          - promtail:9080
```

# Where we are now

Osquery producing results

Promtail forwarding to Loki

Query and tail logs in Loki

Promtail extracting metrics

Prometheus scraping Promtail

# What's left

Charting & alerting

# Grafana

Supports both Promtheus and Loki as data sources

# Grafana - Loki

![inline](media/loki.png)

# Grafana - Prometheus

![inline](media/prometheus.png)

# Grafana - Alerting

![inline](media/alert.png)

# Putting it all together

^TODO: diagram all the components
