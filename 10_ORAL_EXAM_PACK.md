# SECTION 12 — SENIOR DNS ORAL EXAM PACK (150 QUESTIONS)
### Packet 8 — Graded answer tiers, follow-ups, traps

**Protocol (Days 119–123):** answer ALOUD, recorded, closed-book. Grade
against tiers honestly: **E** = excellent (mechanism-level, precise terms,
would satisfy a hostile senior), **A** = acceptable (right idea, missing
mechanism/precision), **W** = weak (the answer that fails the interview —
recognize it to avoid it). **F** = the follow-up the examiner fires next.
**T** = the trap embedded in the question. Target: ≥120/150 at E tier.
Any non-E answer → written model answer in your own words next day.

---

## A. FUNDAMENTALS (Q1–10)

**Q1. What is DNS, in one minute, to a new network engineer?**
E: Distributed hierarchical database mapping names→data (not just IPs);
tree from root, authority split into zones via delegation; two planes:
authoritative servers publish, recursive resolvers find+cache; TTL-driven
eventual consistency. A: "Phonebook of the internet" + client/server/cache
sketch. W: "Turns names into IPs." F: Why "not just IPs"? (MX/TXT/SRV —
service metadata.) T: Skipping the two-plane split — the core mental model.

**Q2. Domain vs zone.**
E: Domain = subtree of the namespace; zone = administratively-served
portion bounded by delegation cuts; the unit of authority, transfer,
signing. A: Domain is the name space, zone is what a server hosts.
W: Uses them interchangeably. F: Can a.b.c.example live in the example
zone? (Yes — labels ≠ delegation.) T: Assuming every subdomain is a zone.

**Q3. Walk me through cold-cache resolution of www.corp.example.**
E: Stub→resolver (RD=1); resolver: hints→root→referral(+glue)→TLD→
referral→authoritative→AA answer; caches every RRset learned; answers
stub non-AA with draining TTL; stub caches. A: Root→TLD→auth chain
correct but no caching/flag detail. W: "The resolver asks the root for
the IP." F: What exactly does root return? (Referral: NS+glue, no
answer, no AA for the child.) T: Claiming clients query root.

**Q4. Iterative vs recursive query.**
E: Recursion = service ("complete this for me", RD); iteration = the
resolver's mechanism (follow referrals itself); stubs recurse, resolvers
iterate; a server may decline recursion (RA absent) yet still answer
authoritatively. A: Client-asks-fully vs step-by-step. W: "Recursive is
when it recurses through servers" (circular). F: Who sets RD, who RA?
T: Believing RD in a response means recursion happened — it's an echo.

**Q5. What lives in the DNS header, and which flags do you read first?**
E: ID, QR/AA/TC/RD/RA/AD/CD, rcode, four section counts; read rcode→AA→
counts→then sections; each flag's owner (querier vs responder).
A: Names most flags correctly. W: Only knows "there are flags."
F: NOERROR with zero answers — meaning? (NODATA/referral — read
AUTHORITY.) T: AD confused with "authoritative."

**Q6. UDP vs TCP 53 — when and why.**
E: UDP first; TCP on TC=1 (size), always for XFR, DoT by design;
EDNS raises UDP ceiling; >~1232 risks fragmentation (silent loss) hence
truncate-to-TCP posture; blocked TCP = intermittent size-dependent
failures. A: "Big answers and transfers use TCP." W: "TCP only for zone
transfers." F: Symptom signature of blocked TCP vs dropped fragments?
T: The "only for transfers" myth — say it and fail.

**Q7. What is EDNS(0) and why does 1232 matter?**
E: OPT pseudo-record: client-advertised UDP size, DO bit, options
(cookies); 1232 ≈ fits min-MTU paths unfragmented — converts silent
fragment loss into clean TC→TCP. A: "Extension allowing bigger UDP."
W: "A DNS version." F: Who advertises the size? (Client.) T: Thinking
the server decides the buffer.

**Q8. NXDOMAIN vs NODATA.**
E: NXDOMAIN: name doesn't exist (no types, and note empty non-terminals
DO exist → NODATA); NODATA: name exists, type doesn't (NOERROR/0
answers + SOA). Both negative-cached per SOA minimum. A: Correct
definitions, no ENT nuance. W: "Both mean not found." F: Query
b.corp.example where only a.b.corp.example exists? (NODATA — ENT.)
T: The empty non-terminal.

**Q9. SERVFAIL vs REFUSED vs timeout — first suspicion each.**
E: SERVFAIL: tried and failed — upstream/zone/DNSSEC (bisect per hop,
+cd early); REFUSED: policy at that responder — ACL/view/role (and
chains launder it to SERVFAIL downstream); timeout: transport — capture
at server. A: Correct mapping, no laundering point. W: Treats all three
as "DNS down." F: Client sees SERVFAIL; where might REFUSED hide?
(An upstream hop — read its logs.) T: Missing the laundering.

**Q10. What does "the DNS is eventually consistent" mean operationally?**
E: Every answer is a timestamped copy governed by TTL; changes converge
layer-by-layer within stated bounds (TTL, negative TTL, transfer
timers); the professional states the bound before the change and never
promises instant global visibility. A: "Caches take time to update."
W: "DNS is slow to propagate" (weather-talk). F: Compute the bound for
deleting a TTL-3600 record. T: "Propagation" as mystery instead of
arithmetic.

## B. RECURSION & RESOLVERS (Q11–19)

**Q11. What exactly does a resolver cache from one resolution?**
E: Multiple independent RRsets: answer, NS sets per zone cut, nameserver
addresses/glue, CNAME links, negatives with SOA timer — each own TTL;
plus server RTT/lameness metadata. A: "The answer and the path."
W: "The query result." F: Why is a sibling-name query fast? T: Thinking
cache stores whole responses.

**Q12. +trace vs querying your resolver — why can they differ?**
E: dig iterates itself from root — bypasses resolver entirely: misses
internal zones/views/forwarding/RPZ/cached state; it shows the public
tree from your network vantage. A: "Trace does its own recursion."
W: "Trace shows the true path your resolver takes." F: When is +trace
actively misleading in an enterprise? (Split-horizon names.) T: The
"true path" belief.

**Q13. forward only vs forward first.**
E: only: upstream is the sole path — dead upstream = SERVFAIL; first:
falls back to own iteration — which silently doesn't work without
hints/egress, so validate the fallback or it's theater. A: Correct
definitions. W: Guesses. F: How do you TEST the fallback? (Kill
upstream in lab, watch.) T: Untested forward-first fallback.

**Q14. Conditional forwarding vs stub vs static-stub vs delegation.**
E: Cond-fwd: send recursive question for zone X upstream; stub: learn
NS then iterate; static-stub: pin authoritative addresses (cleanest for
internal estates); delegation: in-band, needs parent control + shared
tree. Pick by: who owns parent, target recursion posture, split-horizon.
A: Knows fwd vs stub. W: "They're the same." F: Why is cond-fwd to a
recursion-off pure auth fragile? (Out-of-zone/child questions REFUSE.)
T: That fragility.

**Q15. Where can a stale answer physically live?**
E: App layer (pools/pinned/JVM), OS stub cache (Win/systemd-resolved),
site forwarder cache, each resolver node's cache, negative caches at
every one of those — enumerate, interrogate deepest-first, flush
bottom-up. A: Client+resolver. W: "The cache." F: Why flush resolver
before clients? (Else clients re-cache stale.) T: The forgotten
forwarder layer.

**Q16. Why is open recursion dangerous?**
E: Spoofable UDP + small-query/large-answer = reflection amplification
onto victims with your bandwidth/reputation; plus cache-poisoning/
tracking surface for strangers; hence recursion ACL-scoped and RRL on
authoritative edges. A: "DDoS amplification." W: "Hackers can use it."
F: What converts real clients to TCP while starving spoofers? (RRL
slip/TC.) T: Explaining amplification without spoofing.

**Q17. Two resolver nodes behind one VIP disagree. Broken?**
E: No — independent caches populated at different times; expected
during TTL windows post-change; per-node interrogation is mandatory;
monitoring should compare nodes on hot names. A: "Caches differ."
W: "LB is broken." F: User-visible symptom pattern? (~1/N failure
rate.) T: Diagnosing through the VIP.

**Q18. Windows client: three reasons a VPN user resolves internal names wrong.**
E: NRPT rule wrong/absent (silently overrides adapters), VPN adapter
DNS/suffix not applied or out-prioritized, stale client cache (positive
or negative) from pre-VPN — check Get-DnsClientNrptPolicy, adapter
config, Get-DnsClientCache. A: Two of three. W: "VPN DNS is flaky."
F: Which command reveals NRPT? T: Forgetting client-side negative cache.

**Q19. What is 127.0.0.53 and how does it fool people?**
E: systemd-resolved's stub: its own cache + per-link routing domains;
resolv.conf pointing there means dig reflects resolved's view, not the
corporate resolver; check resolvectl status/query, distinguish stub vs
static modes. A: "Local systemd DNS." W: "Localhost DNS, ignore it."
F: Command showing which uplink answered? (resolvectl query -v.)
T: Interrogating "the resolver" that is actually the local stub.

## C. AUTHORITATIVE (Q20–27)

**Q20. What does AA actually assert?**
E: The responder holds the zone containing the answer and served it
from zone data (not cache); combined with full/original TTL on repeat
queries it proves source truth; absence of RA is healthy on pure auths.
A: "It's the authoritative server." W: "The answer is correct." F: Can
an AA answer be wrong? (Yes — wrong zone DATA; AA proves source, not
truth.) T: AA = correct.

**Q21. Why run recursion-off on authoritative servers?**
E: Separate failure/attack domains: no open-resolver abuse, no cache to
poison on the public edge, ACL posture stays simple; mixing roles
couples cache incidents to authority. A: Security best practice.
W: "Performance." F: What rcode do out-of-zone queries get? (REFUSED.)
T: None — but vagueness fails it.

**Q22. A secondary answers with AA while its primary has been dead for
two days. Explain.**
E: Correct behavior: within EXPIRE, a secondary serves its last
transferred copy authoritatively — staleness isn't visible in flags;
expiry margin monitoring is the only early warning. A: "It serves until
expiry." W: "Bug." F: What happens at expire? (Zone → SERVFAIL.)
T: Expecting staleness to show in the protocol.

**Q23. Round-robin: what does the server actually do?**
E: Multiple records = one RRset; servers/resolvers rotate order; whole
RRset cached per TTL; balancing averages across clients/expiries — not
per request; deleting a "duplicate" member is capacity surgery.
A: "Rotates answers." W: "Load balancer in DNS." F: Balancing
granularity? T: The duplicate-member deletion.

**Q24. minimal-responses — what and why?**
E: Omit non-essential AUTHORITY/ADDITIONAL: smaller answers (less
amplification value, fewer fragmentation events), marginal privacy;
referrals/negatives keep required content. A: "Smaller responses."
W: Unknown. F: Which section must a negative answer still carry?
(SOA in AUTHORITY.) T: —

**Q25. What is a zone's serial protocol-wise?**
E: Version in RFC 1982 serial arithmetic — 32-bit circular "newer";
secondaries act only on increase; backwards serial = frozen replicas;
recovery: retransfer per node or +2^31 wrap trick. A: Version number,
must increment. W: "A date." F: Perform the wrap fix for
2026099999→2026070101. T: Not knowing recovery.

**Q26. Wildcards — the two behaviors people get wrong.**
E: (1) Synthesis only for NONEXISTENT names — any exact name (any type)
shadows the wildcard for ALL types at that name (TXT add kills A
synthesis); (2) closest-encloser scoping — doesn't cover the owner or
descend past existing names; plus the operational hazard: typos resolve.
A: Shadowing known. W: "Matches everything under it." F: Query A at a
name that exists as TXT only under a wildcard? (NODATA.) T: The TXT
shadowing.

**Q27. CAA in one breath.**
E: Which CAs may issue certs for the domain; consulted by CAs at
issuance, walking up labels to the nearest CAA; absent CAA = any CA;
operationally a cert-issuance gate living in DNS. A: CA allow-list.
W: Unknown. F: Cert renewal fails, "DNS problem" per vendor — first
record you check? T: —

## D. CACHING & TTL (Q28–44)

**Q28. Who sets TTL, who decrements, what does a draining TTL prove?**
E: Zone owner sets; every cache decrements per second; draining across
repeated queries to the SAME node proves cache provenance; auth returns
full TTL every time — the cheapest provenance test in DNS. A: Correct
minus per-node nuance. W: "TTL is how long DNS takes." F: Same query,
TTL went UP — explain. (Different node/instance, or refreshed after
expiry.) T: The TTL-went-up case.

**Q29. Negative caching end-to-end.**
E: NXDOMAIN/NODATA cached per min(SOA MINIMUM, SOA TTL), SOA attached
as timer; creates create-after-query latency; the fix is sequencing
(create before pollers) or targeted flush; record TTL is irrelevant to
it. A: "NXDOMAIN gets cached via SOA." W: "Missing records aren't
cached." F: Which field do you tune and to what, for change-heavy
zones? T: Tuning record TTL for a negative problem.

**Q30. "I changed the record an hour ago and some users still get the
old IP." Give the complete professional response.**
E: State TTL bound from pre-change TTL; prove: auth=new+AA, resolver=
old+draining, client caches; offer targeted flush on owned resolvers;
convergence clock time; systemic: ramp-down next time. A: TTL
explanation + flush. W: "Clear your cache." F: And if AUTH still shows
old? (Different incident: deploy/serial — the ladder.) T: Skipping the
auth check before blaming caches.

**Q31. rndc flush vs flushname vs flushtree — blast radius.**
E: flush: entire cache — cold-start latency + upstream storm; flushname:
one name's RRsets; flushtree: name + descendants (zone-level fixes);
choose the scalpel; on farms, per node. A: Knows the three. W: Only
flush. F: When is flushtree the right tool? (Post zone-side fix/
migration.) T: Full flush as default.

**Q32. Why can a resolver hold a FRESH answer but STALE NS data (or
vice versa), and what does it cause?**
E: Independent RRsets, independent TTLs — answer may outlive the NS set
or vice versa; during NS migrations, some names re-resolve via new
servers while cached answers persist → mixed-era behavior per name.
A: Independent TTLs. W: "Cache corruption." F: Which TTL governs
WHERE the resolver goes next? (NS/glue.) T: Treating cache as one blob.

**Q33. TTL 0 — meaning and consequence.**
E: Do-not-cache: every lookup rides to authority; resolver load
multiplies; you inherit authority availability per query; latency
spikes on path hiccups; negotiate sane TTL or (policy permitting)
min-cache override with eyes open. A: "No caching, more load."
W: "Fastest updates, good." F: Tradeoff of resolver min-TTL override?
(Violates published intent — document it.) T: Calling TTL 0 best
practice for agility.

**Q34. Design a TTL policy for an enterprise. Defend it.**
E: Tiered: infra/stable 3600+, app/service 300–900, pre-change ramp-down
choreography, SOA MINIMUM ~300–900 in change-heavy zones; rationale:
agility vs resilience vs load; explicit exception process. A: Reasonable
numbers, thin rationale. W: "Low everywhere so changes are fast."
F: What breaks with global TTL 60? (Load, fragility, every blip
user-visible.) T: The global-low answer.

**Q35. Ramp-down math: TTL 3600 record, change needed Monday 09:00
with ≤5 min convergence. Schedule it.**
E: Lower to 300 (or 60) no later than Sunday 08:00-ish (≥1×3600 +
margin before window — strictly, by Mon 08:00 minus margin; earlier is
kinder); change 09:00; converged 09:05; soak; restore. Emphasize: the
lowering itself takes old-TTL to be universally held. A: Correct
concept, sloppy arithmetic. W: Lower it Monday 08:55. F: Deletion
variant — what extra clock? (Negative TTL.) T: Lowering too late.

**Q36. Prove an answer came from cache vs authority — two independent
methods each.**
E: Cache: no AA + draining TTL across repeats to same node; +norecurse
still answers; dumpdb shows entry. Authority: AA + full TTL every
time; server present in NS set (or known hidden primary); zone file/
platform object concurs. A: Flags+TTL only. W: "nslookup says
non-authoritative." F: Limits of +norecurse against a farm? (Per-node
caches.) T: —

**Q37. The five-layer cache map from memory.**
E: App (pools/JVM/pinned) → OS stub (Win DNS Client/systemd-resolved)
→ site forwarder → resolver node(s) → [negative caches at each]; zone
data beneath is source, not cache; one flush verb per layer named.
A: Three layers. W: "Client and server cache." F: Flush order and why?
T: Forwarder omission.

**Q38. Windows negative caching — why does it extend outages?**
E: DNS Client caches NXDOMAIN; after server-side fix, affected clients
keep failing until their negative expires or Clear-DnsClientCache;
visible in displaydns as "Name does not exist." A: Knows it exists.
W: Unaware. F: How do you see it? T: Fix verified at resolver, user
still broken → this.

**Q39. What is cache poisoning and what defends against it today?**
E: Forged responses raced into a resolver's cache; defenses: random ID
+ random source port (post-Kaminsky), bailiwick rules on acceptance,
cookies, and cryptographically: DNSSEC validation; triage checklist
distinguishes poisoning from legit variance (CDN/geo) and staleness.
A: Spoofed answers + randomization. W: "Hacking the cache." F: What
made Kaminsky's attack potent? (Forcing many queries for random
subdomains — many race chances + in-bailiwick NS injection.)
T: Crying poisoning at CDN variance (T35).

**Q40. A TTL is counting down — the app team says that proves DNS is
broken. Respond.**
E: It proves only that the answer is cached and when it was learned;
correctness is judged against authority; the countdown is the
provenance breadcrumb pointing WHERE to verify next. A: "It's just
cache." W: Agreement. F: TTL 212 seen, zone default 300 — what
timestamp do you extract? T: —

**Q41. Where does a FORWARDER's cache bite, concretely?**
E: Central resolvers fixed+flushed, site users still stale → the site
forwarder holds its own copy (positive or negative); it needs its own
flush; monitoring/consistency probes must include forwarder tier.
A: "Forwarders cache too." W: Blank. F: Which teams typically forget
this layer? T: —

**Q42. How long is an NXDOMAIN remembered, exactly?**
E: min(SOA MINIMUM, SOA record TTL) from the moment that resolver
cached it — per resolver node, plus possibly again at client/forwarder
layers; RFC 2308. A: SOA minimum. W: Record TTL. F: Why the min()
with SOA's own TTL? T: The min().

**Q43. Aggressive NSEC caching (RFC 8020/8198) — one sentence.**
E: Validating resolvers may use signed NSEC/NSEC3 ranges to synthesize
negatives for names within a proven-empty span without asking again —
signed zones can suppress query floods for junk names. A: "DNSSEC lets
resolvers infer nonexistence." W: Unknown (acceptable to say so
plainly — better than inventing). F: Prerequisite? (Validated
NSEC/NSEC3, i.e., signed zone + validating resolver.) T: Inventing.

**Q44. After rollback of a bad change, users who saw the broken state
stay broken. Why?**
E: The broken interval populated caches — including NEGATIVES if the
name vanished; rollback re-raises convergence with the broken TTLs;
targeted flushes + honesty about the second tail. A: "Caches kept the
bad data." W: "Rollback failed." F: Which cache class is nastiest
here? (Negative.) T: Declaring rollback complete at auth-level only.

## E. RECORDS & ZONES (Q45–62)

**Q45. SOA fields, each in one sentence, with the operational sting.**
E: MNAME primary; RNAME contact; SERIAL replication trigger (arithmetic!);
REFRESH poll cadence; RETRY after failed poll; EXPIRE the DR deadline
(secondaries SERVFAIL after); MINIMUM negative-cache TTL — three of
these run incidents (serial, expire, minimum). A: All named, stings
missing. W: Reads them as trivia. F: Which field schedules a Monday
outage from a Friday failure? T: MINIMUM as "default TTL" (historic
meaning — wrong since RFC 2308).

**Q46. Why must CNAME stand alone, and what's the DNSSEC exception?**
E: CNAME redirects the NODE for all types — coexisting data would be
unreachable/ambiguous; RRSIG/NSEC may coexist (they describe the node
itself); apex therefore can't be CNAME (SOA/NS live there).
A: Rule known, exception missing. W: "You just can't." F: Vendor
demands apex CNAME — options? (A/ALIAS-flattening, www move, SVCB/HTTPS.)
T: Exception.

**Q47. MX rules that bite.**
E: Lowest preference first; target must be a hostname with A/AAAA —
never CNAME, never an IP literal; domain needs no A for mail; SPF/DMARC
coexist as TXT at apex/_dmarc. A: Preference + no-CNAME. W: "MX points
to mail server IP." F: Two equal preferences — behavior? (Load-share/
either.) T: IP literal in MX.

**Q48. Giant TXT records (DKIM) — the protocol detail and the incident
it causes.**
E: Character-strings cap at 255 bytes → long values split into multiple
quoted strings, concatenated by consumers; copy-paste that drops a
segment breaks DKIM invisibly; also size→EDNS/TCP interactions.
A: Splitting known. W: Unaware. F: The other classic: how many SPF
strings may a name have? (One v=spf1 — two = permerror.) T: —

**Q49. Decode an SRV record and its two rules.**
E: _service._proto.name → priority weight port target; lowest priority
first, weight shares within priority; target = hostname with address
records (no CNAME); AD's entire service discovery rides on these.
A: Fields decoded. W: Confuses priority/weight. F: When is weight
consulted at all? (Among same-priority targets.) T: —

**Q50. The trailing-dot bug — mechanism and symptom.**
E: Relative names get $ORIGIN appended; a dot-less FQDN in a target
becomes name.zone.zone → NXDOMAIN in a weird namespace; checkzone/
review catches; symptom: alias/MX "randomly" dead pointing at
double-suffixed name. A: Knows the doubling. W: "Syntax error."
F: Which record types hide it best? (CNAME/MX/SRV targets.) T: —

**Q51. What breaks when a zone's NS RRset at the child disagrees with
the parent's delegation?**
E: Resolvers learn parent's set first, may switch to child's
(child-centric behavior varies); mismatch → some resolvers use servers
the other side doesn't intend: intermittent lameness, DNSSEC/consistency
warnings; keep identical, audit both. A: "They should match."
W: Unaware two copies exist. F: Which copy is authoritative? (Child's.)
T: —

**Q52. Empty non-terminals — why do they exist and what do they answer?**
E: A name "exists" if anything exists BELOW it (a.b.x makes b.x exist
with no records) → queries at ENT get NODATA, not NXDOMAIN — matters
for negative caching class and monitoring logic. A: Definition ok.
W: NXDOMAIN claim. F: Effect with wildcards? (ENT existence blocks
wildcard at that name.) T: The whole question is the trap.

**Q53. $TTL vs SOA MINIMUM.**
E: $TTL = default TTL for records lacking one (positive data); SOA
MINIMUM = negative-cache TTL (RFC 2308) — unrelated jobs people
conflate. A: Correct split. W: "Both defaults." F: Historic meaning
of MINIMUM? (Old default-TTL role, superseded.) T: The conflation.

**Q54. You must serve corp.example at apex over HTTP — enumerate lawful
designs.**
E: A/AAAA at apex (static or provider-flattened ALIAS/ANAME —
server-side lookup published as A); redirect at the web layer to www;
HTTPS/SVCB records where client ecosystem allows; never apex CNAME —
explain to the vendor with the SOA/NS coexistence argument. A: Two of
three. W: "Just add the CNAME, it works on X provider" (that IS
flattening). T: Not recognizing ALIAS = flattening, not CNAME.

**Q55. Reverse zone naming: 10.10.20.0/24 and the /16 — construct both.**
E: 20.10.10.in-addr.arpa (per-/24) and 10.10.in-addr.arpa (per-/16);
PTR owner = reversed full address under the zone; IPv6 → ip6.arpa
nibbles. A: /24 correct. W: Octet order wrong. F: PTR owner for
10.10.20.15 inside the /16 zone? (15.20 relative → 15.20.10.10.…)
T: Octet order.

**Q56. RFC 2317 in one minute.**
E: Classless reverse for sub-/24 allocations: parent /24 zone CNAMEs
each address into a customer-named child zone the customer serves —
delegation via alias since you can't cut a /24 zone at /28 boundaries
naturally. A: "CNAME trick for small reverse blocks." W: Unknown.
F: Where do you meet it? (ISP handoffs.) T: —

**Q57. Why do orphan PTRs happen even under IPAM, and who do they hurt?**
E: DNS-side-only edits, deletes touching one side, unmanaged reverse
zones, imports without backfill — process gaps around the tool; victims:
mail scoring, SIEM attribution (T07), log/traceroute readers, some auth
flows. A: "Forward changed, reverse forgot." W: "Reverse DNS is
unreliable." F: The control that closes it? (Address-object-driven
changes + reverse-zone coverage audit.) T: Calling it infrastructure
failure.

**Q58. One IP, multiple PTRs — legal? wise?**
E: Legal; breaks naive single-answer consumers and muddies attribution;
policy: one PTR matching forward; exceptions documented. A: Legal-but-
avoid. W: "Illegal." F: What does mail reverse-checking do with three
PTRs? (Implementation-dependent — that's the problem.) T: —

**Q59. A "cleanup" ticket lists 40 TXT records as deletable junk. Your
gate?**
E: TXT is load-bearing: SPF/DKIM/DMARC/domain-verification tokens;
per-record owner identification, query-log liveness, external-dependency
check (verifications don't show in YOUR logs!), staged deletes;
verification tokens often must persist. A: SPF/DKIM caution. W: Deletes
them. F: Which TXT class never shows liveness in query logs?
(Third-party verification tokens — checked from outside rarely/never
via your resolvers.) T: That class.

**Q60. named-checkzone passes — list three wrongs it cannot catch.**
E: Semantically wrong data (right syntax, wrong IP), stale-but-valid
records, delegation truth (whether listed NS actually serve), forgotten
serial ++ relative to secondaries (it checks the file, not the estate),
policy violations (round-robin member removal). Any three. A: "Syntax
only." W: Treats it as full validation. F: What tool/step covers the
estate-level part? (Post-checks at every auth + serial spread.)
T: —

**Q61. Zone file vs zone: when is the file NOT the truth?**
E: Dynamic/inline-signed zones: truth = journal+memory, file lags;
managed estates: truth intent = platform objects (L1) and file is a
deploy artifact; secondaries: file is a transfer snapshot. Editing the
wrong representation causes T21/T47. A: Dynamic-zone case. W: "File is
always truth." F: The sync protocol for hand edits? (freeze/thaw.)
T: —

**Q62. What's in a referral response, exactly?**
E: ANSWER empty; AUTHORITY: child NS set; ADDITIONAL: glue (+OPT);
no AA for the child's names; it's the parent saying "not mine — ask
them." A: NS+glue. W: "The answer with a flag." F: Is glue served
authoritatively? (No — hint data below the cut.) T: —

## F. DELEGATION & REVERSE OPERATIONS (Q63–69)

**Q63. Glue: when mandatory, and the audit for it.**
E: In-bailiwick NS names — else circular dependency; audit: parent
referral's ADDITIONAL contains addresses for every in-bailiwick NS;
missing glue = SERVFAIL-after-flush pattern; out-of-bailiwick NS
removes the need (and the risk). A: In-bailiwick rule. W: "Always
needed." F: Design choice that eliminates glue management for external
delegations? (Out-of-bailiwick NS names — T27's fix.) T: —

**Q64. Lame delegation: definition, symptoms, three-command audit.**
E: Parent-listed NS not answering authoritatively (down/REFUSED/
non-AA); symptoms: intermittent slowness→SERVFAIL scaling with lame
fraction; audit: parent NS via +norecurse → each listed server SOA
+norecurse expecting AA → compare child apex NS. A: Definition +
symptoms. W: "Delegation is broken." F: Why intermittent, not total?
(Resolver NS rotation + lameness tracking.) T: —

**Q65. Decommissioning a delegated child zone — the step teams skip
and its symptom.**
E: Removing zone data but leaving parent NS → resolvers chase refusing
servers → slow SERVFAILs instead of crisp cacheable NXDOMAIN (T42);
correct end-state: delegation removed at parent (optionally deprecation
window with empty zone). A: "Remove the delegation too." W: Deletes
zone only. F: Why is NXDOMAIN the kinder failure? (Fast + negative-
cacheable.) T: —

**Q66. Prove a delegation is healthy from an OUTSIDER's vantage.**
E: From the external universe: parent referral (NS+glue present) →
each listed NS answers child SOA with AA → child NS matches → resolver-
level resolution succeeds; split-horizon means repeating per universe
(T27). A: The chain, one universe. W: "dig works." F: Which universe
masks missing external glue? (Internal.) T: —

**Q67. Reverse DNS "broken" tickets: your first three questions.**
E: Broken (zone/service down) or stale (data)? — dig -x + zone SOA
health; who consumed it and observed what (mail? SIEM?); when did the
forward side last change for that IP (drift correlation) — 90% land on
stale data. A: Stale-vs-broken split. W: Restarts reverse "service."
F: The IPAM control preventing recurrence? T: —

**Q68. Delegating reverse for 10.0.0.0/8 space internally — design
choices.**
E: Serve 10.in-addr.arpa centrally vs per-/16//24 child zones delegated
to regional estates; resolvers need static-stub/forward routing to
internal reverse authorities (never the public tree); consistency
tooling per zone granularity. A: Zone-per-/24 + routing. W: Expects
public resolution of RFC1918 reverse. F: Why can't +trace ever verify
this? T: —

**Q69. Parent shows your delegation, child servers answer, but one
resolver still SERVFAILs the child — three cache-era causes.**
E: Cached lame-server state (negative server metadata) from the broken
period; stale NS/glue RRsets pointing at old servers until their TTL;
cached negatives (SERVFAIL isn't cached long, but NXDOMAIN from a
broken interval is); flushtree + time bounds. A: Stale NS. W: "Resolver
bug." F: Which flush verb targets a whole child zone? T: —

## G. BIND OPERATIONS (Q70–82)

**Q70. Read an unfamiliar named.conf: your order and why.**
E: options ACL posture → views count/order → zone inventory per view →
keys → logging destinations — yields security model + blast radius in
minutes; then rndc/controls. A: options→zones. W: Scrolls randomly.
F: What single option most changes the server's role? (recursion +
allow-recursion.) T: —

**Q71. The life of a zone change, edit to user-visible.**
E: edit → checkzone → serial++ → reload → primary serves → NOTIFY →
secondaries SOA-check → IXFR/AXFR → all auths converged → resolver
caches drain per TTL → clients; name the failure point at each arrow.
A: Chain minus failure points. W: "Reload and it works." F: NOTIFY
lost — what still saves you and when? (REFRESH timer.) T: —

**Q72. IXFR prerequisites and fallback.**
E: Primary needs delta history: journal (dynamic/inline-signed
automatic; static needs ixfr-from-differences); secondary presents
serial; missing history/first transfer/unsupported → full AXFR is the
correct, automatic fallback. A: Journal requirement. W: "IXFR always
works after first AXFR." F: What trims journals? (Size limits,
rebuilds, deletion — T44 corruption territory.) T: —

**Q73. TSIG failure log triage: BADSIG vs BADTIME vs BADKEY vs plain
REFUSED.**
E: BADSIG secret mismatch; BADTIME clock skew beyond fudge (check NTP);
BADKEY unknown key name; unsigned-request-against-key-ACL logs plain
REFUSED — each names a different fix. A: BADSIG/BADTIME. W: "TSIG
error." F: Post-VM-snapshot-restore transfers die — which one?
(BADTIME.) T: The REFUSED-because-unsigned case.

**Q74. rndc freeze/thaw — the contract.**
E: freeze: flush journal to file + suspend dynamic updates (file becomes
momentarily truthful and editable); edit + serial++; thaw: resume,
re-sync; skipping it = journal/file desync (T21). A: "Pause updates to
edit." W: Unaware. F: Zone types where this is mandatory? (Dynamic +
inline-signed.) T: —

**Q75. Secondary shows old serial; NOTIFYs are arriving per logs. Next
three checks.**
E: Secondary's refresh attempt outcome (logs: REFUSED/BADSIG/timeout on
the SOA/XFR step); allow-transfer/TSIG on primary vs secondary's actual
source IP (T13 NAT); zonestatus timers (is it even trying / expiry
countdown); then rndc refresh to force a witnessed attempt. A: Transfer
ACL + logs. W: retransfer blindly. F: Why can NOTIFY arrive but
transfer fail? (Different auth step — NOTIFY is unauthenticated hint;
XFR hits ACL/TSIG.) T: Surgery before evidence.

**Q76. Zone expired on a secondary — what do queries get and what does
zonestatus show?**
E: SERVFAIL for the zone (server otherwise healthy); zonestatus: expired
state, last-refresh ancient; recovery: fix transfer path, retransfer;
prevention: refresh-failure-age alarms at a fraction of EXPIRE.
A: SERVFAIL + retransfer. W: "Zone disappears." F: Do other zones on
the box suffer? (No — per-zone state.) T: —

**Q77. Dynamic updates: allow-update vs update-policy, and the AD
analogue.**
E: allow-update: whole-zone grant per key/ACL; update-policy: per-key
name/type grants (self-updates pattern); AD: GSS-TSIG (Kerberos-
negotiated) "secure dynamic updates" + aging/scavenging lifecycle.
A: The two BIND options. W: "Clients just update." F: Scavenging's
famous failure (T40)? T: —

**Q78. nsupdate prerequisites — why do seniors love them?**
E: Atomic condition+change in one transaction: "add A only if
nxdomain / only if no CNAME" — race-free pre-checks, the protocol-level
ancestor of the EIP collision gate. A: Conditional updates.
W: Unknown. F: Compose: delete app9 A 10.10.20.90 only if it exists
with exactly that value. (prereq yxrrset app9… A 10.10.20.90 …
update delete …) T: —

**Q79. Query logging: cost, control, and the pre-deletion technique.**
E: IO-heavy at scale — toggle live (rndc querylog), rotate via channel
versions/size; blast-radius grep before deletions: N-day window, hits →
name is alive → find sources; plus top-NXDOMAIN mining after changes.
A: Toggle + grep idea. W: Always-on unbounded file. F: Which TXT class
evades this liveness test? (External verification tokens — Q59.)
T: —

**Q80. RPZ: triggers, actions, and its two honest limits.**
E: Triggers QNAME/IP/NSDNAME/NSIP/CLIENT-IP; actions NXDOMAIN(CNAME .),
NODATA(CNAME *.), sinkhole(A x), passthru; distributed as ordinary zone
transfers; limits: only clients using your resolvers (DoH bypass —
T37), and no visibility of direct-to-IP traffic. A: Block/sinkhole +
resolver scope. W: "DNS firewall blocks malware." F: Local override
ordering for FP handling (T22)? (Own passthru zone evaluated first.)
T: Overselling it to security.

**Q81. RRL in two sentences and the slip trick.**
E: Rate-limits identical responses per client prefix to kill
reflection value; slip returns truncated (TC) replies at intervals so
REAL clients retry over TCP and survive while spoofed victims get
nothing usable. A: Rate limit for amplification. W: "QPS limiter."
F: Why does slip not break legitimate users? T: —

**Q82. Your BIND triage order, recited.**
E: rndc status → named-checkconf -z → rndc zonestatus → logs by
category → dig localhost (right view!) → dig remote → only then
surgery; rationale: state before symptoms, evidence before change.
A: Most steps, order fuzzy. W: dig-and-flush. F: Why is checkconf -z
special? (Estate-wide zone load audit in one command.) T: Surgery
first.

## H. EFFICIENTIP / DDI (Q83–93)

**Q83. The three layers of truth and one-line divergence causes.**
E: L1 objects (intent) / L2 deployed zone data / L3 caches; L1≠L2:
failed push, staged change, hand-edit divergence; L2≠L3: TTL physics;
report every finding with its layer. A: Layers named. W: "GUI vs
reality." F: The T47 emergency-edit story in one sentence.
T: Blaming caches for L1/L2 gaps.

**Q84. "Record already exists" — the four realities and gates.**
E: Exact duplicate (close as satisfied), same-name-different-value
(owner intent: round-robin vs stale), type conflict (CNAME rule —
design decision), automation/auto-PTR collision (fix lifecycle first);
each with dig proof before action. A: Three of four. W: One generic
answer. F: Which one is a capacity hazard? (#2 → T06.) T: —

**Q85. IPAM-driven DNS: what it guarantees and what it can't.**
E: Address-object operations fan out A+PTR atomically, lifecycle ties
records to allocations; can't save you from DNS-side-only edits,
unmanaged reverse zones, imports without backfill, or humans bypassing
it — hence drift audits. A: Auto A+PTR. W: "IPAM keeps DNS perfect."
F: The silent auto-PTR failure? (Reverse zone not under management.)
T: —

**Q86. Smart architecture in one minute, to a BIND person.**
E: A template that materializes one logical zone as wired
primary/secondaries (roles, NOTIFY, transfers, TSIG) across member
servers — you edit intent once, platform maintains the replication
graph; underneath it's the BIND estate you already know. A: Multi-
server abstraction. W: "EIP cluster magic." F: What still diagnoses a
transfer failure under it? (Chapter 4 skills — it's BIND physics.)
T: —

**Q87. Bulk import: the four platform facts you verify BEFORE 400 rows.**
E: Column-mapping preview, on-error semantics (abort vs skip),
dry-run/preview existence, export format that round-trips as rollback;
plus your batching doctrine regardless. A: On-error + rollback.
W: "Test with one row" only. F: T32 in one sentence as the cautionary
tale. T: —

**Q88. Why apply via the platform even when SSH is faster?**
E: L1 must stay the source of intent — direct edits diverge and get
overwritten by the next deploy (T47); platform path preserves audit,
rights, linkage; break-glass exists but ends in mandatory
reconciliation. A: "Platform overwrites." W: "Policy says so."
F: Design a break-glass that doesn't cause the second outage.
T: —

**Q89. The ten pre-approval checks — recite eight.**
E: Ticket match; ownership; deployed-reality pre-check; collision
taxonomy; reverse impact; dependency sweep (CNAME/MX/SRV/NS + liveness
for deletes); TTL implications; rollback artifact; post-check plan;
comms w/ negative-TTL honesty. A: Six. W: "Check it exists." F: Which
check most often blocks bad changes, and defend. T: —

**Q90. GUI shows new value since 11:00, dig at auth shows old with aa.
Sixty-second diagnosis.**
E: L1/L2 divergence — deployment class: check platform sync/push status
for that server (failed push, unreachable agent, staged change); serial
unchanged corroborates; caches irrelevant until L2 converges (T20).
A: Push failed. W: "TTL." F: And if push status shows success? (Wrong
server/view queried, or divergence via hand-edit — compare serials
across members.) T: The TTL reflex.

**Q91. EIP vs Infoblox vs BIND — the transfer-of-skills answer.**
E: Same physics (zones/serials/TTL/transfers/three layers); platforms
differ in nouns (smart architecture≈Grid, class params≈extensible
attrs), guardrails, audit location; both wrap BIND-family engines; on
arrival you verify [V]-class specifics instead of assuming. A: "Similar
DDI products." W: Vendor slogans. F: One concept with NO BIND
equivalent? (Object rights/approval workflow.) T: —

**Q92. What questions do you ask before APPROVING someone else's DNS
change?**
E: Intent in plain language + who consumes the name; evidence of
pre-checks against deployed reality; collision/dependency findings;
convergence bound + window fit; rollback artifact attached; post-check
commands with expected outputs; comms plan — approve the EVIDENCE, not
the intention. A: Half of those. W: "Looks fine." F: The one attachment
whose absence auto-blocks? (Pre-change export/rollback artifact.)
T: —

**Q93. Auto-PTR collided with an existing PTR during an IPAM assign —
unpack it.**
E: Reverse zone already holds a PTR for that IP (previous tenant not
cleaned / manual entry): lifecycle fix first — reclaim/clean the
address object and stale PTR, then assign; forcing a second PTR creates
the Q58 mess. A: Stale PTR cleanup. W: Force it. F: The drift class
number from the catalogue? (§3 #3/#4 family.) T: —

## I. DNSSEC (Q94–104)

**Q94. Explain the chain of trust to a security engineer in 90 seconds.**
E: Anchor→root DNSKEY; each parent publishes DS = digest of child KSK;
child DNSKEY signs zone RRsets (RRSIGs); validator walks anchor→DS→
DNSKEY→RRSIG; outcome secure/insecure(provably unsigned)/bogus(SERVFAIL).
A: Keys sign records, parent links child. W: "DNS with certificates."
F: Where's the single record you don't control? (DS at parent.)
T: Cert-PKI analogies taken literally (no CAs here).

**Q95. Secure vs insecure vs bogus — and why the middle one exists.**
E: Insecure = parent SIGNS the absence of DS (NSEC proof) → child
legitimately unsigned → resolve without AD; prevents downgrade attacks
being indistinguishable from unsigned zones; bogus = should-validate-
but-fails → SERVFAIL. A: Definitions. W: Unsigned=broken. F: What
attack does authenticated-absence-of-DS defeat? (Stripping DNSSEC to
force insecure.) T: —

**Q96. KSK vs ZSK: why two, what each signs.**
E: KSK (SEP, 257) signs only DNSKEY RRset and is what DS digests —
stable, parent-linked; ZSK (256) signs zone data — rolls freely without
parent; split isolates the parent-coordination burden. A: Roles known.
W: "Big key and small key." F: Single-key (CSK) setups — legitimate?
(Yes — modern policies sometimes; the split is convention, not law.)
T: —

**Q97. Your resolver SERVFAILs one external domain; 8.8.8.8 works.
Script the proof, fast.**
E: +cd on your resolver (answers → validation class) → delv verdict →
dig DS @parent vs DNSKEY @child, RRSIG timestamps → if chain broken for
everyone, 8.8.8.8 "working" means checking again (it validates too —
did it really answer without cd?) → attribute: domain vs your
anchor/clock/forwarder-stripping path. A: cd+delv. W: Flush and hope.
F: What if it fails ONLY on your resolver with cd too? (Not DNSSEC —
reachability/forwarder.) T: Trusting the 8.8.8.8 anecdote without
re-testing.

**Q98. RRSIG timestamps: read them and name the two operational alarms.**
E: Inception/expiration are absolute validity walls; alarms: minimum
remaining validity across the zone (re-signing liveness — T31) and
signer/validator clock sanity; expired sigs = bogus = SERVFAIL on
validators only. A: Expiry alarm. W: Ignores timestamps. F: Zone
"unchanged for weeks" then dies Saturday 03:00 — story? T: —

**Q99. Choreograph a KSK rollover.**
E: Publish new KSK (DNSKEY signed by both) → wait DNSKEY TTL → submit
new DS to parent → wait parent DS TTL + publication lag → remove old
DS → wait → retire old KSK; invariant: every cached DS/DNSKEY combo
validates at all times; CDS/CDNSKEY where parent supports. A: Steps
minus waits. W: Swap keys same day. F: T30's failure in one line.
T: The waits ARE the rollover.

**Q100. NSEC vs NSEC3, and opt-out.**
E: NSEC: sorted next-name links — provable denial but walkable
enumeration; NSEC3: hashed names resist casual walking (not
cryptographically private); opt-out: skip covering unsigned
delegations in huge TLD-ish zones — smaller, weaker proofs.
A: Hashing difference. W: Unknown. F: Why are signed NXDOMAINs big?
T: Claiming NSEC3 gives privacy.

**Q101. Negative trust anchor — when, and the guardrails.**
E: Per-domain validation bypass for a business-critical domain broken
by ITS OWN DNSSEC error; guardrails: documented, approved,
time-boxed with removal date, vendor contacted — a scalpel with a
timer, never default posture. A: Emergency bypass. W: "Disable
validation." F: Why not disable validation globally instead?
T: The global-disable reflex.

**Q102. What operationally CHANGES the day you sign a zone?**
E: Bigger answers (EDNS/TCP posture matters), serial churn from
re-signing, a liveness requirement (signing must keep running),
parent-DS coupling on every KSK event, monitoring additions (RRSIG
margin, DS consistency), and migrations become key-aware. A: Bigger
answers + keys. W: "It's more secure." F: The migration trap for
signed zones? (DS pointing at keys the new estate lacks — go
deliberate insecure-then-secure or move keys.) T: —

**Q103. Middlebox strips the OPT record — DNSSEC consequence and proof.**
E: DO bit lost → validators can't obtain RRSIGs → validation failures/
SERVFAIL beyond that path; prove with side-by-side +qr captures
inside/outside the box (T48). A: EDNS stripped breaks big/DNSSEC.
W: "Firewall blocks DNSSEC port" (no such port). F: The other casualty
of stripping? (512-byte clamp → chronic truncation.) T: The
"DNSSEC port" howler.

**Q104. Does DNSSEC encrypt anything? Follow the implications.**
E: No — authenticity/integrity only; privacy is DoT/DoH's job;
consequence: signed zones remain fully readable (hence NSEC walking
concerns) and DNSSEC+encrypted transport are complementary, not
alternatives. A: "No, it signs." W: "Yes." F: Which problem does each
solve for a bank? T: —

## J. ENTERPRISE TROUBLESHOOTING (Q105–115)

**Q105. The interrogation ladder, from memory, with what each rung
excludes.**
E: Exact question on the wire (suffixes) → client cache → each resolver
node → each authoritative → parent delegation → transport matrix →
DNSSEC (+cd/delv); each rung either owns the fault or exonerates a
layer with evidence. A: Most rungs. W: "Check DNS then network."
F: Where do containers insert a rung-zero? (Embedded resolver — T39.)
T: —

**Q106. Intermittent failures: your four fingerprints.**
E: ~1/N rate → one bad node/instance behind VIP/anycast; fixed +N-second
latency → a corpse in a list (forwarder/NS timeout); size-dependent →
transport/EDNS/TCP; time-of-day/flap-correlated → health-check or load
inputs (GSLB). A: Two fingerprints. W: "Intermittent = network."
F: Which fingerprint was T15? T: —

**Q107. Prove "DNS is fine" so an app team accepts it.**
E: Reproduce THEIR path (getent/Resolve-DnsName on their host), show
correct answers at client-path/resolver/auth with flags+TTL, then NAME
the actual fault (hosts line, pinned IP, pool) — exoneration lands only
with the culprit attached; timestamped artifacts in the ticket. A:
Layered digs. W: "Works for me." F: Why getent over dig for the
app's-eye view? T: —

**Q108. tcpdump at the server shows the query arriving and a correct
response leaving; client never sees it. Continue.**
E: Return-path problem: asymmetric routing, stateful firewall dropping
replies, NAT mistranslation, or client-side filtering — capture at
client + midpoints, compare tuples/IDs; DNS logic exonerated by the
capture pair. A: "Firewall on the way back." W: Restart named.
F: Which capture detail matches request to reply? (Port/ID tuple.)
T: —

**Q109. When may you flush a production resolver cache, and what must
accompany it?**
E: After the owning layer is identified and fixed at source (else it
re-poisons from upstream stale), scoped (flushname/tree), per node,
with a reason in the ticket; security-driven staleness = flush freely;
convenience flushes that mask root cause = banned. A: Fix-then-flush.
W: Flush first. F: Flushing clients before the resolver — why useless?
T: —

**Q110. NXDOMAIN spike alarm an hour after a change window. Triage.**
E: Top NXDOMAIN names from resolver logs → map to the change (deleted-
but-alive name? renamed without alias? suffix/search-list dependency?)
→ liveness sources identified → rollback vs comms vs alias decision;
this alarm existing at all is the Day 107 spec paying off. A: Check
what was deleted. W: Ignore ("users mistype"). F: Which runbook
executes if it's deleted-but-alive? (Rollback per RB-27 + comms.)
T: —

**Q111. One subnet times out to the resolver; another is fine. Order
your suspects with proofs.**
E: Path/firewall drop (capture at resolver: silence from that subnet →
firewall change log); resolver ACL would REFUSE not drop (rcode
discipline); return-route asymmetry (capture pair); client-side agent/
policy last; T25's script. A: Firewall first. W: "Resolver ACL"
without the rcode logic. F: The single strongest sentence for the
firewall team? ("Zero packets arrive from X" + capture.) T: REFUSED-
vs-drop confusion.

**Q112. The resolver answered a name it hosts no zone for. Walk a
junior through why that's fine.**
E: Recursion is its job: it fetched/cached from the authoritative
chain; "non-authoritative" labels provenance, not error; authority
lives where AA is set; then show the same name at auth for contrast.
A: Cache explanation. W: Investigates the "anomaly." F: When IS an
answer-without-zone suspicious? (Authoritative-only server responding
→ view/config surprise.) T: —

**Q113. Design the poisoning-scare checklist (T35) in five items.**
E: What exact RRset/when cached/from which server (dumpdb provenance);
plausible-legit variance (CDN/geo/anycast of the AUTHORITY)?;
randomization/cookie posture intact?; out-of-bailiwick or unexpected
NS data in cache?; DNSSEC status of the domain (would validation have
caught it?) — verdict + document either way. A: Three items. W: Panic
or dismiss. F: Which item most often closes it as benign? (Variance.)
T: —

**Q114. Two independent faults in one ticket (T49): what discipline
catches the second?**
E: Run the ladder to completion after the first finding; every symptom
must be explained by the evidence set — unexplained residue = keep
digging; report lists each fault with independent proof. A: "Keep
checking." W: Fix first find, close. F: Which pairs co-occur
naturally? (Lame NS + missing record; stale cache + failed push.)
T: —

**Q115. What evidence expires fastest in a DNS incident, and how do
you preserve it?**
E: Cache state (TTLs drain, entries vanish): dumpdb + timestamped digs
FIRST; query logs (rotation); the broken answer itself (capture before
any flush); flush destroys the crime scene — evidence, then surgery.
A: Capture before flushing. W: Flush then investigate. F: Which file
is the cache snapshot? T: —

## K. CHANGE MANAGEMENT & BULK (Q116–123)

**Q116. Why does a delete outrank its corresponding add in risk?**
E: Negative caching penalty on mistake+rollback, burden of proving
non-use (liveness), dangling-reference creation (CNAME/MX/SRV
pointing in), and half of T-catalogue; hence liveness+dependency gates
are delete-specific. A: Negative cache + references. W: "Deletes are
scarier." F: The TXT liveness blind spot? (Q59/79.) T: —

**Q117. Value-match deletion: the rule and the incident it prevents.**
E: Delete rows must match name+type+VALUE against deployed reality —
name-only deletes can remove a round-robin member or a different
record than intended (T06/T50's landmines). A: Rule stated. W: Deletes
by name. F: Which pre-check output proves it? T: —

**Q118. Batching doctrine for 400 rows — defend it in three sentences.**
E: First batch is a canary bounding damage to batch size; per-batch
post-checks catch systematic errors (mapping shifts) before they
multiply; total time cost is minutes vs hours of unwinding a
skip-and-continue disaster (T32). A: Canary idea. W: "Run it all,
we tested one row." F: Batch size logic? (Small enough to unwind,
big enough to finish.) T: —

**Q119. The rollback artifact: define "good."**
E: Captured BEFORE apply, covers all touched objects, in re-applicable
form (import-compatible export / exact record lines + TTLs + serial
note), stored with the ticket, and tested conceptually against the
half-applied case (batch bookkeeping). A: Pre-change export. W: "We
can restore from backup." F: Why is nightly backup not a rollback
artifact? (Wrong granularity/time; co-mingles unrelated changes.)
T: —

**Q120. Objective rollback triggers — why pre-agree them?**
E: Deciding during the incident invites hybrid states and sunk-cost
pushing; pre-agreed "post-check X fails at T+15 → roll back" makes the
decision mechanical under pressure and auditable after. A: "Decide
in advance." W: "Roll back if it feels broken." F: Who owns the
trigger call in your window? T: —

**Q121. Friday 16:40, director pressure, flawed bulk CSV (T50). Your
move and its form.**
E: Written refusal-as-composed with findings table; repaired path
offered (corrected rows, rollback artifact, batching, TTL ramp,
checkpoint); own-senior escalation with evidence; partial "safe rows"
execution declined — no undocumented hybrids into a weekend. A: Refuse
+ fix plan. W: Run the safe-looking rows. F: Why is partial execution
the worst outcome? T: The partial-execution temptation.

**Q122. TTL choreography for a migration's POINTERS — why is it the
step that fails (T26)?**
E: Plans ramp record TTLs but forget NS/glue RRset TTLs — the records
deciding WHERE resolvers go; old estate must serve until pointer-TTL
expiry; the drain graph (old estate QPS→0) is the objective proof.
A: NS TTL matters. W: "Propagation was slow." F: Define the
no-going-back point. T: —

**Q123. Change comms: the sentence that must appear after every
create/delete.**
E: The convergence caveat as clock time: "live at source HH:MM; caches
converge by HH:MM (+negative-TTL for creates); stragglers until then
are expected" — TTL honesty is the anti-ticket vaccine. A: Mentions
caching delay. W: "Done." F: The create-specific extra clock?
T: —

## L. MIGRATION & DR (Q124–129)

**Q124. Five phases of a zone migration with the gate of each.**
E: Inventory (dependency+parameter diff complete) → ramp (record AND
pointer TTLs low, verified held) → parallel-serve (export diff =
byte-identical, per-universe checks) → pointer cutover (parent NS/glue
+DS switched) → drain+decommission (old QPS→0 over pointer-TTL, then
delegation hygiene). A: Phases minus gates. W: "Copy zone, switch NS."
F: The signed-zone extra gate? (DS/keys plan.) T: —

**Q125. Parameter diff (T45): name four invisible zone parameters that
must be compared.**
E: SOA MINIMUM (negative physics), EXPIRE/REFRESH/RETRY (replication+DR
window), $TTL defaults, transfer/TSIG topology, and signing policy —
template regressions change estate behavior with zero record diffs.
A: SOA timers. W: Records-only diff. F: Which one changed rollout
latency 12× in T45? T: —

**Q126. Your primary died Friday 19:00, EXPIRE 3 days. Compute and
plan.**
E: Secondaries dark ~Monday 07:00 per-node from last refresh (T23):
window = restore or promote (convert secondary, re-wire transfers/
notify/platform architecture); signed zones: locate keys before RRSIG
margin dies (second clock); alarms should have fired on refresh age
long before. A: Expiry math. W: "Secondaries keep serving." F: What
turns this from serving problem into signing crisis? (Keys only on the
corpse.) T: —

**Q127. Decommission a zone completely — the checklist.**
E: Announce → liveness watch to zero over a real window → remove data
→ REMOVE parent delegation (T42) → flush/tree on owned resolvers →
archive final export + audit note → monitoring cleanup. A: Data+
delegation. W: Delete zone. F: The symptom of skipping step four?
(Slow SERVFAILs instead of crisp NXDOMAIN.) T: —

**Q128. Promote-a-secondary runbook: the five re-wirings.**
E: Zone type flip (secondary→primary) on the chosen node; transfer
topology re-pointed (other secondaries' primaries{}); NOTIFY direction
re-drawn; TSIG relationships re-keyed as needed; platform/smart-
architecture re-materialized + serial forward-safe; then estate-wide
serial/answer verification. A: Type flip + repoint. W: "Restore
backup instead" (fine, but answer the question). F: Serial hazard in
promotion? (Promoted node's serial behind another copy → arithmetic
freeze.) T: —

**Q129. What does the old estate's query-rate graph prove during
drain, and why is it better than any checklist?**
E: Objective measure of remaining resolvers still holding old
pointers — decay to ~zero over pointer-TTL is empirical convergence;
checklists assert intent, the graph measures reality; premature
shutdown with nonzero QPS = T26. A: Traffic proves usage. W: "Wait
24h to be safe." F: A stubborn trickle persists — sources? (Long-TTL
violators, hardcoded resolvers, monitoring relics.) T: —

## M. ARCHITECTURE (Q130–140)

**Q130. Draw (verbally) the reference enterprise estate and the four
data flows.**
E: External auth (public zones, hardened) + hidden primary + internal
auth estate + resolver tiers with static-stub to internal, cond-fwd to
AD, egress for internet, RPZ/logging at resolvers; flows: internal→
internal name, internal→internet name, internet→public name, AD-zone
updates; each flow's failure mode named. A: Components minus flows.
W: "Some DNS servers inside and outside." F: Which flow breaks when
static-stub routes vanish? T: —

**Q131. Hidden primary: guarantees, costs, and the T43 lesson.**
E: Edit/signing surface off the serving path; costs: explicit notify,
special-box monitoring/DR; the "hidden" property is purely NS-set
discipline — any leak into NS makes it public routing info. A:
Benefits+notify. W: "Extra secure master." F: How do you AUDIT
hiddenness? (Parent+child NS sets + external query test.) T: —

**Q132. Anycast for resolvers: sell it, then attack it.**
E: Sell: proximity latency, BGP-speed site failover, DDoS dilution,
one client config forever; attack: per-instance divergence invisible
via the shared IP (T28), flap-driven instance switches, ops need
instance identity + per-instance probes + flush automation aware of
all instances. A: One side well. W: Buzzwords. F: The one-query trick
for instance identity? (id.server/hostname.bind CH TXT.) T: —

**Q133. Views vs separate estates for split-horizon — pick for a
50k-employee enterprise and defend.**
E: Separate estates: dumber and safer at scale (independent failure/
security domains, no match-clients ordering bugs, cleaner DNSSEC),
cost: more servers + data duplication discipline; views: economical,
one leak-prone box; EIP tips the balance to separate/managed. Defensible
either way — the defense quality is the grade. A: Tradeoffs listed.
W: "Views, it's less servers" full stop. F: The four horsemen of view
leaks? (NAT, new subnets, VPN pools, ACL order.) T: —

**Q134. Which ten things does DNS monitoring watch (Day 107 spec) —
recite eight.**
E: Per-instance answer correctness; serial spread; refresh-age/expiry
margin; SERVFAIL+NXDOMAIN rates; latency percentiles; QPS/top-N;
RRSIG margin + DS consistency; transfer/TSIG error rates; NTP offset;
config/L1-L2 drift. A: Six. W: "Uptime and port 53." F: Which two
predicted T23? T: —

**Q135. Why is "port 53 answers" a dangerous health check?**
E: It proves liveness of a socket, not correctness of answers, view
selection, zone freshness, or role contract — T12/T28/T46 all pass
that check while broken; monitor the contract (AA on hosted zones,
expected values, serials). A: "Need deeper checks." W: Defends ping.
F: Compose the minimal honest authoritative probe. (Hosted-zone SOA
expecting aa + serial compare.) T: —

**Q136. GSLB: what does DNS become, and the TTL knob's two edges?**
E: A control-system output publishing health decisions; low TTL = fast
failover but oscillation-sensitive + high load + per-query authority
dependence; high TTL = calm but slow failover; tune the CONTROLLER
(checks/hysteresis) before the messenger (T36). A: Failover via DNS +
TTL tradeoff. W: "DNS load balancing." F: Why can a healthy service
flap in GSLB? (Marginal probe thresholds/path jitter.) T: —

**Q137. Where do DoT and DoH belong in an enterprise design?**
E: Offer encrypted transport ON corporate resolvers (stub→resolver
leg), disable third-party DoH via endpoint policy/canary, egress-block
known DoH endpoints as depth, keep resolver-tier policy (RPZ/logging)
authoritative — encryption yes, bypass no (T37). A: Own-resolver DoT +
block others. W: "Block encryption" or "allow everything." F: The
detection for bypass? (Firewall-vs-resolver-log discrepancy.) T: —

**Q138. AD DNS in the estate: the three integration facts.**
E: AD zones live on DCs (AD-replicated, not zone-transferred),
GSS-TSIG dynamic updates + scavenging lifecycle, resolvers reach them
via cond-fwd/static-stub — you route to AD's universe rather than
absorb it; SRV records are its lifeblood (T18). A: Two facts. W: "AD
has its own DNS, ignore it." F: What breaks when a client uses a
non-corporate resolver? T: —

**Q139. Capacity/failure math: how many NS, how many resolver nodes,
and what actually limits you?**
E: NS: ≥2 topologically diverse (protocol handles selection/retry) —
more buys diversity not linear capacity; resolvers: N sized so N−1
carries peak (cache-hit ratio dominates load); real limits: cache-miss
upstream latency, per-node cache divergence ops cost, and the humans
flushing them; anycast shifts the math to per-site. A: Redundancy
counts. W: "Two of everything." F: Why does adding resolver nodes
worsen staleness incidents? (More independent caches — T19.) T: —

**Q140. Present your fictional-enterprise design's THREE riskiest
decisions and their mitigations (capstone C6 rehearsal).**
E: (Format answer:) each decision named with the risk owned honestly +
mitigation + monitoring hook, e.g., views-vs-estates choice / hidden
primary DR / DNSSEC scope+rollover automation / resolver-tier depth —
grading is on ownership of tradeoffs, not on picking "the right"
architecture. A: Decisions without mitigations. W: "My design has no
big risks." F: (Examiner picks one and pushes — practice with
Vanessa reading the F-lines.) T: Claiming risklessness.

## N. AUTOMATION & BULK DISCIPLINE, CONCEPT LEVEL (Q141–144)
*(Scripting deferred by design — these test the thinking that survives
tool changes.)*

**Q141. What must ANY bulk-change tool verify per row, regardless of
implementation?**
E: Syntax (FQDN/type/IP/TTL), semantics vs deployed reality
(existence + value match by operation), collision taxonomy, dependency
sweep, PTR plan, range policy — the checks are the product; the tool
is packaging. A: Syntax+existence. W: "Valid CSV format." F: Which
check requires querying authority, not parsing? T: —

**Q142. Dry-run mode: define it honestly.**
E: Executes every read/check and produces the full decision report +
would-be change set, performing zero writes — dry-run that skips
checks is a lie; output should be diffable against the post-change
verification. A: "Simulates the change." W: "Prints the CSV."
F: What's the EIP-native analogue? (Import preview.) T: —

**Q143. Forward/reverse consistency checking: the algorithm in words.**
E: For every A: PTR exists and maps back to exactly that name (or
policy-documented exception); for every PTR: forward exists and
matches; both directions, run per zone pair, exceptions listed not
silently skipped — output is a drift report feeding §3's catalogue.
A: "Check A↔PTR both ways." W: One direction. F: Which direction
finds orphan PTRs? T: —

**Q144. Why did we defer scripting until after mastery, in one
sentence you believe?**
E: Automation multiplies whatever understanding exists — encode the
checks after you can perform and defend them manually, or you ship
your misconceptions at machine speed. A: "Learn manual first."
W: "Scripts are risky." F: First script you WILL write in December,
and its runbook ancestor? T: —

## O. THE META-QUESTIONS (Q145–150)

**Q145. "How do you know when DNS is NOT the problem?"**
E: When each layer answers correctly with evidence (flags/TTL/values)
along the app's actual path AND the true cause is identified elsewhere
— exoneration = correct-everywhere proof + named culprit; until the
culprit is named, DNS stays a suspect with an alibi, not innocent.
A: Layered proof. W: "When dig works." F: The app's-actual-path tool
on Linux? T: —

**Q146. What would you monitor about DNS that most shops don't, and
why?**
E: Pick 2–3 with stories: serial spread (T12), refresh-age vs expire
(T23), per-instance consistency (T19/T28), RRSIG margin (T31),
NXDOMAIN top-N post-change (blast radius), L1/L2 drift (T20/T47) —
each is a pre-incident signal for a ticket class you can cite.
A: Two without stories. W: "Uptime." F: Which one is free to start
tomorrow? (Serial spread — a cron of SOA digs.) T: —

**Q147. Teach TTL to a junior in three sentences, no metaphors
wrong.**
E: Every answer carries a countdown set by the zone owner; every cache
serves its copy until the countdown ends, then re-asks; therefore
changes are visible per-cache within the OLD countdown, and "DNS is
slow" is usually arithmetic working as designed. A: Correct, wordier.
W: "Time DNS takes to propagate." F: Extend for negatives in one more
sentence. T: The propagation phrasing.

**Q148. A senior disagrees with your diagnosis. Process?**
E: Re-state the claim as evidence (layer, command, output), invite the
alternative to make a testable prediction, run the discriminating test
live — the estate arbitrates, not seniority; update loudly if wrong.
A: "Show evidence." W: Defer or dig in. F: What if the test is
impossible right now? (Preserve evidence, bound both hypotheses,
choose reversible action.) T: —

**Q149. What are the three most dangerous sentences in DNS
operations?**
E: Candidates you can defend: "It's just a cleanup" (T06/T42/Q59);
"I'll fix it directly on the server, faster" (T21/T47); "DNS has
propagated, we're done" (TTL/negative tails); also "the GUI shows
it's fine" (L1≠L2). Grading = the incident story attached to each.
A: Two with stories. W: Jokes without mechanisms. F: Your own
near-miss for one of them (journal has candidates by now). T: —

**Q150. Why does DNS mastery transfer to every other system you'll
operate?**
E: It's distributed state + caching + eventual consistency + layered
truth + change discipline in their purest form — the ladder, the
three layers, TTL honesty, and evidence-before-surgery are generic
engineering under DNS names. A: "Teaches troubleshooting." W: "DNS
is everywhere." F: Name the non-DNS system where you'll apply the
three-layers model next. T: —

---
**Grading sheet:** `Q# | tier (E/A/W) | date | rework date | second-pass
tier`. Program target: ≥120 E. Interview reality: an A answer delivered
calmly beats a memorized E delivered brittle — record yourself, listen
for hedging words, and strip them.
