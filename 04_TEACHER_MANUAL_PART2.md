# SECTION 5 — TEACHER MANUAL, PART 2 (Level 3)
### Packet 3a — Recursive, Caching, Forwarding, Split-Horizon
Quiz numbering matches the Daily Calendar (TM 3 Q1–25).

---

# CHAPTER 3 — RECURSION, CACHING, FORWARDING, SPLIT-HORIZON

## TM 3.1 — Resolver cache internals

**Explanation.** A resolver caches **RRsets**, not "queries" and not whole
answers: the final answer RRset, every NS set learned from referrals, every
glue/nameserver address, CNAME links, and negative entries. Each RRset
carries its remaining TTL and decrements per second. A later query for a
*sibling* name reuses the cached NS/address RRsets and goes straight to the
authoritative server — this is why roots/TLDs see so little traffic and why
"the second query is fast."

Reading a live cache: `rndc dumpdb -cache` writes
`/var/cache/bind/named_run/...` or the configured dump file
(in the lab: `docker exec resolver1 rndc dumpdb -cache` then
`docker exec resolver1 sh -c 'cat /var/cache/bind/named_dump.db | less'`).
In the dump you'll recognize: RRsets with current TTLs, `; glue` markers,
negative entries shown as `;-$NXRRSET`/NXDOMAIN annotations with the covering
SOA, and server-selection metadata (RTT tracking — the resolver remembers
which authoritative servers are fast/lame).

**Enterprise analogy.** The cache is not a photocopy of one document — it's
the clerk's entire memory: the answer, the directory pages used to find it,
and a private note about which offices answer the phone quickly.

**Misconceptions.** (1) "Flushing removes one answer" — `rndc flush` empties
*everything*, forcing a cold-start stampede against roots/forwarders at 9 AM;
`flushname` removes one name, `flushtree` a subtree. (2) "Cache is shared
across the farm" — each node behind a VIP has an independent cache. (3) "The
resolver re-checks the authority when suspicious" — it never does before TTL
expiry; the TTL is a contract.

**Senior version.** "Cache state explains 'impossible' behavior: two users on
two resolver nodes get different answers because caches are per-node and were
populated at different times relative to a change. I check per-node with
direct queries, never through the VIP."

**Ops checklist:** know your dump command, your per-node access method (bypass
VIP), and your flush granularity options before an incident, not during.
**Troubleshooting checklist:** wrong answer at resolver → `+norecurse` to
X-ray → dumpdb if you need the exact remaining TTL/provenance → flushname →
re-verify → THEN find why the authority served the old data long enough to
be cached.

**Mini lab:** Day 28 dump reading. **Quiz TM 3 Q1–5:**
1. Name four categories of data a resolver caches beyond final answers.
2. Why is the second query for a sibling name faster? Be mechanism-precise.
3. rndc flush vs flushname vs flushtree — blast radius of each?
4. Two resolver nodes behind one VIP answer differently — is that a fault?
5. What non-record metadata does a resolver keep about authoritative servers?

**Key:** 1. NS sets from referrals, nameserver A/AAAA (incl. glue), CNAME
links, negative entries (+SOA), (also DS/DNSKEY when validating). 2. The
NS+address RRsets for the zone are cached, so the resolver skips root/TLD
and queries the zone's authority directly. 3. flush: whole cache (stampede
risk); flushname: exact name; flushtree: name + everything below. 4. No —
independent caches populated at different times; a fault only if it persists
past TTL. 5. RTT/lameness tracking used for server selection.

## TM 3.2 — Negative caching mastery (RFC 2308)

**Explanation.** Negative answers are cached like positives, with TTL =
min(SOA MINIMUM, TTL of the SOA record itself), taken from the SOA the
authority attaches in AUTHORITY. Two species: NXDOMAIN (name doesn't exist)
and NODATA (name exists, type doesn't). Both are per-⟨name,type⟩ for NODATA
and per-name for NXDOMAIN.

**The operational timeline that matters** (record creation): T-30m app team
queries `newapp.corp.example` "to check" → resolver caches NXDOMAIN for 900 s
→ T-0 you create the record, auth answers instantly → app team retests at
T+1m via the same resolver → STILL NXDOMAIN → ticket says "DNS change didn't
work." Nothing is broken. Your options: wait it out, `rndc flushname` on each
resolver node, or (process fix) create records *before* anyone tests, and
keep SOA MINIMUM modest (300–900 in dynamic estates).

**Senior version.** "Deletions haunt through positive TTL; creations haunt
through negative TTL. I quote both windows in every change ticket so 'still
broken' reports self-answer."

**Traps.** MINIMUM=86400 "to reduce load" → every rollout looks broken for a
day. Flushing the client but not the resolver → NXDOMAIN re-cached instantly.
Forgetting forwarders also hold negative entries.

**Mini lab:** LAB 5 (measured). Assessment: your measured table + the written
comms paragraph you'd send an app team.

## TM 3.3 — Stale-cache anatomy: the change-propagation timeline

**Explanation.** After an authoritative change at T0, the estate converges
layer by layer, and every layer is *correctly* serving its contract:
- Authoritative primary: new data at T0. Secondaries: after NOTIFY+transfer
  (seconds) — or after REFRESH if NOTIFY is lost.
- Each resolver node: whenever its cached copy expires — anywhere from T0
  (wasn't cached) to T0+oldTTL (cached at the worst moment). Population is
  *per node*.
- Each client stub: its own cached TTL on top; Windows may serve its copy
  until expiry even though the resolver already updated.
- Applications: whatever they pinned (JVM default can be forever without
  security-property tuning; connection pools hold established sockets to the
  old IP indefinitely — DNS was consulted once, at connect time).
Worst-case client convergence ≈ secondary-lag + resolver TTL + client TTL +
app behavior. THIS is the answer to "why do half the clients still hit the
old IP" — different nodes/clients cached at different times.

**Senior version.** "Propagation isn't a wave DNS pushes — it's a million
independent countdowns expiring. I can predict the last straggler's time to
the second from TTL math, and anything stale *beyond* that window is a real
fault (forwarder ignoring TTLs, app pinning, hosts file)."

**Mini lab:** LAB 6 with the timestamp table. Assessment: your timeline +
the C1 written diagnosis.

## TM 3.4 — TTL strategy

**Explanation.** TTL trades agility against load/latency/dependency-risk:
- Long TTL (3600–86400): fewer queries, resilience to resolver outages
  (cached answers survive), but changes/failover crawl.
- Short TTL (30–300): fast changes/failover, but constant re-resolution,
  higher exposure to resolver blips, and some resolvers/clients enforce
  floors on very low TTLs.
Policy that works in enterprises: stable infra records 3600; app records
300; records under GSLB/failover 30–60; SOA MINIMUM 300–900.
**The ramp-down ceremony** for a planned change at T: at T−(oldTTL)+margin,
lower TTL (e.g. 300→60). Wait ≥ oldTTL so every cached copy carries the new
short TTL. Execute the change → worst staleness now 60 s. After soak,
restore normal TTL. The classic error: lowering TTL 10 minutes before the
window — the old 300/3600-TTL copies don't care about your new intention.

**Round-robin interaction:** the TTL governs the whole RRset; resolvers may
rotate order per response — deleting one member mid-TTL still leaves it in
cached sets until expiry.

**Quiz TM 3 Q6–10:**
6. Why must TTL be lowered at least one *old* TTL before the change window?
7. Give a defensible TTL for: core router loopback A, app VIP under
   failover, SOA MINIMUM in a fast-moving internal estate.
8. Name two costs of setting everything to 60 s.
9. A record's TTL was 86400; change executed 2 h after lowering to 300.
   Worst-case client staleness?
10. Why can a deleted round-robin member still receive traffic for a while?

**Key:** 6. Caches holding the old-TTL copy keep it for that long; only
copies fetched *after* the lowering carry the short TTL. 7. ~3600–86400;
30–60; 300–900. 8. Query-load/latency increase; brittleness during resolver
or upstream outages (nothing survives in cache); some resolvers clamp
anyway. 9. Up to ~86400 s from the lowering for anyone who cached just
before it — i.e., the change can look unpropagated for up to a day; the 2 h
wait bought nothing for those clients. 10. Cached RRsets containing it live
until TTL expiry; connections already established persist beyond that.

## TM 3.5 — Forwarders

**Explanation.** A forwarder-configured resolver sends its recursion
upstream: query arrives → local cache check → miss → forward (RD=1) to
`forwarders {}` list → upstream recurses → answer returns → **cached locally
too** → served. Two caches now hold the data (double staleness surface,
double flush duty). `forward only`: upstream is the only path — upstream
dead ⇒ SERVFAIL. `forward first`: on upstream failure, fall back to own
iteration — requires working hints and outbound reachability, otherwise it's
`only` with extra steps. Forwarder trees (branch → country → central) add a
cache and a failure point per tier; each tier's logs show the hop.

**Why enterprises forward:** centralize internet egress/policy (RPZ,
logging, DNSSEC validation at one tier), let internal-only resolvers reach
internal + internet namespaces without direct internet DNS, and simplify
firewall rules (only central tier speaks to the world).

**Bisection method for a forwarding chain:** reproduce at the client → query
each tier *directly* with the same question → the first tier that fails
while its upstream succeeds owns the problem. Query logs (`rndc querylog
on`) at two adjacent tiers show whether the question even traveled.

**Quiz TM 3 Q11–15:**
11. Where can a stale answer live in a two-tier forwarding chain?
12. forward only vs first: which can mask an upstream outage, and at what cost?
13. Upstream refuses recursion to the forwarder (ACL). What does the CLIENT see?
14. Why does central-tier RPZ not protect clients that bypass the forwarders?
15. Describe the bisection method for "SERVFAIL through the chain" in ≤4 steps.

**Key:** 11. Both tiers' caches (and the client's). 12. `first` masks it by
iterating itself — cost: needs hints/egress, and behavior differs from the
designed policy path (RPZ/logging bypassed!). 13. Typically SERVFAIL from
the forwarder (it received REFUSED upstream and cannot complete). 14. RPZ
rewrites only on resolvers the client actually uses; direct/DoH resolution
skips it. 15. Reproduce at client → dig the forwarder directly → dig the
upstream directly → first failing tier with a working upstream is the owner;
confirm with querylogs both sides.

## TM 3.6 — Conditional forwarding, stub zones, AD coexistence

**Explanation.** Per-zone routing on a resolver, three tools:
- `zone X { type forward; forwarders {IP;}; }` — send queries for X to a
  server that will *recurse/answer* for X. If the target is authoritative-
  only with `recursion no`, plain forward still works **for names inside its
  zones** (it answers authoritatively) but any referral/child handling is on
  you — which is why:
- `type static-stub` (`server-addresses {IP;};`) — "treat IP as the
  authority for X and iterate below it" — the clean tool for pointing at
  internal authoritative servers.
- `type stub` — auto-learn the NS set of X from a listed server (rarely the
  right choice today; know it exists).
**AD coexistence pattern:** corporate resolvers conditionally route the AD
namespaces (`ad.corp.example`, `_msdcs...`, AD reverse zones) to domain
controllers, which are authoritative for them via AD-integrated zones; DCs
in turn forward everything non-AD back to the corporate resolvers. Loop risk
if both sides "forward the rest" carelessly — scope the conditional zones
tightly.

**Choosing:** delegation = namespace-level, visible to the world of that
tree, needs parent control. Conditional/static-stub = resolver-local policy,
invisible outside, per-resolver config burden. Enterprises use both: proper
delegation where a common parent exists; resolver policy for islands
(partner zones over VPN, AD, RFC1918 reverse).

**Mini lab:** LAB 7b (test both forward and static-stub against auth2 and
articulate the difference). Assessment: working config + written comparison.

## TM 3.7 — Failure modes in forwarding hierarchies

**Explanation — signature table (client's view / where to look):**
- **Upstream dead + forward only:** SERVFAIL after timeout-ish delay;
  forwarder log shows timeouts to upstream.
- **Upstream dead + forward first:** slow-then-works (fallback iteration) —
  or SERVFAIL anyway if no hints/egress; the "it's just slow" ticket.
- **Upstream ACL refuses forwarder:** fast SERVFAIL; tcpdump on forwarder
  shows REFUSED coming back — the forwarder can't relay REFUSED as-is for a
  recursion it owns, so the client sees SERVFAIL. (Contrast: a client
  DIRECTLY refused by a resolver sees REFUSED.)
- **One of N upstreams sick:** intermittent slowness — resolvers rotate/
  retry; RTT-based selection eventually shuns it; symptoms flap.
- **Forwarder cache poisoned-with-stale (post-change):** consistent wrong
  answer at one site only; upstream already correct — flush the *forwarder*.
- **MTU/fragment loss between tiers:** only large answers fail, +tcp works
  — LAB 9 signatures, but localized to the inter-tier path.

**Senior version.** "REFUSED vs SERVFAIL tells me *whose policy vs whose
failure*; where it appears tells me the tier. A REFUSED near the client is
client-facing ACL; a SERVFAIL at the client with REFUSED visible on the
inter-tier capture is an upstream ACL against the forwarder."

**Mini lab:** Day 37 four-way break drill. Assessment: the four captured
signatures, labeled.

## TM 3.8 — Internal vs external DNS architecture

**Explanation.** Enterprises run two DNS worlds:
- **External/public estate:** the zones the internet must see
  (corp.example public records: web, MX, SPF, DKIM). Served by hardened
  authoritative-only servers (often provider/cloud-hosted, anycast),
  registered in the public parent via the registrar. Minimal content —
  publish nothing internal.
- **Internal estate:** internal zones (lab.internal, internal branches of
  corp.example), RFC1918 reverse, AD namespaces — served by internal
  authoritative servers, reachable only inside; internal resolvers route to
  them (delegation or static-stub) and recurse/forward to the internet for
  the rest.
Same name, two truths (portal.corp.example) = split-horizon: either two
separate server sets (internal auth + external auth, most common, cleanest
failure isolation) or views on shared servers (TM 3.9).
**Data-flow answers a senior expects:** internal user → internal resolver:
internal name → static-stub/delegation → internal auth. Internet name →
resolver's own recursion or forwarding tier → out through allowed egress.
External user → public tree → external auth only; internal servers
unreachable and unpublished.

**Quiz TM 3 Q16–20:**
16. Why keep the external zone file minimal?
17. Two mechanisms to implement split-horizon; one advantage of each.
18. Internal user resolves www.some-internet-site: trace the path in your
    reference design.
19. Where does the public delegation of corp.example live and who controls it?
20. Name two ways internal names leak to the internet and one control for each.

**Key:** 16. Reconnaissance surface: every published record maps your
estate; external zone should reveal only what must be reachable.
17. Separate server sets (blast-radius isolation, simple mental model) vs
BIND views (one estate to run, single-box economy; risk: ACL mistakes leak).
18. Stub → internal resolver → (no internal match) → its recursion or
central forwarder tier → internet authoritative chain → cached back down.
19. In the parent TLD (.example) via the registrar — registrar-side NS/DS
control, a change-management domain of its own. 20. Clients using external
resolvers/DoH (block outbound 53/853/DoH IPs + NRPT/policy); internal zones
accidentally slaved/published on external servers (config review, separate
estates); also AXFR open to world (allow-transfer ACLs).

## TM 3.9 — Split-horizon with BIND views

**Explanation.** Views partition one server into virtual servers selected
per query by `match-clients` (source ACL) — **first matching view wins, in
config order**; a client matches exactly one view; each view has its own
zones (possibly different files for the same zone name) and its own cache
(when recursion is involved). Everything about split-horizon failure comes
from that selection step:
- ACL drift: new subnet/VPN pool/NAT range not added → those clients fall
  through to the external view → "internal users get public answers".
- Order mistakes: a broad `match-clients { any; }` view placed first
  swallows everyone.
- Transfers between views: secondaries must be matched into the *right*
  view (TSIG keys are the robust selector: `match-clients { key int-xfer; }`)
  or they slave the wrong version of the zone — the nastiest variant of
  drift.
**The marker-TXT trick** (production-grade): put `whichview TXT "internal"`
/ `"external"` in each version; one dig instantly reveals which view
answered any client. Cheap, priceless.

**Senior version.** "With views, every incident starts with: which view
answered this client, and which view SHOULD have? Marker record, source IP,
ACL order — in that sequence. Only then do I look at zone content."

**Mini lab:** LAB 8/8b. Assessment: dual-answer capture + cold-solved leak.

## TM 3.10 — EDNS deep dive

**Explanation.** OPT pseudo-record (ADDITIONAL section, not real data):
carries the requester's UDP payload size, extended RCODE bits, EDNS version,
the **DO** bit (send DNSSEC records), and options — the ones worth knowing:
**Cookies** (off-path spoofing defense), **Client-Subnet/ECS** (resolver
tells authority a client prefix for geo-answers — privacy trade, mostly
public-CDN territory), **TCP keepalive**, padding. Behavior rules: a
FORMERR/no-OPT reply to an EDNS query marks the server "EDNS-broken" (modern
resolvers no longer retry-without-EDNS post-Flag-Day — ancient middleboxes
that eat OPT now just fail). Size negotiation: the *smaller* of what client
advertises and server is willing to send governs; larger answers ⇒ TC=1.
Fragmentation reality: >MTU UDP answers fragment; fragments are dropped by
stateless filters and some paths silently ⇒ the timeout-only-for-big-answers
signature; 1232 sidesteps it by design.

**Quiz TM 3 Q21–25:**
21. Where does OPT live and why is it a "pseudo" record?
22. What three important things does OPT carry (any three)?
23. Server ignores/mangles EDNS. Modern resolver behavior?
24. Explain the exact mechanism turning a 1800-byte UDP answer into a timeout.
25. ECS: what it does and its privacy/ops trade-off.

**Key:** 21. ADDITIONAL section of each message; it's per-message signaling,
never stored in zones/caches as data. 22. UDP buffer size, DO bit, extended
RCODE/version, options (cookies/ECS/…). 23. Treated as broken — failure is
surfaced rather than silently downgrading (post-2019 behavior).
24. Answer > path MTU ⇒ IP fragments; a filter drops non-initial fragments
(no port info) ⇒ client gets nothing ⇒ retries ⇒ timeout; small answers via
same path fine. 25. Resolver forwards client subnet to authorities for
geo-targeted answers; trades client privacy + cache-fragmentation for CDN
accuracy — usually irrelevant/disabled inside enterprises.

## TM 3.11 — DoT and DoH, operationally

**Explanation.** Same DNS payload, new transports: **DoT** = DNS over TLS,
TCP 853, visible-as-a-protocol (blockable/inspectable as a port). **DoH** =
DNS inside HTTPS/443 to a resolver URL — indistinguishable from web traffic
without TLS inspection or endpoint control. What they protect: the
client↔resolver hop (privacy/integrity). What they do NOT provide: data
authenticity from the authority — that's DNSSEC; the two are orthogonal.
**Enterprise impact:** a client using an external DoH resolver bypasses your
split-horizon (internal names NXDOMAIN publicly or leak as queries!), your
RPZ, your logging, your NRPT assumptions. Controls: endpoint policy
(browsers/OS respect enterprise flags to disable DoH), block known DoH
provider endpoints, offer internal DoT/DoH so the privacy motive is served
in-perimeter, canary-domain conventions. The balanced recommendation you
should be able to defend: encrypt client↔resolver *inside* the enterprise
where feasible, keep resolution on enterprise resolvers by policy, and
treat rogue external DoH as the compliance problem it is.

**Mini lab:** Day 43 memo. Assessment: your both-sides memo.

## TM 3.12 — Windows deep quirks (client)

**Explanation — the four that generate tickets:**
1. **Negative caching on the client:** Windows caches NXDOMAIN briefly —
   "I created it, my machine still fails, my colleague's works" can be
   entirely client-side. `Clear-DnsClientCache` decides in 5 seconds.
2. **Suffix devolution & search lists:** short names expand along the list
   *in order*; the first suffix that yields ANY answer wins — a wildcard or
   stale record in an early suffix hijacks short names.
3. **Multi-NIC + VPN + NRPT:** resolver choice is per-interface with
   NRPT force-routing namespaces; "resolves wrong only on VPN" lives here.
   `Get-DnsClientNrptPolicy`, `Get-DnsClientServerAddress` are the X-rays.
4. **LLMNR/mDNS fallback:** single-label lookups may be answered by peers on
   the LAN when DNS says no — surprising, and a security issue (responder
   attacks); enterprises commonly disable LLMNR.

**Senior version.** "Windows client diagnosis = which exact FQDN was
queried, to which server, answered from which cache. `Resolve-DnsName -DnsOnly`
+ `Get-DnsClientCache` + interface/NRPT dump answers all three in a minute."

**Mini lab:** Day 44 experiments. Assessment: the experiment log.

## TM 3.13 — Linux deep quirks (client)

**Explanation.** systemd-resolved specifics beyond TM 1.7:
- **The 127.0.0.53 illusion:** resolv.conf points at the local stub; `dig`
  therefore shows resolved's cache/behavior, not your DHCP resolver's. To
  interrogate the real upstream: `dig @<real-resolver>` explicitly.
- **Per-link split DNS:** each interface can carry DNS servers + routing
  domains (`~corp.example` routes that suffix to that link's servers;
  `~.` claims default). Misordered claims after VPN connect = "internal
  works, internet broken" or vice versa. `resolvectl status` shows the whole
  routing table; `resolvectl query -4 name` shows which link answered.
- **Its own negative + positive cache:** `resolvectl statistics`,
  `resolvectl flush-caches` — a sixth cache people forget.
- **LLMNR/mDNS toggles** exist here too (resolved implements both).
- Classic gotcha: editing /etc/resolv.conf directly while it's a symlink
  into resolved → overwritten/ignored; per-distro management differs (netplan,
  NetworkManager) — change the manager, not the symlink.

**Mini lab:** Day 45 per-link routing exercise. Assessment: resolvectl trace.

---
**End of Part 2.** Part 3 (BIND operations deep dive) ships in Packet 4 with
the EfficientIP pack.
