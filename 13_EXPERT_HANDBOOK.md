# SECTION 15 — FINAL DNS EXPERT HANDBOOK
### The book you keep. Annotate it until it's yours.

## 1. MENTAL MODELS (the five)

**M1 — Two planes.** Authoritative servers PUBLISH; resolvers FIND and
REMEMBER. Every question is answered by one of the two planes, and the
flags tell you which (aa vs draining TTL).

**M2 — Three layers of truth.** Intent (objects/files) → Deployed (what
auths serve) → Remembered (every cache). Any pair can disagree; every
finding names its layer.

**M3 — TTL is a contract, not weather.** Every answer is a timestamped
copy with a countdown set by the owner. Convergence is arithmetic:
worst case = old TTL after the last authority updated (+ negative TTL
for creates). State the bound BEFORE the change.

**M4 — The cache stack.** App → OS stub → forwarder → resolver node(s)
→ [negatives at each layer]. Staleness is never mysterious: interrogate
deepest-first, flush bottom-up, fix at source first.

**M5 — Evidence before surgery.** Flush/retransfer/restart destroy the
crime scene. Classify → interrogate per hop → name the owning layer with
proof → THEN act. Cache state is the fastest-expiring evidence.

## 2. RESOLUTION FLOW (text diagram — redraw monthly from memory)

```
app → NSS(hosts?) → stub cache → [UDP rd=1] → resolver
resolver cache? ──hit──> answer (no aa, TTL draining)
   └─miss→ hints→ ROOT ──referral(NS+glue)──> TLD ──referral──> AUTH
             cache NS/glue      cache NS/glue        │
                                                     ▼
                                        AA answer, full TTL
resolver caches RRset(s) → answers stub (ra, no aa) → stub caches
TC=1 anywhere → retry TCP. DO set → RRSIGs ride along; validator walks
anchor→DS→DNSKEY→RRSIG; bogus → SERVFAIL (retrievable with +cd).
```

## 3. DECISION TREES

**WRONG ANSWER**
```
dig @auth (every auth) ── wrong there? → DATA/DEPLOY: platform L1 vs L2,
 │ serials across auths, hand-edit divergence, wrong view's file
 └ right at auth → dig @each resolver NODE (bypass VIP)
      wrong+TTL draining → cache: flushname after source confirmed
      wrong+differs by CLIENT → views/split: marker TXT, source IP, ACL order
      wrong+rewritten → RPZ log
      right at resolver → client: displaydns/resolvectl, hosts file, app pin
```
**NO ANSWER**
```
rcode? NXDOMAIN → real absence? negative cache (SOA TTL draining)? wrong
  suffix expansion (+qr / -DnsOnly shows the real qname)? wrong universe?
NODATA → type absent: AAAA-vs-A, wildcard shadowed by exact name, ENT
SERVFAIL → +cd works? → DNSSEC (delv verdict → DS/DNSKEY/RRSIG dates)
  else bisect per hop (each hop queried DIRECTLY; REFUSED hides upstream)
  auth-side: zone expired? (zonestatus) delegation lame? (3-command audit)
REFUSED → policy AT THAT SERVER: allow-query/recursion ACL, view match,
  not-my-zone-no-recursion, unsigned-where-key-required
TIMEOUT → transport: capture AT SERVER (arrived at all?), UDP vs TCP
  separately, size-dependence (bufsize matrix), path/firewall change log
```
**INTERMITTENT** — match the fingerprint:
~1/N of queries → one bad node/instance (VIP/anycast): per-instance digs.
Fixed +N seconds → a corpse in a list (forwarder/NS): find the timeout
quantum. Size-dependent → EDNS/fragment/TCP. Flap-correlated → GSLB/
health-check inputs. Geography-correlated → anycast instance or site
forwarder.

**THE LADDER (memorize):** exact qname on the wire → client cache →
each resolver node → each authoritative → parent delegation → transport
matrix → DNSSEC. The first layer that's wrong owns it; run to completion
anyway (composites exist).

## 4. RECORD CHEAT SHEET

| Type | Job | The trap |
|---|---|---|
| SOA | zone contract | SERIAL arithmetic; EXPIRE = DR clock; MINIMUM = negative TTL |
| NS | delegation/authority | parent & child copies must match; child's is authoritative |
| A/AAAA | address | multi-value = one RRset = round-robin, not duplicates |
| CNAME | alias the NODE | must be alone (exc. DNSSEC meta); never at apex; MX/NS targets never CNAME |
| MX | mail routing | lowest pref wins; target = hostname w/ A/AAAA |
| TXT | SPF/DKIM/DMARC/tokens | 255-byte strings, split+concatenate; ONE spf; tokens have invisible liveness |
| SRV | service discovery | prio then weight; AD lives here |
| PTR | reverse | linked to forward by PROCESS only; orphans lie to SIEM/mail |
| CAA | cert issuance gate | walks up labels; absent = any CA |
| wildcard | synthesize nonexistent | ANY exact name shadows ALL types; typos "resolve" |

## 5. TTL / CACHE CHEAT SHEET

Positive: cached per record TTL, decremented per second, per cache.
Negative: min(SOA MINIMUM, SOA TTL), per cache, covers name (NXDOMAIN)
or name+type (NODATA).
Change bound: old TTL after last auth converges. Create bound: negative
TTL where pre-queried. Ramp-down: start ≥1×old-TTL before the window.
Flush verbs: app restart / `Clear-DnsClientCache` / `resolvectl
flush-caches` / `rndc flushname|flushtree|flush` (per NODE).
Provenance: aa+full TTL = source; no aa+draining = cache; +norecurse =
cache X-ray; TTL went UP = other node or refreshed.

## 6. BIND CHEAT SHEET

Files: named.conf (options/acl/zone/view/key/logging/controls), zone
files, .jnl journals (dynamic truth), named_dump.db (cache snapshot).
Pre-commit: `named-checkconf -z` · `named-checkzone zone file`.
Drive: `rndc status | zonestatus Z | reload [Z] | reconfig | retransfer Z
| refresh Z | flushname N | flushtree N | freeze Z / thaw Z | querylog
| dumpdb -cache | notify Z`.
Replication: edit→serial++→reload→NOTIFY→SOA check→IXFR(journal)/AXFR.
Serial back? retransfer per node or +2^31 wrap. Secondary clocks: REFRESH
/RETRY/EXPIRE from last success — expiry = SERVFAIL.
TSIG logs: BADSIG=secret, BADTIME=clock, BADKEY=name, plain REFUSED=
unsigned vs key ACL.
Dynamic zones: never hand-edit; freeze→edit→thaw. Hidden primary = NS-set
discipline + notify explicit/also-notify.
Hardening: recursion off on auths, allow-transfer keyed, RRL external,
minimal-responses, version none, unique keys, NTP as dependency.
Triage order: status → checkconf -z → zonestatus → logs → dig local
(right view) → dig remote → surgery LAST.

## 7. EFFICIENTIP / DDI CHEAT SHEET

Objects: server → view → zone → RR; space → network → address (name-
carrying, drives A+PTR). Smart architecture = replication graph as
template. Class parameters = ownership metadata.
Layer check: GUI(L1) → dig @each managed server(L2, aa+serial) →
caches(L3). L1≠L2 = push failed/staged/hand-edit divergence — find sync
status. Apply via platform ALWAYS; break-glass ends in reconciliation.
"Already exists" = 4 realities: exact dup (close w/ evidence) / other
value (owner: RR vs stale) / type conflict (design decision) / automation
collision (fix lifecycle). Never force.
Bulk: mapping preview · on-error semantics · dry-run · pre-change EXPORT
= rollback · batches with mid-checks · value-match deletes · liveness +
dependency sweep · PTR plan per row.
Ten pre-approval checks: ticket-match, ownership, deployed pre-check,
collision, reverse, dependencies+liveness, TTL story, rollback artifact,
post-check plan, comms.

## 8. COMMAND CHEAT SHEET

```
dig @S name T            # always choose the server
  +norecurse             # cache X-ray / referral view
  +trace                 # dig iterates itself (NOT your resolver's view)
  +tcp +bufsize=N +noedns# transport matrix (512/1232/4096/tcp)
  +dnssec +cd            # DO bit / bypass validation (classifier)
  +qr                    # see what you actually sent
  -x IP                  # reverse
  zone AXFR [-y alg:name:secret]
delv @S name             # validation verdict + failing link
host name S              # quick glance
nslookup name S          # Windows fluency; "non-authoritative" = normal
rndc <verbs above>       # via controls/953
tcpdump -ni any port 53 [-w f.pcap]   # arrived at all? (strongest bisect)
Resolve-DnsName name -Server S -DnsOnly [-Type T]
Get-DnsClientCache / Clear-DnsClientCache / ipconfig /displaydns /flushdns
Get-DnsClientNrptPolicy  # VPN name-routing truth on Windows
resolvectl status|query -v|statistics|flush-caches ; getent hosts name
named-checkconf -z ; named-checkzone Z file
```

## 9. ENTERPRISE CHANGE CHECKLIST (pin this)

☐ Ticket matches request exactly (no while-we're-at-it) ☐ Owner sign-off
☐ Pre-check vs DEPLOYED reality (every auth) ☐ Collision taxonomy per
name ☐ Dependency sweep (CNAME-in/MX/SRV/NS) ☐ Liveness for deletes
(query logs; remember token-TXT blind spot) ☐ Reverse plan ☐ TTL story
(bound stated; ramp if needed) ☐ Rollback artifact captured BEFORE ☐
Batches + mid-checks (bulk) ☐ Post-check every auth (aa, value, serial)
☐ Convergence clock in the closure comms ☐ Evidence filed

## 10. INCIDENT CHECKLIST

☐ Classify symptom (wrong/rcode/timeout/intermittent) ☐ Preserve
fast-expiring evidence (digs w/ timestamps, dumpdb, captures) BEFORE any
flush ☐ Ladder per hop, direct queries, right view ☐ Owning layer named
with proof ☐ Fix at source first, caches second ☐ Verify at EVERY layer
☐ Ack ≤10 min / updates / resolution WITH the TTL-honesty sentence ☐
Report: timeline, evidence, root cause, fix, prevention ☐ Ladder ran to
completion (composites) ☐ New flashcard/monitoring idea captured

## 11. SENIOR EXPLANATION TEMPLATES

**Change closure:** "Live at source since HH:MM — all N authorities
serving it (aa, serial S). Anyone who queried before HH:MM may hold the
old answer up to TTL T: full convergence by HH:MM+T; we've flushed the
resolvers we own. Rollback is a one-step re-apply held in the ticket."
**Exoneration:** "Resolution is correct at client-path, resolver, and
authority — evidence attached. The failing component is X: <config line/
hosts entry/pinned IP>. Happy to walk through the captures."
**Refusal:** "As composed, this change fails N pre-checks (table
attached). Here is the repaired path: <fixes, batching, TTL ramp,
checkpoint>. I can execute the repaired version in <window>."
**Incident update:** "Confirmed impact: X. Evidence so far points to
<layer> (<proof>). Next update HH:MM. Workaround: <honest or none>."
**Diagnosis delivery:** claim → layer → proof command → output →
therefore. One sentence each. No adjectives.

## 12. COMMON MISTAKES (the graveyard)

Flushing before diagnosing · one generic answer to "already exists" ·
name-only deletes (round-robin surgery) · trusting GUI over dig ·
hand-editing managed/dynamic zones · forgetting serial++ · forgetting
the NS/glue TTL in migrations · deleting the delegation last-or-never ·
"cleanup" of TXT/wildcards without owners · TTL 0 as agility ·
monitoring port-53-answers instead of the contract · promising instant
visibility after a change · declaring victory at the first fault ·
diagnosing through the VIP · believing "non-authoritative" is an error ·
testing forward-first fallback never · scheduling the TTL ramp too late.

## 13. HOW TO SOUND SENIOR AND STAY ACCURATE

Speak in mechanisms, not vibes ("negative cache per SOA minimum, 900s
here" — never "DNS is slow"). Attach a clock to every claim about
visibility. Name the layer for every finding. Say "I'd verify X" instead
of inventing X — verified ignorance outranks confident fiction. Refuse
with a repaired plan attached. Quantify blast radius before touching
anything. Let the estate arbitrate disagreements: propose the
discriminating test. And the one-liner that carries the whole program:
**"Here's the evidence, here's the layer, here's the bound, here's the
rollback."** If every answer you give has those four parts, you are the
senior in the room.
