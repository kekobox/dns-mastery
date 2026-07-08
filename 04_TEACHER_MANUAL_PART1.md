# SECTION 5 — TEACHER MANUAL, PART 1 (Levels 1–2)
### Packet 2b — Fundamentals → Records, Zones, Delegation, Reverse DNS
Quiz numbering matches the Daily Calendar exactly (TM 1 Q1–32, TM 2 Q1–36).

---

# CHAPTER 1 — DNS CORE MECHANICS

## TM 1.1 — The namespace tree; domain vs zone

**Explanation.** DNS is a distributed, hierarchical database. The *namespace*
is one global tree rooted at `.` (root). Every node is a label; an FQDN is the
path from a node to the root: `app1.corp.example.` — the trailing dot IS the
root. A **domain** is a subtree of the namespace (everything under
`corp.example`). A **zone** is the portion of a domain that one administrative
entity actually serves from one set of authoritative servers. Domains are
*names*; zones are *data + responsibility*. `corp.example` the domain includes
`dev.corp.example`; but if dev is delegated, the `corp.example` **zone** stops
at the delegation cut and the `dev.corp.example` **zone** begins.

**Enterprise analogy.** The domain is the org chart; zones are the departments
that actually manage their own staff lists. HQ (parent zone) doesn't keep the
Denmark team roster — it keeps a pointer: "for Denmark, ask the Denmark office"
(NS records at the cut).

**Senior version.** "A zone is the unit of authority, transfer, and signing.
Delegation creates zone cuts; the parent holds only NS (+ glue, + DS if
DNSSEC) for the child — everything below the cut is the child's authoritative
data, and the parent's copy of the NS set is non-authoritative."

**Misconceptions.** (1) "Domain = zone" — false whenever delegation exists.
(2) "The parent controls child content" — it controls only *where the child
is* (NS/DS). (3) "Subdomain requires delegation" — no: `a.b.corp.example` can
live inside the corp.example zone as an ordinary record; delegation is a
choice.

**Ops checklist:** know, for every name you manage, which zone it lives in and
where the nearest zone cut above it is.
**Troubleshooting checklist:** weird failures scoped exactly to one subtree →
suspect a zone cut (delegation) at that boundary.
**Mini lab:** LAB 0–1. **Quiz:** below with 1.2.

## TM 1.2 — The four roles: stub, recursive, forwarding, authoritative

**Explanation.**
- **Stub resolver:** the client OS library. Asks one question with RD=1,
  expects a finished answer, caches it. Cannot iterate.
- **Recursive resolver:** does the real work — iterates from root hints through
  referrals to the answer, caches everything, serves stubs. Sets RA=1.
- **Forwarding resolver:** a recursive-facing middleman that outsources
  recursion upstream (`forwarders`). It still caches. `forward only` = trust
  upstream or fail; `forward first` = try upstream, fall back to own iteration.
- **Authoritative server:** serves zone data it *owns*. Sets AA=1 for its
  zones. Best practice: recursion disabled.

**Analogy.** Stub = you asking a colleague. Recursive = the colleague who
phones HQ, then the regional office, then the site, and returns with the
answer. Forwarder = a colleague who always asks *their* trusted colleague.
Authoritative = the site office that actually holds the record book.

**Senior version.** "Role is per-query behavior, not per-box identity: one
BIND instance can be authoritative for some zones and recursive for clients —
common but discouraged because cache and authority failure domains mix, and
because open recursion on an authoritative edge is an amplification risk."

**Misconceptions.** "The DNS server" — which role? Most tickets die here.
"Non-authoritative answer = problem" — it's the *normal* output of the
recursive role.

**Quiz TM 1 Q1–8** (covers 1.1–1.2):
1. Define domain vs zone in ≤2 sentences.
2. What data does a parent zone hold about a delegated child?
3. Which role sets AA? Which sets RA? Which sends RD?
4. Why is recursion disabled on pure authoritative servers? (2 reasons)
5. `forward only` vs `forward first` under upstream failure — behavior of each?
6. Can `a.b.corp.example` exist without delegating `b`? Explain.
7. Which component caches: stub / recursive / forwarder / authoritative? 
8. A stub gets SERVFAIL. Which roles could have generated it?

**Key:** 1. Domain=subtree of namespace; zone=administratively served portion
bounded by cuts. 2. NS records (+ glue if in-bailiwick, + DS if signed).
3. AA=authoritative; RA=recursive/forwarder; RD=stub (and resolvers when
forwarding). 4. Amplification/abuse surface; separates failure domains &
cache-poisoning surface from authority. 5. only→SERVFAIL when upstream dead;
first→falls back to own iteration (needs hints). 6. Yes — any depth of labels
can live in one zone; delegation is optional. 7. Stub yes, recursive yes,
forwarder yes, authoritative no (it has the truth, not a cache). 8. Recursive
or forwarder (they generate SERVFAIL when they can't complete) — authoritative
servers can also return it for broken/expired zones; the stub only relays.

## TM 1.3 — Message anatomy: header, flags, four sections

**Explanation.** Every DNS message (query and response share the format):
**Header** (12 bytes): ID (16-bit match token), flags, and four counters.
**Sections:** QUESTION (qname/qtype/qclass), ANSWER (RRsets answering),
AUTHORITY (NS of the relevant zone, or SOA for negative answers), ADDITIONAL
(helper records: glue, plus the EDNS OPT pseudo-record lives here).

**Flags:** QR query(0)/response(1). **AA** authoritative answer — set by an
authoritative server answering from its zone. **TC** truncated — retry over
TCP. **RD** recursion desired — set by the querier, copied into the response.
**RA** recursion available — the responder offers recursion. **AD**
authenticated data — validating resolver asserts DNSSEC-validated. **CD**
checking disabled — querier says "don't validate, give me data anyway".
**RCODE:** NOERROR, NXDOMAIN, SERVFAIL, REFUSED, FORMERR, NOTIMP…

**Packet-level.** A response with ANSWER=0, RCODE=NOERROR, AUTHORITY=SOA is
**NODATA**. ANSWER=0, RCODE=NXDOMAIN, AUTHORITY=SOA is **NXDOMAIN**. ANSWER=0
with AUTHORITY=NS + ADDITIONAL=A (no AA answer) is a **referral** — the bread
of iteration.

**Senior version.** "I read responses in this order: RCODE → AA → counts →
sections → TTLs. That sequence alone classifies ~80% of situations:
authoritative truth, cached copy, referral, negative answer, or policy
refusal."

**Misconceptions.** RD=1 in a response doesn't mean recursion happened — it's
an echo. AD is about DNSSEC, not "admin data". REFUSED is policy, not failure.

**Quiz TM 1 Q9–16:**
9. Who sets RD and who sets RA?
10. Response: NOERROR, ANSWER 0, AUTHORITY holds an SOA. Name it.
11. Response: ANSWER 0, AUTHORITY holds NS records, no AA. Name it.
12. What two things does the OPT record in ADDITIONAL carry (name two)?
13. AA + which section proves an answer came from zone data?
14. What must a client do on TC=1?
15. Difference in meaning: AD set by resolver vs CD set by client.
16. Why is the 16-bit ID alone insufficient anti-spoofing, and what else is
    randomized?

**Key:** 9. RD: querier; RA: responder. 10. NODATA. 11. Referral.
12. UDP buffer size, EDNS version/flags (DO bit), options (e.g., cookies).
13. AA flag with the answer in ANSWER; TTL at full original value corroborates.
14. Retry the query over TCP. 15. AD: responder validated DNSSEC; CD: querier
requests validation be skipped. 16. 65k IDs are brute-forceable; source-port
randomization adds ~16 more bits (Kaminsky-era fix).

## TM 1.4 — Iterative resolution: root → TLD → authoritative; referrals & glue

**Explanation (flow, cold cache, `app1.corp.example` A):**
1. Stub → resolver: `app1.corp.example A?` RD=1.
2. Resolver cache miss → picks a root from **hints** (bootstrap list of root
   names/IPs) → asks root the SAME question.
3. Root doesn't know app1; it knows `example.` → **referral**: AUTHORITY=
   `example. NS ns.tld.`, ADDITIONAL=glue `ns.tld. A …`. Resolver caches the
   NS set + glue.
4. Resolver → TLD server, same question → referral to `corp.example NS
   ns1.corp.example` + glue.
5. Resolver → ns1.corp.example → **AA answer** `app1 A 10.10.20.15 TTL 300`.
6. Resolver caches the RRset, answers the stub (RA=1, no AA, TTL starts
   draining). Stub caches too.

**Glue:** if the NS name lives *inside* the zone being delegated
(in-bailiwick), the parent MUST supply its address, or resolution is circular.
Glue is hint data, not authoritative — the child's own copy is authoritative.

**Senior version.** "Recursion is a service; iteration is the mechanism. The
resolver converts one recursive question into a chain of iterative questions,
each answered by a referral until an AA answer or a negative answer
terminates it. Every referral is cached, which is why the second query for a
sibling name skips root and TLD entirely — and why root servers survive."

**Misconceptions.** Clients never talk to root. `dig +trace` bypasses your
resolver (dig iterates itself). Roots don't "know all DNS" — they know only
TLD delegations.

**Mini lab:** LAB 1 `+trace` walk. **Self-test:** redraw the 6-step flow with
flags/caches from memory (Day 4 proof).

## TM 1.5 — Transport: UDP 53, TCP 53, truncation, EDNS(0), fragmentation

**Explanation.** DNS default: UDP, one datagram each way — historically max
512 bytes. Too big → server sets **TC=1** and the client retries over **TCP
53**. **EDNS(0)** (OPT pseudo-record) lets the client advertise a larger UDP
buffer (commonly 1232 today) and carries the DNSSEC **DO** bit. Responses
bigger than the path can carry unfragmented get IP-fragmented; fragments are
widely dropped (firewalls, PMTU) → silent timeouts. Hence modern practice:
advertise ~1232, let anything larger truncate cleanly to TCP. **Zone
transfers are always TCP.** DoT=TCP 853, DoH=HTTPS/443 (Chapter 3).

**Enterprise consequence.** "Allow UDP 53, block TCP 53" is a latent bomb:
everything works until DNSSEC, fat TXT/DKIM, or a transfer — then
intermittent, size-dependent failures that look haunted.

**Senior version.** "My transport triage: does it fail only for large
answers? `dig +tcp` fixes it? Then it's truncation/fragmentation/TCP-blocked,
not data. Buffer matrix (512/1232/4096/+tcp) localizes it in four commands."

**Misconceptions.** "DNS is UDP" — DNS is UDP *first*. "TCP 53 is only for
transfers" — false since forever, and fatal since DNSSEC.

**Quiz TM 1 Q17–22:**
17. Three triggers for DNS over TCP.
18. Who advertises the EDNS buffer size?
19. Why is 1232 the common advertised size?
20. Symptom pattern of dropped fragments vs blocked TCP 53 — distinguish them.
21. What does the DO bit request?
22. dig shows `;; Truncated, retrying in TCP mode.` — is the server broken?

**Key:** 17. TC=1 retry; AXFR/IXFR; client/resolver policy after UDP issues
(also DoT by design). 18. The client/querier (in its OPT record). 19. Fits
typical MTU minus headers → avoids IP fragmentation on nearly all paths.
20. Fragment drops: UDP query sent, no reply at all for big answers (timeout),
small answers fine, +tcp works. Blocked TCP: TC=1 arrives, then the TCP retry
times out/refuses. 21. DNSSEC records (RRSIG etc.) included in responses.
22. No — correct protocol behavior; investigate only if the TCP retry fails.

## TM 1.6 — Every cache between app and zone data

**Explanation.** Layered caches, each with its own flush:
1. **Application** (browser, JVM `networkaddress.cache.ttl`, connection pools,
   pinned IPs) — restart/app-specific.
2. **OS stub cache** — Windows DNS Client (`Clear-DnsClientCache`),
   systemd-resolved (`resolvectl flush-caches`).
3. **Forwarder cache** — `rndc flushname` on the forwarder.
4. **Recursive resolver cache** — `rndc flushname/flushtree/flush`.
5. **Negative cache** — lives inside 2–4; NXDOMAIN/NODATA entries with their
   own TTL (SOA minimum).
Zone data itself is not a cache — it's the source.

**Senior version.** "Staleness is never mysterious: enumerate the caches on
the path, query each layer directly, find the deepest layer still serving old
data, flush from the bottom up (fixing the resolver first, then clients —
otherwise clients immediately re-cache the stale upstream answer)."

**Misconception.** "I flushed DNS" — which of the five? Flushing the client
while the resolver is stale achieves a 2-second illusion.

**Mini lab:** Day 8 cache-map build; LAB 6. (No numbered quiz — the cache map
is the assessment.)

## TM 1.7 — Linux resolver stack

**Explanation.** Layers: applications call **glibc** (getaddrinfo), which
consults **/etc/nsswitch.conf** (`hosts: files dns` → /etc/hosts wins first),
then **/etc/resolv.conf** (nameserver list, `search` domains, options
timeout/attempts/rotate). Modern distros insert **systemd-resolved**: a local
stub on **127.0.0.53** with its own cache and **per-link split DNS** (domain
routing per interface — VPN magic and VPN misery). Key tools: `resolvectl
status`, `resolvectl query`, `resolvectl flush-caches`, `getent hosts <name>`
(exercises the real NSS path — what apps see) vs `dig` (talks straight to a
server, ignores nsswitch and /etc/hosts).

**Classic trap.** `dig` works, `ping <name>` fails → /etc/hosts entry or
nsswitch/mDNS interference — DNS server is innocent. The reverse (ping works,
dig odd) → hosts-file mask hiding a DNS problem.

**Senior version.** "On Linux I establish which path the app uses: getent
first (truth as apps see it), then resolvectl to see which uplink+cache
handled it, dig only to interrogate specific servers."

**Quiz TM 1 Q23–27:**
23. Why can dig and ping disagree on the same name?
24. What is 127.0.0.53?
25. Which file/line makes /etc/hosts win over DNS?
26. Command that resolves a name via the same path applications use?
27. Where does per-interface split DNS live and what problem does it solve?

**Key:** 23. dig bypasses NSS (/etc/hosts, mDNS, resolved routing); ping uses
it. 24. systemd-resolved's local stub listener (its own cache + routing).
25. nsswitch.conf `hosts: files dns`. 26. `getent hosts NAME` (or ahosts).
27. systemd-resolved per-link domains; routes e.g. *.corp.example to VPN DNS
while general traffic uses the LAN resolver.

## TM 1.8 — Windows resolver behavior

**Explanation.** The **DNS Client service** caches positive AND negative
answers (`Get-DnsClientCache`, `ipconfig /displaydns`, flush with
`Clear-DnsClientCache` / `ipconfig /flushdns`). **Suffix search list:**
a short name `app1` is tried as `app1.<primary suffix>`, then connection-
specific suffixes / configured search list — so "app1 works in Madrid, fails
in Luxembourg" is often suffix policy, not DNS data. Multi-NIC: Windows picks
resolvers per interface/binding order — VPN adapters (and NRPT, the Name
Resolution Policy Table, which force-routes specific namespaces) override
expectations. LLMNR/mDNS answer single-label names when DNS fails — masking
or muddying diagnoses. Hosts file: `C:\Windows\System32\drivers\etc\hosts`
beats everything.

**Senior version.** "For a Windows client mystery: what name was *actually*
queried (suffix expansion — check with `Resolve-DnsName app1 -DnsOnly` and
watch it iterate suffixes), against *which* server (multi-NIC/VPN/NRPT), and
is the answer from cache (`Get-DnsClientCache`) or the wire?"

**Mini lab:** Day 10 suffix experiments. (Assessment = experiment log.)

## TM 1.9 — RD/RA semantics, cache inspection, anti-spoofing

**Explanation.** `dig +norecurse` sends RD=0: "answer only if you already
have it." Against a resolver this is a **cache X-ray**: cache hit → answer
with draining TTL; miss → referral-ish/empty NOERROR, and crucially the
resolver does NOT go fetch it. Uses: prove what a resolver has cached without
polluting the experiment; check whether *someone* recently queried a name
(pre-deletion blast-radius trick); compare caches across a resolver farm
(each VIP member answers differently — same technique exposes it).
Anti-spoofing recap: random ID + random source port + (properly) DNSSEC.

**Misconception.** "The resolver answered, so it's authoritative for the
zone" — resolvers answer for everything; AA and zone config decide authority.

**Quiz TM 1 Q28–32:**
28. What exactly does +norecurse ask, in flag terms?
29. Two operational uses of +norecurse against a resolver farm.
30. +norecurse returns the record with TTL 112, zone TTL is 300 — conclusions?
31. Why can two consecutive +norecurse queries to one VIP disagree?
32. A resolver returns an answer for a zone it doesn't host. Fault?

**Key:** 28. RD=0 — do not recurse on my behalf. 29. Cache inspection
(is stale data present? which node has it?); pre-change evidence that a name
is in active use. 30. Cached 188 s ago by that resolver; someone queried it
then. 31. VIP/anycast members hold independent caches. 32. No fault —
caching recursion is its job; "non-authoritative" ≠ wrong.

---

# CHAPTER 2 — RECORDS, ZONES, DELEGATION, REVERSE

## TM 2.1 — SOA: the zone's contract

**Explanation.** One SOA per zone, at the apex. Fields:
- **MNAME** primary server name; **RNAME** admin mailbox (first dot = @).
- **SERIAL** — version number. Secondaries transfer only when it INCREASES
  (serial arithmetic, RFC 1982). Convention YYYYMMDDnn. Forgotten increment =
  silent divergence; decreased serial = secondaries frozen (2^31-add recovery).
- **REFRESH** — how often secondaries poll SOA if no NOTIFY arrives.
- **RETRY** — poll interval after a failed refresh.
- **EXPIRE** — how long a secondary keeps serving without ANY successful
  refresh; after this it SERVFAILs the zone. This is your real DR deadline.
- **MINIMUM** — since RFC 2308: the **negative-caching TTL** (capped by the
  SOA record's own TTL).

**Analogy.** SOA = the zone's service contract: version stamp, sync schedule,
abandonment clause (expire), and "how long to remember a 'no'" (minimum).

**Senior version.** "Expire vs refresh ratio defines tolerance to primary
outage; minimum defines how painful deletions/creations feel; serial
discipline is the whole replication protocol — three numbers most people
never read govern most replication incidents."

**Traps.** Serial typo `2026070` sorting backwards; MINIMUM=86400 making
every new-record rollout 'broken' for a day; EXPIRE shorter than a long
weekend + dead primary = Monday outage.

**Quiz TM 2 Q1–6:**
1. Which SOA field is the negative-cache TTL and what caps it?
2. Secondary never updates though you edited the zone — first SOA suspect?
3. Explain EXPIRE's operational meaning in one sentence.
4. What happens when a serial is set LOWER than before, and one recovery?
5. When does RETRY apply instead of REFRESH?
6. Primary dead Friday 18:00, expire=604800 — when do secondaries go dark?

**Key:** 1. MINIMUM, capped by the SOA's own TTL. 2. Serial not incremented.
3. How long secondaries serve stale-but-working data with the primary
unreachable before refusing (SERVFAIL). 4. Secondaries ignore "older" data —
add 2^31, let it propagate, then set the target value (or force retransfer
per secondary). 5. After a refresh attempt fails, until success.
6. Following Friday ~18:00 (per secondary, from its last successful refresh).

## TM 2.2 — A/AAAA, CNAME, and the apex problem

**Explanation.** **A** name→IPv4, **AAAA** name→IPv6 — separate RRsets,
separate queries. Multiple A records at one name = one RRset = round-robin
(order rotated by servers/resolvers) — NOT duplicates. **CNAME** aliases the
entire node: "for ANY type at this name, go ask the canonical name." Hence
the rule: **CNAME must be alone at its node** (DNSSEC's RRSIG/NSEC are the
exception). Corollaries: no CNAME at zone **apex** (SOA+NS must live there);
no other records beside a CNAME; MX/NS targets must be hostnames with
A/AAAA, **not** CNAMEs. Resolution of a CNAME chain: resolver follows it and
returns the chain + final RRset in one answer.

**Apex workarounds:** A/AAAA directly (maybe provider-flattened
"ALIAS/ANAME" — a server-side lookup masquerading as A), move service to
`www`, or SVCB/HTTPS records where the ecosystem supports them.

**Traps.** "Two A records with different IPs is a duplicate error" —
sometimes it's intentional round-robin; deleting one member "as cleanup"
halves capacity. Distinguish by asking the owner + checking both IPs serve.

**Quiz TM 2 Q7–12:**
7. Why exactly is CNAME-at-apex illegal?
8. Two A records, same name, different IPs — name the two possible realities
   and how you distinguish them.
9. Can a name have both CNAME and TXT? Exception?
10. Why must MX targets not be CNAMEs?
11. Client asks A for a name that is a CNAME to a name with only AAAA —
    result?
12. What is "CNAME flattening / ALIAS" conceptually?

**Key:** 7. Apex must hold SOA+NS; CNAME forbids coexisting data → conflict.
8. Intentional round-robin vs stale-duplicate; distinguish via owner intent,
whether both IPs serve the app, IPAM records, change history. 9. No —
CNAME-and-other-data violation; exception: DNSSEC metadata (RRSIG/NSEC).
10. Standards forbid it; extra lookups and broken/undefined mail behavior in
practice. 11. NODATA for A (chain followed, target has no A). 12. Provider
resolves the alias target itself and publishes the result as apex A records.

## TM 2.3 — Mail records: MX, and SPF/DKIM/DMARC as DNS objects

**Explanation.** **MX** `preference target` — lowest preference wins; target
must resolve to A/AAAA. Mail flows to MX targets; the domain itself needs no
A record for mail. As DNS objects (you operate the records; mail teams own
the content):
- **SPF** — TXT at the domain apex: `v=spf1 …` — which senders may emit mail
  for the domain. ONE spf TXT only; two = permerror.
- **DKIM** — TXT at `<selector>._domainkey.domain` holding a public key —
  long, hence multiple quoted 255-byte strings in one TXT record
  (concatenated by consumers). Copy-paste truncation is the classic incident.
- **DMARC** — TXT at `_dmarc.domain`: policy tying SPF/DKIM results.

**Traps.** TXT strings >255 chars must be split into multiple quoted strings;
missing quotes or a swallowed segment breaks DKIM invisibly. Deleting "some
random TXT" that is the SPF = mail rejected globally. MX pointing at a CNAME.

**Quiz TM 2 Q13–18:**
13. Which MX preference is tried first?
14. Where exactly does a DKIM record live?
15. Why are big TXT records written as multiple quoted strings?
16. Two `v=spf1` TXT records at the apex — result?
17. What does the DNS engineer own vs the mail team in SPF changes?
18. Risk statement for "delete unused TXT records" as a cleanup ticket?

**Key:** 13. Lowest number. 14. `<selector>._domainkey.<domain>` TXT.
15. Protocol caps each character-string at 255 bytes; consumers concatenate.
16. SPF permanent error — treated as broken policy. 17. Engineer: record
syntax/placement/TTL/change safety; mail team: policy content semantics.
18. TXT hosts SPF/DKIM/DMARC/verification tokens — deletion can stop mail
flow or break domain verifications; every TXT needs an owner sign-off.

## TM 2.4 — SRV, CAA, NAPTR, wildcards

**Explanation.** **SRV** `_service._proto.name TTL IN SRV priority weight
port target` — service discovery (AD lives on this: `_ldap._tcp`,
`_kerberos._tcp`); target must be a hostname with A/AAAA (not CNAME).
Priority like MX; weight load-shares within a priority; port decouples
service from :standard-port. **CAA** — which CAs may issue certs for the
domain (`0 issue "letsencrypt.org"`); checked at issuance time, walks up
parent labels until a CAA is found. **NAPTR** — regex-based rewriting, telco
land (ENUM/SIP) — know it exists, read one example, move on. **Wildcards**
`*.apps` — synthesize answers for NONEXISTENT names below the owner.
Subtleties: a wildcard does NOT apply where the exact name exists (with any
type — existing `x.apps` with only TXT means A query for x.apps = NODATA,
not wildcard A); wildcards don't cover the owner name itself; they don't
descend past existing names ("closest encloser" logic).

**Traps.** Wildcard hides typo-NXDOMAINs (everything resolves → apps connect
to wrong place instead of failing loudly). AD outage tickets that are really
one missing SRV. CAA forgotten → cert issuance mysteriously refused.

**Quiz TM 2 Q19–24:**
19. Decode every field: `_sip._tcp 300 IN SRV 10 60 5061 sip1.corp.example.`
20. Two SRVs, priorities 10 and 20 — when is 20 used?
21. `x.apps.corp.example` exists as TXT only; wildcard `*.apps` has A.
    Query A for x.apps — answer?
22. Why are wildcards operationally dangerous in corp zones?
23. What does CAA control, and who consults it?
24. Where does AD's dependence on DNS concretely live?

**Key:** 19. Service sip over tcp, TTL 300, priority 10, weight 60, port
5061, host sip1. 20. Only when all priority-10 targets are unreachable.
21. NODATA — the name exists, wildcard doesn't apply. 22. They convert typos
and decommissioned names into "successful" resolutions → silent misrouting;
they also complicate audits. 23. Which CAs may issue certificates; CAs check
it during issuance. 24. SRV records (_ldap/_kerberos/_gc…) published by DCs —
clients locate services purely via DNS.

## TM 2.5 — Zone file syntax: $TTL, $ORIGIN, relative names, the dot

**Explanation.** `$TTL` default TTL for records lacking one. `$ORIGIN` the
suffix appended to every **relative** (dot-less) name. `@` = current origin.
The **trailing dot** makes a name absolute. THE bug: writing
`www IN CNAME portal.corp.example` (no dot) inside corp.example →
target becomes `portal.corp.example.corp.example.` — resolves as NXDOMAIN
somewhere weird and burns an hour. Multi-line records use `( )` (SOA, DKIM).
Comments `;`. Validation before load, always:
`named-checkzone corp.example db.corp.example` and `named-checkconf`.

**Senior habit.** Never hand-edit → reload in one step: edit → checkzone →
serial++ → reload → dig the changed name at the authority → THEN declare done.

**Mini lab:** Day 18 five-breaks drill. (Assessment = the five break/fix
pairs; no numbered quiz.)

## TM 2.6 — Delegation mechanics

**Explanation.** Delegation = NS records for the child placed in the PARENT at
the cut point, plus glue when in-bailiwick. The parent's NS set for the child
is non-authoritative (the authoritative copy is in the child at its apex —
and yes, they can disagree: the child's is authoritative, but resolvers
learn the parent's first; keep them identical). A query hitting the parent
for anything below the cut gets a referral, never an answer (AA won't be set
for child names).

**Senior version.** "Delegation health = parent NS set, child NS set, and
reality (which servers actually answer AA) all agree. Any two disagreeing is
an incident waiting; I check all three, not just one."

**Quiz TM 2 Q25–30:**
25. Where do the child's NS records exist, and which copy is authoritative?
26. When is glue mandatory (term + reason)?
27. Parent lists ns1+ns2; child apex lists only ns1. Consequences?
28. What response does the parent give for `x.dev.corp.example` A?
29. Is glue served with AA by the parent? Why (not)?
30. Command sequence to audit a delegation end-to-end.

**Key:** 25. Both parent (delegation) and child apex; the CHILD's is
authoritative. 26. In-bailiwick NS names (inside the delegated zone) —
circular dependency otherwise. 27. Resolvers using the parent set may try
ns2; if ns2 isn't serving, intermittent lameness; also DNSSEC/consistency
warnings — fix to identical sets. 28. Referral: AUTHORITY=dev NS set,
ADDITIONAL=glue, no AA. 29. No — below the cut it's hint data, not the
parent's authority. 30. `dig NS dev.corp.example @parent-auth +norecurse`
(parent view) → `dig NS dev.corp.example @each-child-NS +norecurse` (child
view, expect AA) → `dig SOA dev.corp.example @each-listed-NS` (reality:
every listed server answers AA).

## TM 2.7 — Lame delegation

**Explanation.** A delegation is lame when a parent-listed NS does not
answer authoritatively for the zone: server down, server up-but-no-zone
(answers REFUSED or non-AA), wrong/missing glue. Client experience depends
on how many of the NS set are lame: all → SERVFAIL; some → intermittent
slowness/failures as resolvers iterate the set (resolvers do track and
de-prioritize lame servers, which makes symptoms flappy and confusing).

**Diagnosis pattern:** enumerate parent NS set → test EACH listed server
directly with `+norecurse` expecting AA SOA → the ones failing that test are
the lame ones. Fix at whichever side is wrong: parent data (stale NS/glue)
or child side (zone not configured/loaded).

**Mini lab:** LAB 3b (three break variants). Assessment = the three
diagnosis logs.

## TM 2.8 — Reverse DNS: in-addr.arpa, PTR, classless delegation

**Explanation.** Reverse mapping is just DNS in a special tree:
IPv4 `10.10.20.15` → reverse the octets → `15.20.10.10.in-addr.arpa PTR`.
Zones typically per-/24 (`20.10.10.in-addr.arpa`) or per-/16
(`10.10.in-addr.arpa`). IPv6 uses `ip6.arpa` with reversed nibbles. Nothing
in the protocol ties PTR to A — consistency is purely operational (this is
where IPAM earns its keep). **RFC 2317** (classless): delegating a sub-/24
(e.g. a /28) via CNAMEs from the /24 zone into a named child zone — know the
pattern, it appears in ISP handoffs. Consumers of reverse: mail servers
(spam scoring), Kerberos/SSH checks (historically), logging/monitoring/
security tooling, traceroute readability.

**Traps.** Reverse "broken" is usually reverse **stale** — the zone works,
the data wasn't maintained during a forward change. Multiple PTRs at one IP:
legal, but breaks naive tooling — policy: one PTR, matching forward.

**Quiz TM 2 Q31–36:**
31. Construct the PTR owner name for 192.168.50.11.
32. Why doesn't deleting an A record remove its PTR?
33. Who actually suffers when reverse is stale (three consumers)?
34. What problem does RFC 2317 solve, and with which record type trick?
35. Forward says app1→10.10.20.15; `-x 10.10.20.15` → old-db. Which zone do
    you edit and what two edits?
36. Your resolver can't resolve internal reverse zones though auth1 serves
    them — why (in this lab and in real enterprises), and the fix pattern?

**Key:** 31. `11.50.168.192.in-addr.arpa.` 32. Different zone, different
RRset; protocol has no linkage — only IPAM/process links them.
33. Mail delivery (reverse checks), security/SIEM attribution, admins
reading logs/traceroutes (also some auth systems). 34. Delegating reverse
for less than a /24: parent /24 zone CNAMEs each address into a child zone
the customer controls. 35. Edit `20.10.10.in-addr.arpa`: delete PTR 15→old-db,
add PTR 15→app1.corp.example. (+serial++). 36. RFC1918 reverse isn't in the
public/root tree — resolvers need explicit routing (static-stub/forward
zones or internal delegation) to the internal authorities; add those zone
statements on the resolver.

## TM 2.9 — NXDOMAIN vs NODATA vs wildcard; negative caching (first pass)

**Explanation.** NXDOMAIN: the NAME doesn't exist (no type at it, and —
subtlety — no names BELOW it either... actually: NXDOMAIN asserts the exact
name has no records AND, note, a name "exists" if any type or any descendant
exists: `a.b.corp.example` existing makes `b.corp.example` an **empty
non-terminal**, which returns NODATA, not NXDOMAIN). NODATA: name exists,
not that type. Wildcards synthesize positives for nonexistent names in
scope, converting would-be NXDOMAINs into answers. Both negatives are cached
per SOA-minimum (RFC 2308) with the covering SOA attached as proof/timer.
Operational corollary: creating a record that clients were already querying
inherits negative-cache latency; the fix conversation with app teams is a
*timeline*, not an apology.

**Mini lab:** LAB 5 measurement + Day 24 drill (produce all three answer
classes on demand). Assessment = timed experiment log + written A3/A4.

---
**End of Part 1.** Part 2 (Chapter 3: recursion/caching/forwarding/
split-horizon/EDNS deep dives, Linux/Windows quirks) arrives in Packet 3
with the Command Mastery Pack.
