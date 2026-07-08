# SECTION 11 — TROUBLESHOOTING TICKET SIMULATOR, PART 2 (Tickets 26–50)
### Packet 7a — Senior difficulty. Same protocol and scoring as Part 1.

Senior tickets add: multi-cause composites, process failures behind technical
symptoms, and the expectation that your "customer answer" includes the
systemic fix, not just the repair.

---

### T26 — Migration cutover that "worked in testing" [senior]
**Complaint:** corp.example moved to new auth servers last night. This
morning ~30% of internal lookups still hit the OLD servers — which were
powered off at 06:00. Those users now get timeouts→SERVFAIL.
**Data:** Parent (TLD/EIP) NS set updated 22:00 to new servers. Old NS
RRset TTL was 86400 and was never lowered. Resolvers that refreshed the NS
set after 22:00: fine. Resolvers holding the old NS RRset: iterating into
the void until their copy expires (up to 22:00+24h).
**Diagnosis:** NS-record TTL choreography skipped. The migration plan
ramped down the *record* TTLs but forgot the **NS RRset and glue TTLs** —
the one RRset that decides where resolvers go.
**Recovery:** power the old servers back on serving the zone (parallel-
serve — the correct migration state) until old NS TTL fully expires; only
then decommission.
**Tempting wrong:** flushing every resolver on earth; blaming "slow
propagation" as weather rather than arithmetic.
**Senior explanation:** migrations move *pointers* (NS/glue) — their TTLs
govern the cutover, and the old estate must serve until pointer-TTL expiry.
The no-going-back gate is pointer-TTL expiry, not the change window's end.

### T27 — Child zone dead ONLY for outsiders [senior]
**Complaint:** partner.corp.example resolves internally; external partners
get SERVFAIL. Delegation "was copied exactly" to the external estate.
**Data:** External parent zone: `partner NS ns1.partner.corp.example.` —
and NO glue A. ns1's address exists only in the internal universe.
**Diagnosis:** In-bailiwick delegation without glue on the external side —
circular dependency for external resolvers (internal ones resolve ns1 via
internal zones, masking the bug).
**Fix:** add glue to the external parent; better: use out-of-bailiwick NS
names for externally-delegated children to remove the glue dependency.
**Senior explanation:** "works internally" is a masking pattern —
split-horizon means every delegation must be validated FROM each universe.

### T28 — Anycast: one city sees yesterday [senior]
**Complaint:** Copenhagen users intermittently get a decommissioned IP for
sso.corp.example; Madrid never does. Same resolver address everywhere
(anycast VIP).
**Data:** Per-instance marker (`id.server` / instance TXT trick): CPH
users land on instance dns-cph-1. Direct query to that instance: stale RRset,
TTL huge — cached before the change, and that node ALSO missed the flush
(automation ran on an inventory list that predates dns-cph-1).
**Diagnosis:** Anycast divergence: per-instance caches + incomplete flush
inventory. Routing sends CPH to the stale instance — geography selects the
symptom.
**Fix:** flush the instance; systemic: instance discovery from routing/
monitoring, not a static list; per-instance consistency probes.
**Tempting wrong:** "user-side caching" — instance identification kills it.
**Senior explanation:** anycast = one IP, many truths; any cache operation
must enumerate instances, and monitoring must query *instances*, not the VIP.

### T29 — The NOTIFY storm [senior]
**Complaint:** Primary CPU pinned; logs scrolling thousands of NOTIFY and
SOA queries per minute for corp.example since a config push.
**Data:** Push added `also-notify` entries on BOTH primary and all
secondaries pointing at each other (copy-paste of a shared options block);
secondaries have `notify yes` default → every transfer triggers notifies to
everyone → each NOTIFY triggers SOA checks → feedback amplification.
**Diagnosis:** NOTIFY loop/storm from symmetric also-notify + notify-on-
secondaries.
**Fix:** secondaries: `notify no;` (or explicit and empty); also-notify
only on the primary, only toward secondaries; rate normality returns
immediately.
**Senior explanation:** replication topology is a directed graph; config
templates that ignore role direction create cycles. Draw the intended
arrows before pushing shared blocks.

### T30 — DS rollover roulette [senior] [LAB: 14b analog]
**Complaint:** After "routine DNSSEC key maintenance" on signed zone
secure.corp.example, validating resolvers SERVFAIL it; non-validating are
fine. Started ~24h after the maintenance.
**Data:** `dig DS secure.corp.example @parent` → old DS (digest of retired
KSK). `dig DNSKEY secure… +dnssec` → only the NEW KSK present. delv:
"broken trust chain: no matching DS".
**Diagnosis:** KSK rolled and old key removed BEFORE the parent DS was
updated (or before old-DS TTL expired) — the chain parent→child snapped.
The 24h delay = caches of the old DNSKEY expiring.
**Fix:** re-publish the old KSK (restore chain) OR expedite the correct DS
at the parent; then execute a proper rollover: publish new KSK → update DS
→ wait DS TTL + propagation → only then retire old key.
**Tempting wrong:** resolver-side hunts; the DS-vs-DNSKEY mismatch is
provable in two digs.
**Senior explanation:** KSK rollovers are a *parent-coordination* dance
with TTL waits between steps; the DS is the only record you don't fully
control — schedule around ITS TTL.

### T31 — Signatures died on schedule [senior]
**Complaint:** Signed zone SERVFAILs on validators, Saturday 03:00 onward.
No changes made "in weeks".
**Data:** `dig secure.corp.example SOA +dnssec` → RRSIG expiration
timestamp = Saturday 02:58. Signing host: cron for re-sign disabled during
a patch freeze three weeks ago and never re-enabled (pre-dnssec-policy
legacy zone).
**Diagnosis:** Expired RRSIGs — "no changes" WAS the change; signatures
age out unless re-signing runs.
**Fix:** re-sign now; migrate zone to automated `dnssec-policy` (KASP);
alert on min RRSIG remaining validity.
**Senior explanation:** a signed zone is a living process, not a state;
monitoring must watch signature expiry like cert expiry.

### T32 — Bulk import: 400 rows, columns off by one [senior, EIP]
**Complaint:** After a bulk CSV import, dozens of new records "look
insane": FQDNs resolving to TTL-like numbers is being reported (garbage
values), some legit-looking but wrong.
**Data:** Import mapping step assigned columns shifted by one (value←ttl,
ttl←ticket…). On-error behavior: skip-and-continue → ~340 rows applied,
mixed garbage/plausible. Export of affected zones from BEFORE the import
exists (ceremony followed by the operator — the saving grace).
**Diagnosis:** Column-mapping error at import + permissive row handling.
**Recovery:** halt further batches; diff current export vs pre-change
export → generate exact revert set → apply → post-check; incident report.
**Tempting wrong:** hand-fixing "the visibly wrong ones" — plausible-but-
wrong rows are the real damage; only the diff finds them all.
**Senior explanation:** the pre-change export IS the incident's ceiling;
mapping preview + first-batch canary would have capped it at 50 rows.
Process gap named, not person blamed.

### T33 — Forwarding loop [senior]
**Complaint:** Both resolver sites degraded, high CPU, queries for a
handful of external domains time out; packet rates between the two resolver
clusters are enormous.
**Data:** Site A resolvers: `forward only → Site B` for zone
`legacy.example` (set during an old migration). Site B resolvers:
`forward only → Site A` for the same zone (set last week "to match A").
Queries for legacy.example ping-pong until hop budget dies.
**Diagnosis:** Mutual conditional forwarding = loop.
**Fix:** one side must actually resolve it (static-stub to the real
authorities); loop-prevention rule: conditional forwards always point
*toward authority*, never sideways; document zone routing centrally.
**Senior explanation:** forwarding topology is routing; loops are routing
loops with DNS costumes. A zone-routing map (which namespace → which
next-hop) is the estate document that prevents this class.

### T34 — "We're being DDoSed"… as the amplifier [senior]
**Complaint:** ISP abuse report: your external authoritative is
participating in a reflection attack. Simultaneously, legit external users
report sporadic SERVFAILs.
**Data:** Query logs: floods of `ANY bigzone.example` from spoofed
sources. RRL not configured. The sporadic legit failures: collateral from
saturation.
**Diagnosis:** Open amplification via large answers to spoofed UDP; you're
the reflector, victim is the spoofed address.
**Fix:** enable RRL (slip→TC forces real clients to TCP, spoofed victims
drop); minimal-responses; confirm recursion off; consider ANY-minimization.
Communicate to abuse desk with before/after rates.
**Senior explanation:** TM 4.9's five sentences, delivered as an incident
retro: amplification is a property of being helpful over spoofable UDP;
RRL+TC is the surgical control that keeps real users working.

### T35 — Poisoning scare [senior]
**Complaint:** Security: "resolver returned a WRONG IP for bank-site.example
for 20 minutes — cache poisoning?!"
**Data:** Resolver logs around the window: normal. The "wrong" IP belongs
to the bank's other CDN region. TTL on the RRset was 60; the anomaly window
matches one TTL cycle. Upstream authoritative (CDN) legitimately serves
geo/timing-variant answers.
**Diagnosis:** Not poisoning: legitimate answer variance from a
geo-balanced authority, cached for one TTL. Poisoning triage checklist run
and documented anyway (unexpected NS changes? out-of-bailiwick data? port/
ID randomization intact? DNSSEC where available?).
**Tempting wrong:** declaring poisoning (career-grade false alarm) or
dismissing without running the checklist (career-grade miss).
**Senior explanation:** "wrong answer" claims get the provenance treatment:
what was served, when cached, from which authority, was it plausible-legit
variance — THEN the poisoning indicators. Write the checklist into the SOC
runbook.

### T36 — GSLB flapping metronome [senior]
**Complaint:** app-eu.corp.example alternates between Madrid and Frankfurt
IPs "randomly"; sessions break. TTL 30.
**Data:** GSLB health checks for Madrid pool flap (probe timeout marginal —
80ms threshold, path jitter 70–95ms). Each flap flips the served answer;
TTL 30 means clients follow within seconds.
**Diagnosis:** Health-check threshold too tight → DNS-based failover
oscillation. DNS is faithfully publishing a flapping input.
**Fix:** hysteresis/dampening on checks, saner threshold, TTL vs failover-
speed tradeoff made explicit to the app owner.
**Senior explanation:** GSLB moves failure detection INTO DNS answers; the
record is now a control-system output — tune the controller (checks), not
the messenger.

### T37 — DoH ghost clients [senior]
**Complaint:** RPZ-sinkholed malware domain still being contacted from ~40
workstations (firewall sees connections to the real bad IP). Resolver logs
show ZERO queries for the domain from those hosts.
**Data:** Endpoint inspection: a browser with built-in DoH enabled to a
public resolver; corporate resolver bypassed entirely.
**Diagnosis:** DoH bypass of the enforcement point (TM 3.11's warning,
realized).
**Fix:** endpoint policy disables third-party DoH (canary domain +
GPO/MDM), block known DoH endpoints at egress as defense-in-depth, offer
sanctioned encrypted DNS on corporate resolvers.
**Senior explanation:** the resolver is a policy point only for traffic
that visits it; encrypted-transport policy is an endpoint+egress program,
and the firewall-vs-DNS-log discrepancy is your standing detection for
bypass.

### T38 — The server that resolves against itself [senior]
**Complaint:** A Linux app server intermittently fails internal lookups
after OS patching; `dig @172.20.0.53` always works, plain `dig` sometimes
fails.
**Data:** /etc/resolv.conf now points at 127.0.0.53 (systemd-resolved
enabled by the patch baseline). resolvectl status: interface DNS lists an
OLD decommissioned resolver first, current one second; per-query it
sometimes burns the dead one (and caches negatives from timeout handling).
**Diagnosis:** Patch flipped resolver management to systemd-resolved which
resurrected stale per-link DNS from old config management data.
**Fix:** correct source-of-truth (netplan/NM profile) → resolved inherits;
flush; baseline check for the fleet.
**Senior explanation:** "DNS config" on modern Linux is a *pipeline*
(config mgmt → network manager → resolved → stub) — diagnose at the
resolved layer with resolvectl, fix at the top of the pipeline.

### T39 — Container amnesia [senior]
**Complaint:** Inside new Docker-based CI runners, internal names
intermittently NXDOMAIN; on the host, always fine.
**Data:** Containers use Docker's embedded DNS 127.0.0.11 → forwards to
host's resolv.conf *as captured at daemon/network creation*, which predates
the resolver migration; one of two upstreams there is dead/answers
NXDOMAIN for internal zones (external resolver).
**Diagnosis:** Docker's embedded-DNS upstream list stale/mixed —
per-upstream behavior differences surface as intermittence.
**Fix:** daemon.json/network DNS settings → correct internal resolvers;
recreate networks/containers; fleet audit.
**Senior explanation:** container platforms interpose their own resolver
layer with its own config lifecycle — add "which resolver does the
WORKLOAD see" as ladder rung 0 in containerized estates.

### T40 — Scavenger ate the printers [senior, AD concept]
**Complaint:** Monday: hundreds of static-ish devices (printers, badge
readers) unresolvable in ad.corp.example. Records "vanished".
**Data:** AD DNS aging/scavenging enabled Friday with aggressive
no-refresh/refresh windows; devices register once and never refresh →
timestamps ancient → scavenging deleted them. Audit shows the deletion
batch.
**Diagnosis:** Scavenging misconfiguration deleting live-but-non-refreshing
dynamic records.
**Fix:** restore records (re-register/import), convert genuinely static
devices to static records (exempt from aging), retune windows, stage
scavenging with report-only observation first.
**Senior explanation:** scavenging is garbage collection whose correctness
depends on refresh behavior of every client class; inventory record
*lifecycles* before enabling. (You'll meet this in EIP-managed MS estates
too — same physics.)

### T41 — TTL 0: the record nobody can hold [senior]
**Complaint:** One vendor-integration name resolves fine but generates
insane resolver load and sporadic latency spikes.
**Data:** Record published with TTL 0 (vendor's "always fresh" idea): every
single client lookup → resolver → full upstream fetch; cache never absorbs
anything; spikes when the authority path hiccups.
**Diagnosis:** TTL 0 = caching disabled = every resolution rides the WAN;
you inherited the authority's availability at per-query granularity.
**Fix:** negotiate a sane TTL (30–60 if they need agility); interim
resolver-side min-cache-TTL policy IF policy allows (know the tradeoff:
you're overriding published intent).
**Senior explanation:** TTL is load-shedding and blast-radius control;
TTL 0 outsources your user experience to someone else's uptime, query by
query.

### T42 — Decommission leaves a crater [senior]
**Complaint:** Old zone legacy.corp.example deleted per project closure.
Since then, resolvers log constant SERVFAIL retries and app teams report
30-second stalls (not clean failures) in mixed legacy/current code paths.
**Data:** Zone deleted from auth servers, but the parent DELEGATION (NS in
corp.example) remained → resolvers chase nameservers that now REFUSE →
retry across NS set → slow SERVFAIL instead of instant NXDOMAIN.
**Diagnosis:** Half-decommission: authority removed, pointer left. The
correct end-state for a dead namespace is NXDOMAIN at the parent
(delegation removed), which is fast and cacheable.
**Fix:** remove NS+glue from parent (RB-25's step people skip); optionally
serve an empty zone during a deprecation window to keep NODATA/NXDOMAIN
crisp and observable.
**Senior explanation:** deleting a zone is two changes: the data AND the
delegation; forgetting the second converts "gone" into "slowly broken".

### T43 — The hidden primary that wasn't [senior]
**Complaint:** Security review finding + intermittent external weirdness:
some external resolvers occasionally query an IP that should be your
internal-only hidden primary.
**Data:** The hidden primary's name/IP appears in the zone's NS RRset (a
migration leftover). Mostly unreachable externally (hence "intermittent"),
sometimes leaks through.
**Diagnosis:** Hidden-primary pattern violated: it's listed in NS →
resolvers legitimately select it.
**Fix:** remove it from the NS set (parent and child), keep also-notify/
transfer wiring; verify no glue remnants; the "hidden" property is an NS-set
property, nothing more magical.
**Senior explanation:** in DNS, topology intentions must be encoded in the
records; anything in NS is public routing information regardless of your
diagram.

### T44 — IXFR corruption after the disk filled [senior]
**Complaint:** One secondary serves a zone that fails `named-checkzone`
when dumped — a few records mangled; other secondaries fine. Started after
last week's disk-full incident on that node.
**Data:** Journal (.jnl) on that node damaged during ENOSPC; subsequent
IXFRs applied onto bad state. Logs show journal errors around the disk
event.
**Diagnosis:** Corrupted local zone/journal state on ONE secondary; primary
healthy.
**Fix:** stop zone on the node, delete its zone file+journal, `rndc
retransfer` (clean AXFR), verify serial+spot records vs primary; add
disk-space alarms to the DNS health model.
**Senior explanation:** secondaries hold durable local state; "stateless
replica" thinking is wrong — state can rot locally and only per-node
comparison finds it (serial equality is necessary, not sufficient — hence
spot-record diffs after incidents).

### T45 — Negative TTL landmine post-migration [senior]
**Complaint:** After migrating app zones to a new EIP smart architecture,
every new-record rollout "takes forever to appear" — an hour+, versus
minutes before.
**Data:** New zone template SOA MINIMUM = 3600 (old estate: 300). Auth
answers instantly; resolvers hold NXDOMAIN negatives for an hour for any
pre-queried name.
**Diagnosis:** Template regression: negative-cache TTL 12× larger, changing
rollout physics.
**Fix:** fix SOA MINIMUM in the template + existing zones (serial++,
converge); comms to app teams with the new/old bounds.
**Senior explanation:** migrations must diff the *invisible* zone
parameters (SOA timers, TTL defaults), not just records; a template is
production configuration and gets the same review as code.

### T46 — Monitoring says down, users say fine [senior]
**Complaint:** NOC: "auth cluster CRITICAL — REFUSED on health checks"
since a change window. Zero user impact reported.
**Data:** Monitoring probes query the servers for `healthcheck.monitoring.
internal` — a zone those authoritative servers don't host — relying on
(previously enabled) recursion. The window disabled recursion (correct
hardening!). REFUSED to the probe; users querying hosted zones: unaffected.
**Diagnosis:** Probe design error surfaced by a correct change: monitoring
tested recursion-on-an-authoritative, not authority.
**Fix:** probes ask for hosted-zone SOA expecting aa (per zone, per
server); alert on serial spread and refresh age while you're there.
**Senior explanation:** monitor the *contract of the role*: authoritative
servers are contracted to answer their zones with aa — encode exactly
that; anything else measures an accident.

### T47 — Split-brain zone after emergency edit [senior]
**Complaint:** During last night's P1, someone hand-edited the zone
directly on the EIP-managed server "to fix fast". Today the platform
re-deployed and the emergency record vanished; app down again. Now there's
fear of "DNS randomly reverting".
**Data:** Audit: platform push at 09:00 (unrelated change) rewrote server
state from L1 objects — which never contained the emergency record.
**Diagnosis:** L1/L2 divergence created under pressure, resolved violently
by the next deploy — the platform behaved exactly as designed.
**Fix:** re-add the record VIA the platform; define the emergency
procedure: even at 03:00, changes go through the platform (it's just as
fast), or a documented break-glass with a mandatory reconciliation step
before the next push.
**Senior explanation:** "the platform reverts hotfixes" is a process bug
wearing a technology costume; break-glass without reconciliation is a
scheduled second outage.

### T48 — The 512-byte time machine [senior]
**Complaint:** From one DMZ segment, DNSSEC-signed zones and big TXT
lookups fail; ancient plain lookups fine. New security appliance inline
since the weekend.
**Data:** dig through the path: OPT record stripped from responses
(compare `+qr` sent vs received capabilities), answers clamp at 512,
TC then TCP → appliance also mangles/blocks TCP 53 "DNS inspection".
**Diagnosis:** Middlebox enforcing pre-EDNS assumptions (strips OPT,
polices port-53 payloads) — TM 3 Q25 in the wild.
**Fix:** vendor profile update/disable DNS "helper", allow EDNS + TCP 53;
prove with side-by-side captures inside/outside the appliance.
**Senior explanation:** protocol-aware middleboxes age like milk; the
inside/outside capture pair is the vendor-proof artifact.

### T49 — Two bugs, one ticket [senior composite]
**Complaint:** New service dyn.dev.corp.example unreachable for HQ users.
"DNS wrong AND slow."
**Data:** (1) `dig @resolver1 dyn.dev.corp.example` → SERVFAIL after ~4 s.
(2) `dig NS dev.corp.example @auth1 +norecurse` → ns1.dev (172.20.0.20) and
ns9.dev (172.20.0.99 — decommissioned; leftover from a resilience project).
(3) `dig @172.20.0.20 dyn.dev…` → NXDOMAIN, aa — the record was requested
but the child-zone change was never actually applied.
**Diagnosis:** TWO faults: half-lame delegation (dead ns9 → latency/
intermittency) AND the record genuinely missing in the child (SERVFAIL vs
NXDOMAIN confusion resolved by asking the healthy authority directly).
Resolver behavior mixes them into one smeared symptom.
**Fix:** remove ns9 from parent+child NS; apply the record change; verify
via healthy-NS direct queries then resolver.
**Tempting wrong:** stopping at the first finding — the lameness — and
declaring victory while the record is still absent.
**Senior explanation:** composite tickets are why the ladder runs to
completion even after a hit: "found A fault" ≠ "found THE fault(s)". Your
report lists both with independent evidence.

### T50 — The change that must be refused [senior, capstone-grade]
**Complaint:** Urgent CAB-approved-in-spirit request, Friday 16:40: bulk
CSV — delete 61 "stale" records, add 40 for a migration going live Monday.
Requester is a director. "Just run it."
**Data (your pre-checks find):** 3 delete rows are members of live
round-robins (query logs hot); 2 deletes are CNAME *targets* referenced by
7 other names; 1 add collides case-3 (CNAME exists); 4 adds have IPs
outside the approved ranges (typo pattern 10.100.); on-error behavior of
the import on this version: skip-and-continue; no pre-change export
attached to the ticket; TTLs on affected names: 3600, no ramp-down done —
Monday go-live math doesn't work anyway.
**Correct action:** REFUSE execution as-composed, in writing, with the
findings table; offer the repaired path: corrected CSV (errors itemized),
export/rollback artifact, batch plan, TTL ramp-down starting now for a
Monday cutover, and a Saturday checkpoint. Escalate the refusal to your
own senior WITH the evidence — refusing is a technical act, covering it is
a political one.
**Tempting wrong:** partial execution of "the safe rows" under pressure —
you'd own an undocumented hybrid state going into a weekend.
**Senior explanation:** the pre-check gate exists precisely for Friday
16:40; a refusal with a repaired plan attached is service, not
obstruction. This ticket is the Level 7 gate's spirit in one scenario —
and the final capstone C5 will feel familiar.

---
**Cumulative scoring:** carry the Part 1 tracker through T50. Level 6 gate
requires ≥80% across all attempted; any ticket class scored <3/5 twice goes
to weak-topics and gets a lab reproduction.
