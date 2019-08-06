# Learn Loki

```bash
vagrant up
vagrant ssh
cd /vagrant/demo
./start.sh
```

With everything running, you can navigate to Grafana on your host at [localhost:3000](localhost:3000).
Use "admin" as both the username and password.
Once authenticated, check out the "Demo" dashboard and "Explore" section.

Prometheus, Loki, and Promtail are exposed as well at ports 9090, 3100, and 9080, respectively.
