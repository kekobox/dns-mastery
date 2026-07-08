# SECTION 5 — TEACHER MANUAL, PART 5 (Level 8)
### Packet 7c — Architecture, HA, Anycast, GSLB, Monitoring, Migration, DR
Quiz numbering matches the Daily Calendar (TM 8 Q12–21).

---

# CHAPTER 8 (part 2) — ARCHITECTURE & SENIOR DESIGN

## TM 8.6 — Reference architectures

**Explanation.** The enterprise DNS estate, drawn once and defended forever:

```
INTERNET ──> [External authoritative pair/anycast]   public zones only,
                     ▲ (transfers, TSIG)              recursion off, RRL,
             [Hidden primary]  ── not in NS ──        often signed
                     ▼ (transfers, TSIG)
             [Internal authoritative estate]          internal zones,
                     ▲                                internal views of
INTERNAL ──> [Resolver tier(s)] ──> internet egress   public names, RFC1918
clients        │  (RPZ, logging, DoT to clients)      reverse
               ├─ static-stub → internal auths
               └─ conditional fwd → AD DCs (dynamic AD zones)
```
**Hidden primary:** the primary holds the pen (all edits/signing) but is
absent from NS — unreachable by resolvers, unadvertised to attackers;
secondaries are the serving face. Costs: NOTIFY must be explicit
(`also-notify`), monitoring must include the unlisted box, and the
pattern's guarantee is only as real as the NS set (T43).
**Resolver tiers:** site-local caches → central policy resolvers → egress.
Each tier adds cache locality and a policy point; each adds a cache layer
and a SERVFAIL-laundering hop (TM 3.7) — say both halves when defending
the design.
**EIP mapping:** smart architectures materialize exactly these patterns
(multi-primary, stealth/hidden primary, farm) — you design the picture,
the platform wires it.

**Quiz TM 8 Q12–16:**
12. Two benefits and two costs of a hidden primary.
13. Why does the external estate get RRL but the internal usually not?
14. Where do AD zones live in this picture and why?
15. What breaks if the resolver tier loses its static-stub routes to
    internal auths — and what do users report?
16. Defend two resolver tiers instead of one, then attack your own
    defense.

**Key:** 12. Benefits: edit/signing surface off the attack path,
serving capacity scales via secondaries. Costs: explicit notify wiring,
easy to leak into NS (T43), one more special box to monitor/DR.
13. External faces spoofed-UDP internet (amplification); internal
clients are known/routable — RRL there mostly punishes your own bursts.
14. On the DCs (AD-integrated, GSS-TSIG dynamic); resolvers route to
them via conditional-fwd/static-stub — replication and update semantics
are AD's, not yours. 15. Internal names SERVFAIL/NXDOMAIN while internet
names work — "half-blind" pattern (mirror of T18). 16. Defense: site-
local latency + survives WAN cuts + policy staging; attack: more caches
to go stale (T19/T28 class), more hops laundering rcodes, more fleet to
patch — the answer is monitoring + flush automation, not tier removal.

## TM 8.7 — HA: anycast vs VIP vs plain multi-NS

**Explanation.** Three availability idioms:
- **Multiple NS records** (authoritative HA): resolvers retry/select among
  NS; built into the protocol; convergence = resolver retry behavior
  (seconds). Cheap, global, mandatory baseline.
- **VIP/load-balancer** (resolver HA): one service IP, N nodes; instant
  failover, but N independent caches (T19), health-check design decides
  everything, and the LB is itself a failure domain.
- **Anycast:** same IP announced from multiple sites via routing;
  proximity + DDoS dilution + site-failure rerouting at BGP speed. Costs:
  per-instance divergence invisible to VIP-style checks (T28), routing
  flaps = mid-"session" instance changes (why DNS's one-shot UDP suits
  anycast, and long TCP less so), and troubleshooting needs instance
  identity (`hostname.bind`/`id.server` CH TXT, or your marker scheme).
**"The resolver IP responds" is not health** (Day 106's thesis): a ping
or even a canned query proves an instance is up, not that ITS answers are
correct or ITS zone view is current — health = correctness probes per
instance (next section).

## TM 8.8 — GSLB & the monitoring spec

**GSLB in one box:** DNS answers computed per query from health checks +
policy (geo, weight, failover). It's a control system publishing through
DNS: TTL becomes the failover-speed knob (low TTL = fast failover = high
query load and flap sensitivity — T36). Failure modes: check flapping →
answer oscillation; check network position ≠ user position → wrong
"health"; and every GSLB name is now only as available as the checker.

**The monitoring spec (Day 107 deliverable) — what to watch and why:**
1. **Per-instance answer correctness:** hot names resolved at each
   authoritative and each resolver INSTANCE, compared to intent
   (catches T12/T19/T28 before users).
2. **Serial spread:** SOA serial per secondary vs primary; alert on lag
   age (catches transfer rot).
3. **Refresh-failure age / expiry margin:** time since last successful
   refresh as a fraction of EXPIRE (the T23 countdown, alarmed early).
4. **SERVFAIL and NXDOMAIN rates** per resolver: leading indicators of
   upstream breakage, DNSSEC events, or a bad change (NXDOMAIN spike =
   deleted-but-alive name or client misconfig storm).
5. **Latency percentiles** per resolver, split cache-hit/miss if
   available.
6. **QPS + top-N names/clients:** capacity and anomaly (amplification,
   loops — T29/T33 show as rate signatures).
7. **RRSIG expiry margin** on signed zones; **DS/DNSKEY consistency**
   check (catches T30/T31 mechanically).
8. **Transfer/NOTIFY log error rates;** TSIG failure count (BADSIG/
   BADTIME = key or clock rot).
9. **Certificate-adjacent time health:** NTP offset on every DNS node.
10. **Config drift:** named-checkconf -z clean on every node, every day;
    L1-vs-L2 spot diffs on EIP-managed estates (T20/T47).

**Quiz TM 8 Q17–21:**
17. Why must monitoring query instances rather than the VIP/anycast
    address?
18. Which two metrics predict a T23 (expiry outage) days ahead?
19. What does an NXDOMAIN-rate spike after a change window suggest?
20. Why is TTL the central GSLB tradeoff?
21. Design the one probe that would have caught T12 within a minute.

**Key:** 17. The shared address hides per-node divergence — the exact
failure class (stale node/instance) you most need to see. 18. Refresh-
failure age and expiry margin (serial spread corroborates). 19. A
deleted name still in active use (blast radius missed) — or a client/
suffix misconfig storm; either way, investigate the top NXDOMAIN names.
20. Low TTL = fast failover but high load + oscillation sensitivity +
authority-availability inherited per query; high TTL = calm but slow
failover. 21. Per-authoritative-server probe of a canary record + SOA
serial comparison across all auths, alerting on divergence.

## TM 8.9 — Zone migration planning

**Explanation.** The gate-checklist doctrine (RB-24 operationalizes it):
**Phase 0 — inventory:** full export old estate; dependency sweep
(delegations in/out, CNAMEs crossing zones, MX/SRV targets); SOA/TTL
parameter diff old-vs-new templates (T45); consumers list.
**Phase 1 — ramp:** lower RECORD TTLs and, above all, **NS/glue TTLs**
(T26) at least one old-TTL before the window.
**Phase 2 — parallel-serve:** new estate loaded and serving identical
data (diff exports = byte-level gate); old estate still authoritative.
Verification from every universe (internal/external — T27).
**Phase 3 — pointer cutover:** parent NS/glue (and DS if signed —
signed-zone migrations must move/re-sign keys or go insecure-then-secure
deliberately; never strand a DS pointing at keys the new estate lacks)
switched to new estate. The clock that matters now: old NS TTL.
**Phase 4 — drain:** old estate KEEPS SERVING until pointer-TTL expiry +
margin; watch its query rate decay to zero — that graph IS the proof.
**Phase 5 — decommission:** old estate off; delegation hygiene (T42);
restore TTLs; post-migration parameter audit.
**No-going-back point:** DS/NS cutover once old-TTL has expired —
before that, rollback = flip pointers back; after, rollback = a new
migration. State it in the plan.

## TM 8.10 — DR: expiry math and the dead-primary playbook

**Explanation.** Your real RTO for "primary is gone" is written in the
SOA: secondaries serve until EXPIRE from their last refresh — that's the
window to (a) restore the primary, or (b) **promote**: pick a secondary,
convert to primary (its zone file is current to last transfer), re-point
transfer topology, re-wire notify, and — on EIP estates — re-materialize
the smart architecture accordingly. Signed zones add: the signing
capability (keys!) must survive the primary's death — keys stored only
on the dead box turn a serving problem into a re-signing crisis before
RRSIG expiry (a second, shorter clock). Drill artifacts (Day 109): your
measured RTO, the promote runbook in your words, and the two clocks
(EXPIRE, min RRSIG validity) computed for the lab estate.
**Decommission discipline** (RB-25): announce → liveness watch (query
logs at zero for the deprecation window) → remove data → **remove
delegation** (T42) → archive final export + journal.

## TM 8.11 — Platform mapping (BIND / EfficientIP / Infoblox / MS)

**Explanation.** The Day 110 table, seeded (extend with your [V]
findings):
| Concept | BIND | EfficientIP | Infoblox | Microsoft |
|---|---|---|---|---|
| Mgmt plane | files+rndc | SOLIDserver objects | Grid Master | AD/DNS mgr |
| Multi-server unit | primary/secondaries | smart architecture | Grid | AD replication |
| Metadata | comments | class parameters | extensible attrs | — |
| Dynamic updates | allow-update/policy | managed | managed | GSS-TSIG native |
| Hidden primary | NS-set discipline | stealth pattern | grid design | n/a typical |
| Audit | logs | object audit trail | audit log | AD/event logs |
| Underlying engine | named | BIND-based | BIND-derived | MS DNS |
The senior sentence: "Physics identical everywhere — zones, serials,
TTLs, transfers, the three layers of truth; platforms differ in nouns,
guardrails, and where the audit trail lives. I verify platform-specific
[V] facts on arrival instead of assuming."

---
**End of the Teacher Manual.** Remaining packets: oral exam pack,
flashcards, exams/capstones, expert handbook, mentor loop.
