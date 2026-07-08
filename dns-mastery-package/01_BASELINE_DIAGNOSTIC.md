# SECTION 2 — BASELINE DIAGNOSTIC EXAM
### Packet 1b — Take this on Day 1 (7 July 2026), closed-book, 90 minutes max.

Rules: no notes, no lab, no internet. Write answers by hand or in a text file.
Then grade yourself with the answer key using the rubric. Be brutal. An answer
that is "sort of right" scores half at best. Vague = wrong.

---

## PART A — CONCEPTS (15 questions, 2 pts each = 30 pts)

**A1.** A client asks its configured DNS server for `www.corp.example`. That
server does not host the zone. Describe every hop and every actor involved in a
cold-cache resolution, in order, naming each component's role.

**A2.** What is the difference between a record *stored in a zone* on an
authoritative server and an *answer returned* by a recursive resolver? Name two
ways they can legitimately differ at a given moment.

**A3.** Define NXDOMAIN vs NODATA. Give one concrete example of each for the
name `app1.lab.internal`.

**A4.** What does the SOA *minimum* field control in modern DNS (RFC 2308), and
why does it matter operationally when you delete a record?

**A5.** What is a glue record, when is it required, and what breaks without it?

**A6.** What is a lame delegation? Name two ways it manifests to clients.

**A7.** A CNAME exists for `web.corp.example`. Why can you not also add a TXT
record at `web.corp.example`? Which rule forbids it, and what is the one
exception at a name where CNAME-like behavior coexists with other data?
(Naming DNAME or the CNAME-at-apex prohibition angle acceptable.)

**A8.** Explain TTL behavior end-to-end: who sets it, who decrements it, what a
decreasing TTL in a response proves, and what TTL you'd expect from an
authoritative server on repeated queries.

**A9.** Difference between a forwarder and a conditional forwarder. Give one
enterprise use case for each.

**A10.** What is split-horizon DNS? Name two implementation mechanisms and one
classic failure mode it produces.

**A11.** When does DNS use TCP 53? Name at least three triggers. What breaks in
an enterprise if a firewall permits UDP 53 but blocks TCP 53?

**A12.** What is EDNS(0), what problem did it solve, and how does it relate to
fragmentation problems and the modern ~1232-byte guidance?

**A13.** SERVFAIL vs REFUSED vs timeout — what does each typically indicate,
and which component do you suspect first for each?

**A14.** In DNSSEC: what do RRSIG, DNSKEY, and DS records each do, and where
does the DS live (parent or child)? Why does a stale DS cause SERVFAIL on
*validating* resolvers only?

**A15.** AXFR vs IXFR — difference, and what makes an IXFR fall back to AXFR?

---

## PART B — COMMAND / OUTPUT INTERPRETATION (8 questions, 3 pts each = 24 pts)

**B1.** Interpret this header line and flags. Where did the answer come from,
and is the responding server authoritative?

```
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31337
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; ANSWER SECTION:
app1.corp.example.  212  IN  A  10.10.20.15
```
Also: what does the value `212` most likely tell you if the zone default TTL
is 300?

**B2.** Same query, different server:

```
;; flags: qr aa rd; QUERY: 1, ANSWER: 1
app1.corp.example.  300  IN  A  10.10.20.15
```
What is different, what does `aa` prove, and why is `ra` missing possibly fine
here?

**B3.** `dig www.example.net` returns `status: NXDOMAIN` with an SOA in the
AUTHORITY section, TTL 900. What is that SOA doing there, and for how long will
this resolver keep answering NXDOMAIN even after you create the record?

**B4.** You run `dig @10.10.0.53 db1.lab.internal +norecurse` against a
recursive resolver and get NOERROR with an answer. Then a colleague runs the
same and gets 0 answers with `status: NOERROR`. Explain both results.

**B5.** What is `dig +trace` actually doing (who performs the recursion?), and
name one reason its result can differ from what your corporate resolver returns.

**B6.** Windows client: `Resolve-DnsName app1.corp.example` returns an IP, but
`nslookup app1.corp.example` prints `Non-authoritative answer`. A junior says
"nslookup says DNS is broken because it's non-authoritative." Correct them.

**B7.** `ipconfig /displaydns` shows the record with a small TTL counting down.
The app team says "DNS is wrong." What exactly does this display prove, and
what is your next command on the *resolver* side to compare?

**B8.** `rndc status` works but `dig @127.0.0.1 corp.example SOA` on the BIND
box returns REFUSED. Name the two most likely `named.conf` causes.

---

## PART C — SCENARIO DIAGNOSIS (8 questions, 4 pts each = 32 pts)

For each: (i) most likely cause, (ii) the command(s) that PROVE it,
(iii) the fix, (iv) one tempting wrong diagnosis.

**C1.** Record `app2.corp.example` was changed from 10.10.20.15 to 10.10.30.15
an hour ago. Authoritative servers return the new IP. Half the clients still
connect to the old one.

**C2.** Reverse lookup of 10.10.20.15 returns `old-db.corp.example`, but
`old-db.corp.example` doesn't resolve forward. Impact + cause + fix.

**C3.** Everything under `dev.corp.example` fails with SERVFAIL, but
`corp.example` itself resolves fine. `dig NS dev.corp.example @<corp.example
auth server>` returns two NS names; neither answers for the child zone.

**C4.** Zone transfer from primary 10.10.0.10 to secondary 10.10.0.11 fails.
On the secondary: `transfer of 'corp.example/IN' from 10.10.0.10#53: failed
while receiving responses: REFUSED`. Two most likely causes and how to prove
each.

**C5.** Internal users resolve `portal.corp.example` to 10.10.40.10; external
users get 203.0.113.40 — intended. But some *internal* users suddenly get the
external IP. What architecture is in play and what are the two most common
causes of the leak?

**C6.** DNS resolution works from subnet 192.168.50.0/24 but not from
10.10.60.0/24, same resolver IP configured. dig from the failing subnet times
out; from the working subnet it's instant. Order your suspects and the proof
for each.

**C7.** Large TXT lookups (DKIM keys) fail intermittently: dig over UDP times
out or is truncated, `dig +tcp` works everywhere. What's happening and what are
two acceptable fixes?

**C8.** After enabling DNSSEC validation on the corporate resolvers, one
external domain returns SERVFAIL corporately but resolves on 8.8.8.8 with `+cd`.
Walk the proof chain: which commands, in which order, to show whether it's the
domain's fault or yours?

---

## PART D — SENIOR ORAL QUESTIONS (5 questions, ~3 pts each = 14 pts)
Answer in writing, 5–10 sentences each, as if a senior engineer asked you in a
design review.

**D1.** "Walk me through what happens, packet by packet, when a laptop with an
empty cache opens `https://portal.corp.example` — DNS only, stop at the A/AAAA
answer."

**D2.** "How do you *prove* whether a wrong answer is an authoritative-data
problem, a resolver-cache problem, a client-cache problem, a network/firewall
problem, or an application problem? Give me your decision sequence."

**D3.** "What objects must exist, and where, for `newapp.corp.example` →
10.10.20.80 to resolve correctly for internal clients, including reverse DNS?"

**D4.** "Why do we forbid CNAMEs at zone apex, and what do we do instead when a
vendor demands one?"

**D5.** "You're about to bulk-delete 400 A records from a CSV. What must be
validated before you press go, and what's your rollback?"

---

# ANSWER KEY

## Part A

**A1.** Stub resolver (client OS) → configured recursive resolver. Resolver has
cold cache → queries a **root server** (from its root hints) for
`www.corp.example` → root refers to `.example` TLD NS (referral, no answer) →
resolver queries TLD NS → referral to `corp.example` authoritative NS (with
glue if in-bailiwick) → resolver queries authoritative NS → gets AA answer →
caches every RRset it learned (NS sets, A of nameservers, final answer) →
returns non-authoritative answer to stub, which caches it too. Full credit
requires: stub vs recursive distinction, iterative referrals, caching at both
resolver and stub.

**A2.** Zone data is the source of truth with the *original* TTL; a recursive
answer is a cached copy with a *decremented* TTL. Legitimate differences: (1)
TTL value counting down; (2) stale data during TTL window after a change; also
acceptable: CNAME chains flattened into multi-RRset answers, RRset order
rotation (round-robin), minimal-responses trimming, negative answers
synthesized from SOA.

**A3.** NXDOMAIN: the *name* does not exist at all (no records of any type) —
e.g. `app1.lab.internal` was never created; rcode NXDOMAIN + SOA in authority.
NODATA: the name exists but not for the queried type — e.g. `app1.lab.internal`
has an A record and you query AAAA: rcode NOERROR, ANSWER 0, SOA in authority.

**A4.** Per RFC 2308 the SOA minimum field is the **negative-caching TTL**: how
long resolvers cache NXDOMAIN/NODATA (capped by the SOA record's own TTL).
Operationally: after deleting a record, queries that arrive create negative
cache entries lasting up to that value — and when *creating* a record that was
recently queried-and-missing, clients keep seeing NXDOMAIN until negative TTL
expires. Classic "I added the record but it still doesn't resolve."

**A5.** Glue = A/AAAA records for a delegated zone's nameservers placed in the
**parent** zone, required when the NS names are *inside* the delegated zone
(in-bailiwick), e.g. `dev.corp.example NS ns1.dev.corp.example`. Without glue:
circular dependency — you can't resolve the NS name without asking the very
servers you're trying to find → child zone unresolvable.

**A6.** Lame delegation: the parent delegates to a server that is not actually
authoritative for the zone (doesn't answer with AA / answers REFUSED /
SERVFAIL / doesn't respond). Manifestations: intermittent failures (resolvers
rotate NS and only some are lame), slow resolution (retries), SERVFAIL when all
listed NS are lame.

**A7.** RFC rule: a CNAME must be the **only** record at a node (excluding
DNSSEC records like RRSIG/NSEC, which is the exception worth naming). Adding
TXT alongside CNAME violates "CNAME and other data." Also acceptable: apex
can't be CNAME because SOA/NS must exist there — same rule.

**A8.** The zone owner sets TTL in the zone (per-record or $TTL default). The
recursive resolver caches the RRset and **decrements** TTL every second;
answers it serves show remaining TTL. A decreasing TTL across repeated queries
proves the answer is served from cache. An authoritative server returns the
full original TTL every time. Client stub caches also honor (and may cap) TTL.

**A9.** Forwarder: resolver sends *all* recursion upstream (e.g. internal
resolvers → central resolvers → ISP/cloud). Conditional forwarding: only
specific zones go to specific servers — e.g. `partnercorp.example` →
partner's DNS over a VPN, or AD domain zones → domain controllers.

**A10.** Same name gives different answers depending on who asks. Mechanisms:
BIND **views** (match-clients), or physically separate internal/external
authoritative servers (the more common enterprise pattern; EfficientIP
"smart" architectures do either). Classic failure: a client hits the wrong
side (VPN split-tunnel, wrong resolver, misordered match-clients) and gets the
external answer internally — or a zone updated on one side only, causing
internal/external drift.

**A11.** TCP triggers: (1) TC=1 truncation retry (response too big for
UDP/EDNS size), (2) zone transfers AXFR/IXFR always TCP, (3) resolvers/clients
may use TCP after fragmentation issues; also DoT is TCP 853. Blocked TCP 53:
zone transfers fail, large responses (DNSSEC, big TXT/SRV sets) fail
intermittently — the classic "mostly works, weird failures" pattern.

**A12.** EDNS(0) = extension mechanism (OPT pseudo-record) letting UDP
responses exceed the original 512-byte limit and carry flags (DO bit for
DNSSEC) and options. Big UDP responses get IP-fragmented; fragments are dropped
by many firewalls/paths → timeouts. Hence DNS Flag Day 2020 guidance:
advertise ~1232 bytes so responses either fit unfragmented or truncate to TCP.

**A13.** SERVFAIL: the *server tried and failed* — upstream unreachable,
broken delegation, DNSSEC validation failure, expired zone on a secondary.
Suspect resolution path/zone health. REFUSED: *policy* — ACLs
(allow-query/allow-recursion), wrong view, querying a server not configured
for that zone/recursion. Suspect configuration. Timeout: nothing came back —
network, firewall, dead server, dropped fragments. Suspect network path first.

**A14.** DNSKEY: the zone's public keys (KSK/ZSK), in the child. RRSIG:
signatures over each RRset, in the child. DS: hash of the child's KSK,
published in the **parent**, creating the chain of trust. Stale DS (key rolled
but parent DS not updated) breaks the chain; validating resolvers get bogus →
SERVFAIL; non-validating resolvers ignore DNSSEC and resolve fine — which is
exactly the diagnostic signature.

**A15.** AXFR: full zone transfer. IXFR: incremental, based on serial deltas
kept in the primary's journal. Falls back to AXFR when the primary lacks the
journal history for the secondary's serial (journal trimmed, primary restarted
without journal, serial mismatch/rewind) or IXFR not supported.

## Part B

**B1.** `qr` response, `rd` recursion desired, `ra` recursion available, **no
`aa`** → non-authoritative: a recursive resolver answered from cache or after
recursion. TTL 212 vs zone default 300 → cached ~88 seconds ago; the
countdown itself proves cache.

**B2.** `aa` set → this server is authoritative for `corp.example`; the answer
comes from zone data, full TTL 300. `ra` absent is normal/healthy for a pure
authoritative server with recursion disabled (best practice).

**B3.** Negative caching: the SOA of the covering zone is included so the
resolver knows how long to cache the NXDOMAIN — min(SOA minimum, SOA TTL),
here 900 s. After you create the record, this resolver can keep answering
NXDOMAIN up to 900 s from when it cached the negative answer.

**B4.** `+norecurse` asks the server to answer only from what it already has.
You got a cache hit (someone resolved it recently); your colleague may have hit
a different server behind the same VIP/anycast address, or the entry expired
between queries. Key concept: `+norecurse` against a resolver is a cache
inspection technique, and load-balanced resolvers have independent caches.

**B5.** `+trace` makes **dig itself** iterate: it queries root, then TLD, then
authoritative, ignoring your resolver entirely (except to bootstrap root NS).
Differences vs corporate resolver: internal/split-horizon zones invisible to
public tree, corporate forwarding/views, cached (stale) data on the resolver,
RPZ rewrites, or different network egress.

**B6.** "Non-authoritative answer" is nslookup's *normal* label for any answer
from a recursive resolver's cache/recursion — i.e., almost every client lookup
ever. It indicates nothing is broken; it distinguishes cache-derived answers
from AA answers. Both tools got a valid answer.

**B7.** It proves only the **client OS cache** contents and that the client
received that answer earlier; it says nothing about what the resolver *now*
returns. Next: query the resolver directly, bypassing client cache —
`Resolve-DnsName app1.corp.example -Server <resolver> -DnsOnly` (or dig
@resolver) — and compare against an authoritative server to localize the
staleness.

**B8.** (1) `allow-query` ACL on the zone/options excludes 127.0.0.1 (or a
`match-clients` view mismatch puts localhost in a view without the zone);
(2) the server isn't actually serving that zone in the reachable view /
zone not loaded — but with REFUSED specifically, ACL/view policy is the
prime suspect. Also acceptable: querying the wrong listen address/view.

## Part C  (credit requires cause + proof + fix + trap)

**C1.** Cause: TTL — clients/resolvers still hold the old RRset cached before
the change; also possible the app caches connections. Proof: `dig @<auth>`
shows new IP with full TTL; `dig @<resolver>` shows old IP with decrementing
TTL → resolver cache; `ipconfig /displaydns` shows old IP → client cache.
Fix: wait out TTL, or flush resolver cache (`rndc flushname`) + client flush;
process fix: lower TTL before planned changes. Trap: "the record wasn't
changed / EfficientIP failed" — disproven by the AA answer.

**C2.** Stale PTR: forward record was changed/deleted but reverse zone wasn't
updated (classic when forward/reverse are managed separately). Impact:
security tools, SSH/Kerberos reverse checks, mail servers, traceability all
mislead. Proof: `dig -x 10.10.20.15` vs `dig old-db.corp.example A`. Fix:
update/delete PTR in `20.10.10.in-addr.arpa`, add correct PTR for current
owner. Trap: "reverse DNS is broken/server issue" — the reverse *zone* works
fine; the data is stale.

**C3.** Broken/lame delegation of child zone `dev.corp.example`: parent NS
records point at servers not authoritative (decommissioned, moved, or child
zone never configured). Proof: `dig NS dev.corp.example @parent-auth` then
`dig SOA dev.corp.example @each-listed-NS +norecurse` → no AA answer.
Fix: correct NS (and glue) in parent, or restore zone on listed servers.
Trap: "resolver problem" — resolver SERVFAIL is a symptom; parent+child
disagreement is the cause.

**C4.** REFUSED on XFR → policy on the primary: (1) `allow-transfer` ACL
doesn't include the secondary's *source* IP (multi-homed secondaries bite
here) — prove with primary logs + `dig AXFR corp.example @10.10.0.10` from
the secondary; (2) TSIG required/mismatched key (name, secret, or clock skew)
— prove via primary security logs ("request has invalid signature" vs plain
REFUSED) and a keyed test transfer. Fix accordingly. Trap: "network/TCP
blocked" — TCP connected (you got REFUSED, not timeout).

**C5.** Split-horizon. Leak causes: (1) clients using the wrong resolver
(DHCP scope option pointing outside, VPN split-DNS misconfig, hardcoded
8.8.8.8); (2) view/ACL mismatch — client source IP (e.g., a new subnet or
NAT) not matched by the internal view's match-clients, falling through to the
external view. Proof: identify which resolver the failing client actually
used (`Resolve-DnsName ... -Server`, ipconfig /all), then query each view
directly. Trap: "record was changed" — it differs by *vantage point*, not
time.

**C6.** Suspects in order: (1) firewall/ACL between 10.10.60.0/24 and the
resolver — prove with `tcpdump port 53` on the resolver (queries arriving?)
and traceroute/ping to port; (2) resolver ACL `allow-query`/`allow-recursion`
excluding that subnet — but that returns REFUSED, not timeout, so a *drop*
points at network; (3) routing/return-path asymmetry (resolver has no route
back). Proof discipline: timeout = packets lost somewhere; capture on both
ends decides which direction. Trap: "DNS server is down" — it answers another
subnet.

**C7.** Large responses exceed UDP/EDNS path capability → fragmentation drops
or TC=1 with TCP 53 blocked somewhere. dig +tcp working proves data + server
fine; transport is the issue. Fixes: allow TCP 53 through the path, and/or
cap EDNS buffer to 1232 so responses truncate cleanly to TCP instead of
fragmenting; long-term: split giant TXT/DKIM records into multiple strings /
review record size. Trap: "the record is corrupt/intermittently missing."

**C8.** Order: (1) `dig portal.ext.example @corp-resolver` → SERVFAIL; (2)
same query `+cd` (checking disabled) → if it resolves, DNSSEC validation is
the failure class, not reachability; (3) `delv portal.ext.example
@corp-resolver` (or against 8.8.8.8) → shows "fully validated" vs "resolution
failed: broken trust chain"; (4) inspect chain: `dig DS ext.example @parent`,
`dig DNSKEY ext.example +dnssec` — mismatched DS↔DNSKEY or expired RRSIG
(check inception/expiration) = domain's fault; (5) if delv validates fine
externally and only your resolver fails → your resolver (stale trust anchor,
clock skew, broken forwarder stripping DNSSEC). 8.8.8.8 also validates, so if
it *only* works there with `+cd`, the domain is bogus for everyone validating.

## Part D (model answers — grade against these)

**D1.** Excellent answer includes: browser asks OS stub → stub cache miss →
UDP query (rd=1) to configured resolver → resolver cache miss → iterative:
root (referral to TLD + NS/glue) → TLD (referral to corp.example NS + glue)
→ authoritative (aa=1 answer) → resolver caches all RRsets, replies (ra=1,
no aa, TTL starts decrementing) → stub caches → A and AAAA are separate
queries (often parallel) → EDNS OPT present throughout; TCP only if TC=1.

**D2.** Excellent: a bisection sequence with proofs — (1) query authoritative
directly: wrong there = data problem, stop; (2) right at auth → query each
recursive resolver directly: wrong = resolver cache (TTL decrementing old
RRset) → flush or wait; (3) right at resolver → client cache
(`ipconfig /displaydns`) → flush; (4) all DNS layers right but app fails →
app-side caching (JVM, connection pools, hosts file, pinned IPs); (5)
timeouts anywhere → network/firewall, prove with tcpdump both sides,
UDP vs TCP 53 separately.

**D3.** Excellent: A record `newapp.corp.example → 10.10.20.80` in zone
`corp.example` on the internal authoritative servers (in EfficientIP: the
record object in the right zone object on the right DNS server/smart
architecture, and the IPAM address object marked/assigned); PTR
`80.20.10.10.in-addr.arpa → newapp.corp.example` in the reverse zone (which
must exist and be delegated/served internally); serial increments +
propagation to secondaries; internal resolvers must be able to reach those
auth servers (forwarding/stub config for `corp.example` and
`10.in-addr.arpa`); TTL chosen consciously; no conflicting CNAME at the name.

**D4.** Apex must hold SOA and NS; CNAME must be alone at a node → CNAME at
apex is illegal and breaks resolution unpredictably. Instead: A/AAAA at apex
(possibly automated to track the target — "ALIAS/ANAME"-style flattening at
the provider), or move the service to a subdomain (`www`) where CNAME is
legal, or use HTTPS/SVCB where supported.

**D5.** Excellent covers: CSV syntactic validation (FQDN format, no
duplicates, IP format); every row pre-checked against authoritative — does
the record exist, does it match the CSV's IP exactly (name+type+value), is
anything else at that name (CNAME pointing to it? PTR? part of round-robin?);
dependency check — what references these names (CNAMEs targeting them, MX,
SRV); blast-radius question — are any still receiving queries (query logs)?;
change window + ticket; snapshot/export of current state = rollback artifact
(re-add file ready); staged execution (batch, verify, continue); post-check:
NXDOMAIN confirmed at auth, negative-TTL comms to app teams; rollback =
re-import snapshot + flush caches.

---

## SCORING RUBRIC (100 pts)

Per question: full points = precise, mechanism-level, correct terminology;
half = right idea, missing mechanism or proof; zero = vague, wrong, or "cache
issue" without naming which cache.

| Score | Level | What it means | Action |
|---|---|---|---|
| 0–39 | Below intermediate | Fundamentals gaps (resolution flow, TTL, negative caching) | Do NOT compress the calendar. Add +30 min/day of Level 1–2 flashcards for Weeks 1–4. Re-take this exam end of Week 4. |
| 40–59 | Intermediate (expected start) | You operate DNS but can't yet *prove* things | Follow the calendar exactly. Your enemy is vagueness — enforce the written-explanation step daily. |
| 60–79 | Strong intermediate | Mechanics OK; gaps in BIND internals, DNSSEC, delegation, enterprise workflow | Follow calendar; you may compress Weeks 1–2 lessons to 1.5h/day and bank time for Levels 4–8 labs. |
| 80–100 | Near-senior already | Verify honesty of self-grading with the oral pack (file 10) | Skip to Week 3 content but still build the full lab in Week 1; double ticket volume in Weeks 12–16. |

**Skill-gap interpretation by section:**
- Weak Part A → theory gap → Teacher Manual is your priority; don't hide in the lab.
- Weak Part B → evidence gap → Command Mastery Pack daily until flags are reflex.
- Weak Part C → diagnosis gap → double your ticket throughput (file 09) from Week 5.
- Weak Part D → articulation gap → never skip the written "explain to a senior" task; read answers aloud.

Log your score and per-section breakdown in `dns-journal/exams/2026-07-07-baseline.md`. You will re-take this exam on **1 November 2026** — target ≥90.
