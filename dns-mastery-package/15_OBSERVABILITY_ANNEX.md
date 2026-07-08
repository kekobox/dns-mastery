# SECTION 17 (ADDENDUM A) — LAB OBSERVABILITY ANNEX
### Wiring the Day 107 monitoring spec into your existing Prometheus/Grafana stack

**Why this exists:** file 04 Part 5 (TM 8.8) tells you WHAT to monitor;
this annex makes it real against the lab — and doubles as a working
prototype for **Module A of your Telenor observability proposal** (same
exporters, same probe patterns, production-transferable).

**Integration choice:** you already run Prometheus + Grafana + Blackbox
via Docker Compose (kekobox/home-monitoring). Preferred path: add the
DNS jobs to THAT stack and attach it to the `dnslab` network
(`docker network connect dnslab <prometheus-container>`), rather than
running a second Prometheus. Standalone snippets are included anyway.

---

## 1. ENABLE BIND STATISTICS (per monitored instance)

Add to `options { }` — start with resolver1 and auth1:
```
statistics-channels { inet 0.0.0.0 port 8053 allow { 172.20.0.0/16; }; };
zone-statistics yes;        // per-zone counters (options or per-zone)
```
Reload, then verify from any lab container:
`curl -s http://172.20.0.53:8053/ | head` → XML stats = channel live.

## 2. bind_exporter SIDECARS

One exporter per BIND instance (compose additions):
```yaml
  bindexp-resolver1:
    image: prometheuscommunity/bind-exporter:latest
    container_name: bindexp-resolver1
    command:
      - --bind.stats-url=http://172.20.0.53:8053/
      - --bind.stats-groups=server,view,tasks
    networks: { dnslab: { ipv4_address: 172.20.0.153 } }
  bindexp-auth1:
    image: prometheuscommunity/bind-exporter:latest
    container_name: bindexp-auth1
    command: [ "--bind.stats-url=http://172.20.0.10:8053/",
               "--bind.stats-groups=server,view,tasks" ]
    networks: { dnslab: { ipv4_address: 172.20.0.110 } }
```
Verify: `curl -s http://172.20.0.153:9119/metrics | grep ^bind_up` → `bind_up 1`.

**Honesty note (errata protocol applies):** metric names below are the
commonly used bind_exporter families; on first run, browse `/metrics`
yourself and correct any name drift in this file — that correction is
your first errata-log entry exercise.

Key families → Day 107 spec mapping:
| Metric family | Spec item |
|---|---|
| `bind_up` | instance liveness (necessary, insufficient — Q135) |
| `bind_incoming_queries_total{type}` | QPS + query-mix (item 6) |
| `bind_responses_total{result}` / query error counters | SERVFAIL & NXDOMAIN rates (item 4) |
| `bind_zone_transfer_success_total` / `_failure_total` / `_rejected_total` | transfer health (item 8) |
| `bind_recursive_clients` | resolver pressure/saturation |
| `bind_query_duration_seconds*` (where exposed) | latency percentiles (item 5) |

## 3. WHAT THE EXPORTER CANNOT SEE — THE SOA SWEEP

Serial spread, refresh age, and expiry margin (spec items 2–3, the T12/
T23 catchers) are estate-level facts, not per-daemon counters. Cheapest
honest implementation — a cron writing node_exporter textfile metrics
(this is monitoring plumbing, not the deferred automation toolkit):
```bash
#!/bin/bash  # soa-sweep.sh — run per zone, e.g. every 60s via cron
ZONE=corp.example; OUT=/var/lib/node_exporter/textfile/dns_serials.prom
{ for S in 172.20.0.10 172.20.0.11; do
    SER=$(dig +short SOA $ZONE @$S | awk '{print $3}')
    echo "dns_zone_serial{zone=\"$ZONE\",server=\"$S\"} ${SER:-0}"
  done; } > $OUT.tmp && mv $OUT.tmp $OUT
```
Spread alert then becomes: `max(dns_zone_serial{zone="corp.example"})
- min(dns_zone_serial{zone="corp.example"}) > 0 for 15m`.
(Serial-arithmetic caveat from Q25 applies to fancy math; for
monitoring, "unequal for 15 minutes" is the operationally honest test.)

## 4. BLACKBOX DNS PROBES — PER-INSTANCE CORRECTNESS (spec item 1)

You already run blackbox_exporter. Add DNS modules (blackbox.yml):
```yaml
modules:
  dns_corp_app1_udp:
    prober: dns
    dns:
      query_name: "app1.corp.example"
      query_type: "A"
      valid_rcodes: ["NOERROR"]
      validate_answer_rrs:
        fail_if_not_matches_regexp: ["app1\\.corp\\.example\\.\\t.*\\tA\\t10\\.10\\.20\\.15"]
  dns_corp_soa_tcp:
    prober: dns
    dns: { query_name: "corp.example", query_type: "SOA",
           transport_protocol: "tcp", valid_rcodes: ["NOERROR"] }
```
Prometheus job — the crucial pattern: **target every node/instance
directly, never a VIP** (Q135/T19/T28 doctrine):
```yaml
- job_name: dns_probes
  metrics_path: /probe
  params: { module: [dns_corp_app1_udp] }
  static_configs:
    - targets: ["172.20.0.53:53","172.20.0.10:53","172.20.0.11:53"]
  relabel_configs:
    - { source_labels: [__address__], target_label: __param_target }
    - { source_labels: [__param_target], target_label: instance }
    - { target_label: __address__, replacement: "blackbox:9115" }
```
The TCP-SOA module doubles as your standing "TCP 53 works" canary —
T16's whole class, alarmed before users notice.

## 5. SCRAPE CONFIG (exporters)

```yaml
- job_name: bind
  static_configs:
    - targets: ["172.20.0.153:9119"]
      labels: { role: resolver, node: resolver1 }
    - targets: ["172.20.0.110:9119"]
      labels: { role: auth, node: auth1 }
```

## 6. THE DASHBOARD — SIX PANELS (build by hand; hand-building IS the lesson)

1. **QPS by type, per node** — `rate(bind_incoming_queries_total[5m])`.
2. **SERVFAIL & NXDOMAIN rate** — `rate(...{result=~"SERVFAIL"}[5m])`
   and NXDOMAIN equivalent; annotate change windows and watch T-class
   signatures appear (the Q110 alarm, visualized).
3. **Serial spread** — the textfile metric, `max-min` per zone; single
   stat + history.
4. **Transfer success/failure** — `increase(bind_zone_transfer_failure_total[1h])`.
5. **Probe matrix** — `probe_success` by instance × module (the
   per-instance correctness wall; one red cell = T19/T28 before users).
6. **Probe latency** — `probe_duration_seconds` heatmap (the T15
   timeout-quantum becomes visible as a band).

## 7. STARTER ALERT RULES

```yaml
- alert: DNSInstanceAnswerWrongOrDown
  expr: probe_success == 0
  for: 3m
- alert: DNSServfailSpike
  expr: rate(bind_responses_total{result=~"(?i)servfail"}[5m]) > 1
  for: 5m
- alert: ZoneSerialSpread
  expr: (max by(zone)(dns_zone_serial) - min by(zone)(dns_zone_serial)) > 0
  for: 15m
- alert: ZoneTransferFailures
  expr: increase(bind_zone_transfer_failure_total[30m]) > 0
- alert: BindDown
  expr: bind_up == 0
  for: 2m
```
Deliberately missing (add as exercises once the estate exposes them):
RRSIG-margin (Week 15 — probe with a `validate_answer` DNSSEC module or
a delv cron), refresh-age-vs-expire (extend the sweep script with the
refresh timestamp from `rndc zonestatus`).

## 8. CALENDAR HOOKS

Build §1–5 during **Week 6 spare time / Day 41 retro**; panels 1–4 by
**Day 63**; probes matrix before **Week 12** (so the incident capstones
fire your own alerts — diagnosing WITH your dashboard is the point);
alert rules reviewed against every ticket you solve from then on ("would
my rules have caught this?" becomes a standing journal question).

## 9. TELENOR MODULE A BRIDGE

Everything above transposes: bind_exporter → the estate's BIND/EIP-
managed servers (statistics-channels is the same knob), blackbox
per-instance probes → the anycast/VIP resolver farms (the T28 detector),
the SOA sweep → serial-spread across the ~189-device estate's DNS tier,
and the six panels → the Grafana folder in your proposal. Keep the lab
dashboard JSON export in `proofs/` — it's a demo asset for the proposal
meeting, built on evidence.
