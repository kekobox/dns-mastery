# SECTION 3 — MASTERY MAP
### Packet 1c — Intermediate operator → Senior enterprise DNS engineer

Rule: you do not "move on" from a level by finishing its days on the calendar.
You move on by meeting the **proof-of-mastery criteria** and logging the proof
in your journal. Calendar days spent ≠ competence.

---

## LEVEL 1 — DNS CORE MECHANICS (Weeks 1–2)

**Understand:** namespace tree, zones vs domains, stub/recursive/forwarding/
authoritative roles, iterative vs recursive queries, root hints, referrals,
glue, the DNS message format (header, flags, four sections), UDP/TCP 53, EDNS.

**Explain:** the full cold-cache resolution of `www.corp.example` including
every referral and every cache write; what each flag (QR AA RD RA TC AD CD)
means and who sets it; why a resolver's answer is a *copy*, not the truth.

**Configure in lab:** the full Docker BIND lab (file 06): 1 recursive, 2
authoritative (parent + child), 1 forwarder; Windows host + WSL as clients.

**Troubleshoot:** distinguish authoritative vs cached answers with dig alone;
identify which component answered any given query.

**Senior traps:** confusing "recursive query" (rd bit) with "recursion
performed"; thinking `+trace` shows your resolver's view; believing nslookup's
"non-authoritative" is an error; forgetting the stub cache exists.

**Proof of mastery:** (1) hand-drawn resolution flow, from memory, annotated
with flags and cache writes, photographed into journal; (2) live demo: same
query answered three ways (auth, resolver cache, client cache) with the flag/
TTL evidence for each captured; (3) Week 2 exam ≥85%.

---

## LEVEL 2 — RECORDS, ZONES, DELEGATION, REVERSE (Weeks 3–4)

**Understand:** SOA (every field, especially serial and minimum/neg-TTL), NS,
A/AAAA, CNAME (and its exclusivity rule), MX, TXT (SPF/DKIM/DMARC mechanics at
DNS level), SRV, PTR, CAA, NAPTR, wildcards and their non-obvious matching
rules; zone file syntax ($TTL, $ORIGIN, relative names, the trailing-dot
trap); parent/child, delegation, glue, lame delegation; in-addr.arpa /
ip6.arpa structure and classless reverse delegation (RFC 2317).

**Explain:** why CNAME-at-apex is illegal; NXDOMAIN vs NODATA with wildcard
interaction; how a /24 reverse zone maps to addresses; what breaks when serial
doesn't increment.

**Configure in lab:** full corp.example zone with every record type; reverse
zones for 10.10.0.0/16 and 192.168.50.0/24; delegate dev.corp.example with
glue; deliberately create then fix a lame delegation; wildcard zone behavior
lab.

**Troubleshoot:** missing trailing dot symptoms; CNAME conflicts; forward/
reverse mismatch; delegation broken at parent vs child.

**Senior traps:** wildcard does NOT match names that exist with other types
(empty non-terminals nuances); MX must point to a name with A/AAAA, never a
CNAME; TXT 255-byte string segmentation; PTR zones are ordinary zones —
"reverse DNS is broken" is almost always stale data, not infrastructure.

**Proof:** zone files pass named-checkzone; a written "record type risk table"
(what breaks if each type is wrong); lame-delegation break/fix demo with
before/after dig captures; Week 4 exam ≥85% + July capstone passed.

---

## LEVEL 3 — RECURSIVE / CACHING / FORWARDING / SPLIT-HORIZON (Weeks 5–7)

**Understand:** cache internals (RRset caching, TTL decrement, cache poisoning
defenses at concept level), negative caching (RFC 2308) deeply, forwarding vs
conditional forwarding vs stub zones, views/match-clients, internal vs
external DNS architectures, NXDOMAIN/NODATA/SERVFAIL/REFUSED semantics,
EDNS/fragmentation/1232, DoT/DoH at operational level, Linux resolver stack
(glibc, /etc/resolv.conf, systemd-resolved, nsswitch) and Windows resolver
behavior (cache, suffix search lists, LLMNR/mDNS interference, DNS client
service).

**Explain:** where every possible stale answer can live and how to purge each;
why negative caching makes "I just added the record" fail; how a query flows
in a forwarding hierarchy and where SERVFAIL originates.

**Configure in lab:** conditional forwarding lab; split-horizon with BIND
views (internal/external answers for portal.corp.example); stale-cache lab;
negative-cache lab; forwarder-chain failure lab.

**Troubleshoot:** stale record at each cache layer; split-horizon leaks;
resolver returns answer for zone it doesn't host (cache via +norecurse);
Windows suffix-search-list surprises.

**Senior traps:** flushing the wrong cache; assuming one resolver = one cache
behind a VIP; forgetting the *forwarder's* cache; negative TTL vs record TTL
confusion; systemd-resolved's own cache surprising Linux admins.

**Proof:** the "cache map" — a written diagram of every cache between app and
zone data with the flush command for each; live split-horizon demo; Week 7
exam ≥85%.

---

## LEVEL 4 — BIND OPERATIONS (Weeks 8–9)

**Understand:** named.conf structure (options, zone, view, acl, key, logging,
controls), primary/secondary mechanics, serial discipline, notify, AXFR/IXFR
+ journals, TSIG, rndc operations, dynamic updates + journal freeze/thaw,
BIND logging categories/channels, query logging, RPZ, response-rate-limiting
concepts.

**Explain:** the life of a zone change from edit → serial → notify → transfer
→ answer; why editing a dynamic zone file directly corrupts it; what each
rndc subcommand touches.

**Configure in lab:** primary/secondary with NOTIFY + TSIG-secured transfers;
IXFR observation via journals; dynamic updates with nsupdate; query logging +
log analysis; an RPZ blocking a lab domain (sinkhole); break/fix: wrong
serial, trimmed journal, bad TSIG clock skew, allow-transfer lockout.

**Troubleshoot:** transfer failures (REFUSED vs TSIG vs network), zone expiry
on secondaries, rndc connection issues, config errors via
named-checkconf/named-checkzone before they bite.

**Senior traps:** decreasing a serial (and the 2^31 wrap trick to fix it);
forgetting `rndc freeze` before hand-editing dynamic zones; logging channels
misdirected so "logging is broken"; secondary silently serving expired-soon
data.

**Proof:** full transfer chain demo with tcpdump capture of NOTIFY+IXFR; a
written BIND ops runbook in your own words; deliberately corrupt then recover
a zone using journal knowledge; Week 9 exam ≥85% + August capstone.

---

## LEVEL 5 — EFFICIENTIP / SOLIDSERVER OPERATIONS (Weeks 10–11)

**Understand:** SOLIDserver object model at practical level (DNS servers /
smart architectures, views, zones, RRs; IPAM spaces, networks, addresses;
how a DNS record and an IPAM address relate), class parameters concept,
deployment model (SOLIDserver pushing to managed DNS servers), where BIND
sits underneath, GUI vs API vs CSV import surfaces, rights/approval
workflows.

**Explain:** what objects must exist for a record to deploy; why "record
already exists" fires (exact duplicate vs name collision vs CNAME conflict
vs reverse auto-generation collision); how IPAM-driven DNS keeps forward/
reverse consistent — and how it drifts anyway.

**Configure/simulate:** since no lab appliance — simulate workflows against
your BIND lab: model an "IPAM sheet" (CSV) as source of truth, practice the
pre-check/apply/post-check discipline exactly as SOLIDserver changes are
done; then answer the real-environment validation questions (file 07)
read-only against your corporate SOLIDserver.

**Troubleshoot:** record exists/conflict errors, deployment not reaching the
DNS server (pushed but not answering), GUI shows record but dig disagrees
(which layer lies?), reverse auto-creation surprises.

**Senior traps:** trusting the GUI over dig; forgetting SOLIDserver manages
*objects* while resolvers serve *cached copies*; bulk CSV with one bad row
semantics (all-or-nothing vs partial); deleting an A record while a PTR or
CNAME still references it.

**Proof:** written SOLIDserver conceptual map (objects + their BIND
equivalents); completed real-environment validation questionnaire (read-only);
a full simulated bulk change with pre/post artifacts; Week 11 exam ≥85%.

---

## LEVEL 6 — TROUBLESHOOTING & INCIDENT RESPONSE (Weeks 12–13)

**Understand:** the universal isolation method (client cache → resolver →
forwarder → authoritative → network at each hop), reading tcpdump/Wireshark
DNS captures, intermittent-failure patterns (one-of-N resolvers bad, UDP vs
TCP, fragmentation, anycast instance divergence), firewall interaction, DNSSEC
failure signatures, timing analysis.

**Explain:** your decision tree out loud in under two minutes; how to prove a
negative ("DNS is fine, the problem is X") to a hostile app team.

**Configure in lab:** all break/fix scenarios armed and solved (file 06);
packet captures of healthy and broken flows archived as references.

**Troubleshoot:** tickets 1–35 (file 09) solved with written diagnosis before
reading answers; ≥80% correct including identifying the red herring.

**Senior traps:** stopping at the first plausible cause; flushing caches as
"the fix" without finding why data was wrong; blaming DNS for connectivity
problems and vice versa; not capturing evidence before it expires (TTL!).

**Proof:** ticket log with scores; one full incident writeup (timeline,
evidence, root cause, fix, prevention) reviewed against the model; September
capstone passed.

---

## LEVEL 7 — BULK OPERATIONS & CHANGE MANAGEMENT (Week 14)
*(Automation scripting deferred per your decision — this level trains the
discipline manually with dig/Resolve-DnsName and structured CSVs.)*

**Understand:** enterprise change lifecycle (request → validation → CAB/
approval → window → apply → verify → close/rollback), CSV validation rules,
dependency analysis (what references a name), blast radius, TTL strategy
around changes, communication templates.

**Explain:** why pre-checks compare name+type+value, not just existence; the
rollback artifact concept; when to refuse a change.

**Configure in lab:** execute a 50-row bulk add and 50-row bulk delete against
lab BIND using a manual checklist workflow; produce pre-check and post-check
evidence files.

**Troubleshoot:** a poisoned CSV (duplicates, bad IPs, CNAME conflicts,
records that don't match reality) — find every landmine before "executing".

**Senior traps:** validating syntax but not semantics; deleting round-robin
members thinking they're duplicates; no negative-TTL communication after
deletes; rollback plan that assumes the change half-succeeded cleanly.

**Proof:** the poisoned-CSV exercise with 100% landmines found; your own
written change-checklist that a colleague could execute; Week 14 exam ≥85%.

---

## LEVEL 8 — ARCHITECTURE, HA, DNSSEC, ANYCAST, SENIOR DESIGN (Weeks 15–17)

**Understand:** enterprise DNS reference architectures (hidden primary,
internal/external split, resolver tiers, forwarder trees, AD DNS
coexistence), HA patterns (anycast vs VIP vs multiple NS), DNSSEC signing
operations (KSK/ZSK, rollovers, DS interaction with parent, NSEC/NSEC3),
DoT/DoH policy implications, GSLB/health-checked DNS basics, monitoring
(what to graph: QPS, SERVFAIL rate, latency, transfer lag, expiry),
migration and DR planning, Infoblox-vs-EfficientIP-vs-BIND mapping.

**Explain:** defend an architecture choice under challenge; walk a zone
migration plan including serial/NS/TTL choreography; explain a DNSSEC
rollover and its failure modes.

**Configure in lab:** sign lab.internal with DNSSEC, validate with delv, then
break it (expired signatures / wrong DS) and diagnose; hidden-primary
topology; a full zone migration between lab servers with pre/post evidence.

**Troubleshoot:** DNSSEC SERVFAIL chains; migration cutover issues; "one
anycast site answers differently" (simulated with two resolvers).

**Senior traps:** signing without a rollover plan; migration TTL lowered too
late; NS changes without parent update; monitoring answers ("it responds")
instead of correctness ("it responds *right*").

**Proof:** architecture design doc for a fictional enterprise (written +
defended against the oral pack's architecture questions); DNSSEC break/fix
demo; October capstone passed.

---

## LEVEL 9 — FINAL ENTERPRISE CAPSTONE (Weeks 18–19, ends 15 Nov 2026)

Simulates being *the* DNS engineer on duty. Defined fully in file 12:
an enterprise change + stale-cache incident + delegation failure + BIND
config fault + SOLIDserver-style bulk operation + senior design review +
rollback + written incident report — executed against the lab under time
pressure.

**Proof of program completion:**
- Final capstone all 8 components passed per rubric.
- Baseline exam re-take ≥90.
- Oral pack: ≥80% of 150 questions at "excellent" tier (self-graded honestly,
  recorded aloud).
- Handbook (file 13) annotated with your own additions — the proof you made
  it yours.
