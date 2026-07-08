# SECTION 13 — FLASHCARDS & MEMORY SYSTEM
### Final packet — Spaced-repetition deck

**System:** import into Anki (or paper boxes). Schedule: new cards on the
day their topic appears in the calendar; review daily in the 10-min slot
(Mentor Loop §2). A card is "mature" after 3 clean recalls spaced ≥3 days.
Failed card → tomorrow + weak-topics.md. Format per card:
Q / A / Why it matters / Trap.

---

## A. CORE CONCEPTS

**C01** Q: Domain vs zone? A: Domain = namespace subtree; zone =
administratively served portion bounded by delegation cuts. Why: the unit
of authority/transfer/signing. Trap: assuming every subdomain is a zone.

**C02** Q: The four resolver roles? A: Stub (asks, caches), recursive
(iterates, caches), forwarder (delegates recursion upstream, caches),
authoritative (serves zone data, AA). Why: every ticket starts by naming
the role. Trap: "the DNS server" without a role.

**C03** Q: What does a referral contain? A: Empty ANSWER; AUTHORITY = child
NS; ADDITIONAL = glue; no AA. Why: the mechanism of iteration. Trap: glue
is hint data, not parent authority.

**C04** Q: When is glue mandatory? A: NS names in-bailiwick (inside the
delegated zone). Why: circular dependency otherwise. Trap: out-of-
bailiwick NS removes the need entirely.

**C05** Q: NXDOMAIN vs NODATA? A: Name absent vs type absent (NOERROR/0 +
SOA). Why: different causes, both negative-cached. Trap: empty
non-terminals answer NODATA, never NXDOMAIN.

**C06** Q: Negative-cache duration? A: min(SOA MINIMUM, SOA TTL) from the
moment cached, per cache. Why: create-after-query latency. Trap: record
TTL is irrelevant to negatives.

**C07** Q: Three DNS-over-TCP triggers? A: TC=1 retry; AXFR/IXFR; policy/
DoT. Why: "UDP-only firewall" = intermittent size-dependent failures.
Trap: "TCP only for transfers."

**C08** Q: Why 1232 for EDNS? A: Fits min-MTU paths unfragmented — silent
fragment loss becomes clean TC→TCP. Why: modern transport posture. Trap:
the CLIENT advertises the size.

**C09** Q: Split-horizon leak — four horsemen? A: NAT, new subnets, VPN
pools, ACL order. Why: view selection = source IP + first match. Trap:
"data changed" when it differs by vantage.

**C10** Q: forward only vs first under dead upstream? A: only→SERVFAIL;
first→own iteration IF hints/egress work. Why: untested fallback is
theater. Trap: validate the fallback in lab.

**C11** Q: The three layers of truth (DDI)? A: L1 objects (intent), L2
deployed zone data, L3 caches. Why: every finding names its layer. Trap:
blaming L3 (TTL) for L1/L2 gaps.

**C12** Q: Five-layer cache map? A: App → OS stub → forwarder → resolver
node(s) → negatives within each. Why: staleness enumeration. Trap: the
forgotten forwarder layer.

**C13** Q: Wildcard shadowing rule? A: Any exact name (any type) stops
wildcard synthesis for ALL types at that name. Why: a TXT add can kill A
resolution. Trap: T10.

**C14** Q: CNAME exclusivity? A: CNAME must be alone at its node (DNSSEC
metadata excepted); never at apex. Why: §4 case 3 refusals. Trap: apex
"ALIAS" = provider flattening, not CNAME.

**C15** Q: What does DNSSEC provide / not provide? A: Authenticity +
integrity; never confidentiality. Why: DoT/DoH is the privacy tool.
Trap: "DNSSEC encrypts."

**C16** Q: Secure / insecure / bogus? A: Validated (AD); provably unsigned
(signed DS absence — resolves fine); should-validate-but-fails (SERVFAIL).
Why: unsigned ≠ broken. Trap: the middle state exists by design.

**C17** Q: Where does DS live and what does it digest? A: Parent zone;
child's KSK. Why: the one record you don't control. Trap: stale DS after
KSK roll = T30.

**C18** Q: Anycast's hidden cost? A: Per-instance caches diverge behind
one IP. Why: T28; monitoring must probe instances. Trap: flushing "the
resolver" = flushing one instance.

**C19** Q: RPZ's two blind spots? A: Clients on other resolvers/DoH;
direct-to-IP traffic. Why: honest scoping to security teams. Trap:
overselling.

**C20** Q: TTL 0 means? A: No caching — every lookup rides to authority.
Why: load + inherited authority availability per query. Trap: not "agile
best practice."

## B. FLAGS & RCODES

**F01** Q: qr aa rd — who answered? A: An authoritative server, from zone
data. Why: source truth. Trap: AA proves source, not correctness.

**F02** Q: qr rd ra, no aa, TTL draining? A: Recursive resolver, cache.
Why: provenance in one glance. Trap: draining across repeats to the SAME
node.

**F03** Q: RD in a response? A: Echo of the query — proves nothing about
recursion happening. Trap: the echo.

**F04** Q: AD vs CD? A: AD: responder validated DNSSEC; CD: querier says
skip validation. Why: +cd is the DNSSEC bisector. Trap: AD ≠
"authoritative."

**F05** Q: TC=1 next step? A: Retry same query over TCP. Why: normal
protocol, only the failed TCP retry is an incident. Trap: treating TC as
an error.

**F06** Q: SERVFAIL first suspicion? A: The path/zone: upstream dead,
broken delegation, expired zone, DNSSEC bogus — bisect per hop, +cd
early. Trap: chains launder REFUSED into SERVFAIL.

**F07** Q: REFUSED meaning? A: Policy at THAT responder (ACL/view/role).
Why: read it at the hop that emitted it. Trap: REFUSED ≠ down (TCP
conversation happened).

**F08** Q: Timeout meaning? A: Transport — nothing DNS-level returned.
Why: capture at server = cheapest bisect. Trap: ACLs REFUSE, they don't
drop.

**F09** Q: +norecurse against a resolver? A: Cache X-ray — answers only
from cache. Why: staleness/liveness probe without polluting. Trap:
per-node on farms.

**F10** Q: NOERROR + 0 answers + SOA in authority? A: NODATA. Why: the
SOA is the negative-cache timer. Trap: not an error.

## C. RECORDS

**R01** Q: SOA SERIAL rule? A: RFC 1982 arithmetic — secondaries act only
on increase; backwards = frozen. Why: replication protocol in one number.
Trap: recovery = retransfer or +2^31 wrap.

**R02** Q: SOA EXPIRE? A: How long secondaries serve without successful
refresh, then SERVFAIL. Why: your real DR deadline (T23). Trap: staleness
invisible in flags until the cliff.

**R03** Q: SOA MINIMUM (modern)? A: Negative-cache TTL (RFC 2308). Why:
create-latency physics. Trap: historic "default TTL" meaning is dead.

**R04** Q: MX two rules? A: Lowest preference first; target = hostname
with A/AAAA — no CNAME, no IP literal. Trap: the CNAME target.

**R05** Q: SRV fields? A: priority weight port target (at
_service._proto.name). Why: AD lives on these. Trap: weight only among
equal priorities.

**R06** Q: Long TXT mechanics? A: 255-byte strings, multiple quoted
segments concatenated by consumers. Why: DKIM truncation incidents.
Trap: exactly ONE v=spf1 per name.

**R07** Q: PTR owner for 10.10.20.15? A: 15.20.10.10.in-addr.arpa. Why:
octet reversal reflex. Trap: nothing links PTR↔A except process.

**R08** Q: CAA does? A: Which CAs may issue certs; walked up labels at
issuance. Why: "cert renewal failed" tickets. Trap: absent CAA = any CA.

**R09** Q: Round-robin caching? A: Whole RRset cached per TTL; rotation
at serving side; balance averages across clients. Trap: "duplicate"
deletion = capacity surgery (T06).

**R10** Q: Trailing-dot bug? A: Dotless target gets $ORIGIN appended →
name.zone.zone NXDOMAIN. Why: the classic zone-file hour-burner. Trap:
hides in CNAME/MX/SRV targets.

## D. BIND OPERATIONS

**B01** Q: Zone-change lifecycle? A: edit→checkzone→serial++→reload→
NOTIFY→SOA check→IXFR/AXFR→converged→caches drain. Why: name the failure
at each arrow. Trap: NOTIFY is a hint; REFRESH is the guarantee.

**B02** Q: IXFR needs? A: Delta history (journal; static zones need
ixfr-from-differences); else clean AXFR fallback. Trap: fallback is
correct behavior, not an error.

**B03** Q: TSIG log triage? A: BADSIG=secret, BADTIME=clock, BADKEY=name,
plain REFUSED=unsigned vs key ACL. Why: four different fixes. Trap: NTP
is a DNS dependency.

**B04** Q: freeze/thaw contract? A: Flush journal→file, suspend updates,
edit, resume. Why: dynamic-zone truth = journal+memory (T21). Trap:
hand-edit without it = desync.

**B05** Q: rndc reload vs reconfig? A: reload re-reads zones; reconfig =
config + NEW zones only. Why: busy-server safety. Trap: —

**B06** Q: One-command estate audit? A: named-checkconf -z (config + every
zone load). Why: triage step 2, always. Trap: passes ≠ semantically right
data.

**B07** Q: zonestatus gives? A: Loaded/serial/type/refresh timers/expiry
countdown. Why: THE secondary-health command. Trap: check before any
surgery.

**B08** Q: BIND triage order? A: status → checkconf -z → zonestatus →
logs → dig local (right view) → dig remote → surgery last. Why: evidence
before change. Trap: dig-and-flush reflex.

**B09** Q: allow-update vs update-policy? A: Whole-zone grant vs
per-key/name/type least privilege. Why: AD-style self-updates pattern.
Trap: unkeyed allow-update = anyone writes.

**B10** Q: RRL's slip trick? A: Periodic TC replies — real clients retry
TCP, spoofed victims get nothing. Why: amplification defense that spares
users. Trap: —

**B11** Q: Query log flags +E T D S? A: RD, EDNS, TCP, DO, TSIG-signed.
Why: read the line, know the client. Trap: —

**B12** Q: Pre-deletion blast-radius technique? A: Grep N-day query logs
for the name; hits = alive, find sources. Why: prevents T-class deletion
incidents. Trap: external verification TXTs never show liveness.

## E. EFFICIENTIP / DDI

**E01** Q: "Already exists" four realities? A: Exact dup / same-name-
diff-value / type conflict / automation collision. Why: four different
actions. Trap: one generic response.

**E02** Q: Smart architecture =? A: Template materializing one logical
zone as wired primary/secondaries across members. Why: it's BIND
underneath — Chapter 4 skills apply. Trap: hand edits get overwritten.

**E03** Q: Auto-PTR silent failure? A: Reverse zone not under platform
management → forward-only creates. Why: drift class #2. Trap: "IPAM
keeps it consistent" — only for managed paths.

**E04** Q: L1≠L2 causes? A: Staged change, failed push, unreachable
agent, hand-edit divergence. Why: T20/T47. Trap: the TTL reflex.

**E05** Q: Bulk import — four facts first? A: Mapping preview, on-error
semantics, dry-run existence, round-trip export. Why: T32 prevention.
Trap: skip-and-continue + shifted columns.

**E06** Q: Value-match deletes because? A: Name-only can hit round-robin
members or wrong record. Why: T50 landmines. Trap: —

**E07** Q: Rollback artifact standard? A: Captured BEFORE apply,
re-applicable form, covers all touched objects, handles half-applied.
Trap: nightly backup ≠ rollback artifact.

**E08** Q: Break-glass rule? A: Direct edits only with mandatory
reconciliation before next deploy. Why: T47's second outage. Trap:
"faster on the server."

## F. TROUBLESHOOTING DECISION POINTS

**T01** Q: Wrong answer — opening move? A: Provenance ladder: client →
each resolver node → each auth → parent. Why: deepest wrong layer owns
it. Trap: stopping at first plausible cause (T49).

**T02** Q: Timeout — opening move? A: tcpdump at the server: did anything
arrive? Why: strongest bisect in networking (T25). Trap: theorizing past
an empty capture.

**T03** Q: ~25% failure rate? A: One stale node of four behind
VIP/anycast. Why: T19/T28 fingerprint. Trap: diagnosing through the VIP.

**T04** Q: Fixed +N-second latency? A: A corpse in a list (dead
forwarder/NS) burning a timeout. Why: T15 fingerprint. Trap: "internet
is slow."

**T05** Q: Size-dependent failure? A: Transport: EDNS/fragmentation/TCP
blocked — bufsize matrix + +tcp. Why: T16/T48. Trap: "record corrupt."

**T06** Q: SERVFAIL, +cd works? A: DNSSEC validation class → delv →
DS/DNSKEY/RRSIG chain. Why: three-query triage. Trap: only-my-resolver
= my anchor/clock/path.

**T07** Q: Fix verified, user still broken? A: Client-side cache —
including Windows NEGATIVE cache. Why: Clear-DnsClientCache. Trap:
declaring done at resolver level.

**T08** Q: dig fine, app broken? A: hosts file / nsswitch / app cache /
pinned IP — getent is the app's-eye view. Why: exoneration standard
(T04). Trap: "not DNS" without naming the culprit.

**T09** Q: Evidence that expires fastest? A: Cache state — dumpdb +
timestamped digs BEFORE any flush. Why: flush destroys the crime scene.
Trap: surgery first.

**T10** Q: "DNS propagated, done"? A: Never — state convergence as clock
time + negative-TTL tail. Why: TTL honesty = the senior sentence. Trap:
the word "propagation" as weather.

## G. COMMANDS (drill until reflex)

**K01** Q: Prove authoritative? A: dig @auth name → aa + full TTL every
repeat. Trap: AA ≠ correct data.
**K02** Q: Prove cached? A: No aa + TTL draining across repeats (same
node); +norecurse still answers. Trap: farm nodes differ.
**K03** Q: Negative-cache clock visible where? A: SOA TTL in AUTHORITY of
the NXDOMAIN/NODATA answer, draining. Trap: —
**K04** Q: Targeted resolver purge? A: rndc flushname (tree for subtrees;
full flush = storm). Trap: per node.
**K05** Q: Windows cache view/purge? A: Get-DnsClientCache /
Clear-DnsClientCache (ipconfig /displaydns /flushdns) — negatives show
as "Name does not exist." Trap: —
**K06** Q: Linux app-path lookup? A: getent hosts name (NSS truth); dig
bypasses NSS. Trap: 127.0.0.53 = resolved's view.
**K07** Q: DNSSEC verdict tool? A: delv — "fully validated" vs failing
link named. Trap: dig +cd first to classify.
**K08** Q: Transfer test by hand? A: dig @primary zone AXFR (TSIG: -y
type:name:secret). Why: also the security audit. Trap: unauth success =
finding.
**K09** Q: Estate serial spread? A: dig SOA @each-auth +short, compare.
Why: free monitoring, catches T12. Trap: equality necessary, not
sufficient post-incident (T44).
**K10** Q: Instance identity on anycast? A: dig CH TXT id.server (or
hostname.bind) @IP. Why: T28. Trap: —

---
**Deck maintenance:** every ticket you miss and every exam error becomes
a new card in your own words, added the same day. The deck you graduate
with in November should be ~30% bigger than this file — that growth IS
the learning record.
