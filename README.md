# Learn Loki

```bash
vagrant up
vagrant ssh
cd /vagrant/demo
./start.sh
```

With everything running, you can navigate to Grafana on your host at [localhost:3000](http://localhost:3000).
Use "admin" as both the username and password.
Once authenticated, check out the "Demo" dashboard and "Explore" section.
The dashboard shows the increases in SSH logins over an interval.
To make it move, run `vagrant ssh` a few times.

Prometheus, Loki, and Promtail are exposed as well at ports 9090, 3100, and 9080, respectively.

## Play Around

Run `osqueryi` and try these.

```sql
select p.pid, p.name, l.port from processes p inner join listening_ports l on p.pid = l.pid where l.port <> 0;

select c.name, p.port, p.host_port from docker_containers c inner join docker_container_ports p on c.id = p.id order by c.name;

select name, source, base_uri from apt_sources;

select name, description, value from osquery_flags where default_value <> value;

select valid_from, valid_to from curl_certificate where hostname = 'rocdev.org';

select path, md5 from hash where path = '/home/vagrant/.ssh/authorized_keys';

select f.path, f.mtime, h.md5 from hash h inner join file f where h.path = '/home/vagrant/.ssh/authorized_keys' and f.path = '/home/vagrant/.ssh/authorized_keys';
```

To query Loki on the command line, use `logcli`.

```bash
logcli --addr='http://localhost:3100' query '{name="pack_incident-response_last"}'

logcli --addr='http://localhost:3100' query '{name=~"pack_incident-response.*"}'

logcli --addr='http://localhost:3100' query '{name=~"pack_incident-response.*"} |= "last"'

# if useing a newer version than the original presentation used.
logcli --addr='http://localhost:3100' query 'increase({name="pack_incident-response_last"}[5m])'
```
