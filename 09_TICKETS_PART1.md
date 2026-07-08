# SECTION 11 — TROUBLESHOOTING TICKET SIMULATOR, PART 1 (Tickets 1–25)
### Packet 6 — Intermediate → Advanced

**Protocol (strict):** read Complaint/Background/Data ONLY. Write your
investigation plan, then your diagnosis (cause + proof commands + fix + the
red herring you rejected) BEFORE reading Path/Diagnosis. Grade: 2 pts correct
diagnosis, 1 pt correct proof method, 1 pt red herring identified, 1 pt
customer answer quality. ≥4/5 = pass. Log every score (cumulative ≥80%
required at the Level 6 gate). Tickets marked **[LAB]** should be reproduced
in the lab before reading the answer.

Names/IPs are synthetic (corp.example, lab.internal, 10.10/172.20/192.168.50).

---

### T01 — "DNS is wrong, fix it now" [intermediate] [LAB: LAB 6]
**Complaint:** App team: "You changed app2.corp.example an hour ago but half
our clients still hit the OLD server. Your change failed."
**Background:** Planned change 13:00: app2 10.10.20.16 → 10.10.30.16. TTL 3600
(nobody ramped it down).
**Data:** `dig @auth1 app2.corp.example` → 10.10.30.16, aa, TTL 3600.
`dig @resolver1 app2…` → 10.10.20.16, no aa, TTL 2417 and falling.
**Red herring:** "The change failed" — the auth answer disproves it instantly.
**Path:** authoritative first (correct, aa) → resolver (old, TTL draining =
cache, converges by 14:00) → client caches inherit the bound.
**Diagnosis:** No fault. TTL physics: caches honor the pre-change TTL 3600.
**Tempting wrong:** "Replication broke / EIP didn't deploy" — disproven by aa.
**Customer answer:** "Change is live at source since 13:00. Caches hold the
old address up to 60 min (TTL) — full convergence by 14:00; we can flush the
corporate resolvers to pull that forward. Process fix for next time: TTL
ramp-down before the window."
**Senior explanation:** State the convergence bound BEFORE such changes;
propose ramp-down choreography (TM 3.4) as the systemic fix.

### T02 — "The record I added doesn't exist" [intermediate] [LAB: LAB 5]
**Complaint:** "Created newsvc.corp.example 10 minutes ago; users still get
'name not found'. Your platform is broken."
**Data:** `dig @auth1 newsvc…` → A 10.10.20.88, aa. `dig @resolver1` →
NXDOMAIN, AUTHORITY: corp.example SOA, TTL 512 falling. Monitoring had been
polling the name since yesterday.
**Red herring:** "platform broken" — auth answers fine.
**Diagnosis:** Negative caching. Monitoring queried the name pre-creation;
resolver caches NXDOMAIN for SOA-minimum 900 s.
**Tempting wrong:** "Zone transfer lag" — the SOA-in-authority NXDOMAIN with
draining TTL is the negative-cache signature, and auth already answers.
**Customer answer:** "Live at source. Resolvers cached the earlier 'doesn't
exist' — clears in ≤9 min or immediately with a targeted flush (doing now).
For go-lives: create the record before anything polls it."
**Senior explanation:** SOA MINIMUM as a product decision; sequencing beats
flushing.

### T03 — "nslookup says non-authoritative — DNS is broken" [intermediate]
**Complaint:** Junior admin escalates: "Every lookup on this server says
*Non-authoritative answer* — the resolver must be degraded."
**Data:** `nslookup portal.corp.example` → correct IP, "Non-authoritative
answer". Apps work fine.
**Red herring:** the entire ticket.
**Diagnosis:** Normal recursive behavior — the label means "answer from
cache/recursion, not from zone authority." Nothing is degraded.
**Tempting wrong:** agreeing and "investigating the resolver."
**Customer answer:** teach the flag; show `dig @auth` with aa for contrast.
**Senior explanation:** turn it into 5-minute education; log it as a
recurring training gap, not an incident.

### T04 — Works by IP, fails by name, but only for ONE tool [intermediate]
**Complaint:** "db1.corp.example unreachable from server lx-app-07 — but
only for our app; ping works!"
**Data:** On lx-app-07: `ping db1.corp.example` → 10.10.20.30 replies.
`dig db1.corp.example` → 10.10.20.30. App log: "connecting to 10.10.99.30…
timeout."
**Red herring:** "DNS resolves fine, so DNS-adjacent config can't be the
issue" — the app isn't using DNS.
**Path:** the app's resolved IP ≠ DNS answer → where else can a name→IP come
from? `/etc/hosts` → entry `10.10.99.30 db1.corp.example` (old migration
leftover); nsswitch `files dns`.
**Diagnosis:** Stale hosts-file entry shadowing DNS for libc consumers the
app uses differently than ping? (ping also uses NSS — so if ping got .30,
check app-specific config: connection string with hardcoded IP, or app
container's own /etc/hosts). Two valid variants — the lab arms the container
variant.
**Tempting wrong:** "resolver intermittently wrong" — no evidence; both dig
and ping agree.
**Customer answer:** name the exact non-DNS source found, remove it, and
state the general rule: DNS was exonerated by evidence (dig + getent).
**Senior explanation:** the exoneration pack (Day 86): dig, getent, hosts
file listing, app config line — app teams can't argue with artifacts.

### T05 — "app1 works in Madrid, fails in Luxembourg" [intermediate]
**Complaint:** Same laptop, same user, short name `app1` resolves at HQ,
NXDOMAIN at the LX office.
**Data:** `Resolve-DnsName app1 -DnsOnly` in LX shows attempts:
app1.lx.corp.example (NXDOMAIN), app1.corp.local (NXDOMAIN). In Madrid it
tried app1.corp.example first. FQDN app1.corp.example works everywhere.
**Diagnosis:** DHCP-delivered connection-specific suffix / search-list
differs per site; short-name expansion never tries corp.example in LX.
**Tempting wrong:** "LX resolver missing the record" — FQDN works there.
**Fix:** correct DHCP option (search list) or GPO; interim: use FQDNs.
**Customer answer:** show the expansion attempts from the -DnsOnly output —
it's self-documenting.
**Senior explanation:** short names are a client-config feature, not a DNS
namespace feature; document the corporate suffix policy.

### T06 — Two A records, "obviously a duplicate, delete one" [intermediate]
**Complaint:** Cleanup ticket: "portal-api.corp.example has TWO A records
(10.10.40.21, 10.10.40.22). Duplicate — remove the second."
**Data:** dig shows both, answers rotate order. Query logs: heavy traffic.
Monitoring shows both IPs serving HTTPS with ~equal hit counts.
**Red herring:** the word "duplicate" in the ticket.
**Diagnosis:** Intentional round-robin — deleting one is a 50% capacity cut.
**Path:** RB-02 value/round-robin gate → owner question → owner confirms LB
pair.
**Customer answer:** refuse with evidence; correct the ticket taxonomy;
optionally tag records with owner metadata so the next "cleanup" doesn't
recur.
**Senior explanation:** "same name+type, different value" is §4 case 2 —
never actioned without owner intent. This exact refusal is a senior marker.

### T07 — Reverse lookup shames the wrong server [intermediate] [LAB: LAB 4]
**Complaint:** Security: "SIEM shows attacks from old-db.corp.example
(10.10.20.16). Shut it down!" — but old-db was decommissioned months ago.
**Data:** `dig -x 10.10.20.16` → old-db.corp.example. `dig old-db… A` →
NXDOMAIN. `dig app2.corp.example` → 10.10.20.16.
**Diagnosis:** Orphan/stale PTR: IP re-used by app2, reverse zone never
updated. SIEM attribution is wrong; the "attacker" is app2 traffic.
**Tempting wrong:** treating the reverse zone as "broken infrastructure" —
data staleness, not service failure. Also wrong: hunting a ghost server.
**Fix:** update PTR 16→app2.corp.example (RB-06); process: reverse updates
bound to IP-reassignment workflow (IPAM linkage).
**Customer answer:** corrected attribution + fixed record + note that
historical SIEM entries carry the stale name.
**Senior explanation:** forward/reverse are linked by process only; show the
drift class and the IPAM control that closes it.

### T08 — "Add a CNAME for a name that already has an A" [intermediate]
**Complaint:** "Please add shop.corp.example CNAME → vendor-lb.example.net.
Platform refuses: record exists."
**Data:** `dig @auth1 shop.corp.example A` → 10.10.40.60 (live traffic in
query logs).
**Diagnosis:** Type conflict (§4 case 3): CNAME cannot coexist with the A.
This is a *replace* request in disguise → owner decision + planned two-step
(delete A, add CNAME) with a gap and TTL plan — or keep A and change its
target IP instead.
**Tempting wrong:** "platform bug, force it" or silently deleting the A.
**Customer answer:** explain the protocol rule in one line, present the two
lawful options with their downtime math, get a decision in writing.
**Senior explanation:** the refusal isn't bureaucracy; a forced coexistence
is undefined behavior — and the delete+add gap under TTL 300 is a visible
outage window to plan, not hide.

### T09 — Deleted a record, "users still resolve it — your delete failed"
[intermediate]
**Complaint:** "old-portal.corp.example removed at 09:00; at 09:20 users
still get 10.10.40.9."
**Data:** all auths: NXDOMAIN, aa. Resolver: answer with TTL 847 falling
(was 3600).
**Diagnosis:** TTL again — deletion converges like any change; caches serve
until expiry (≤10:00).
**Tempting wrong:** re-deleting, or hunting "a rogue DNS server" — the
draining TTL names the resolver cache precisely.
**Customer answer:** ETA + optional flush; add: after expiry users get
NXDOMAIN, and if the app should show a redirect page instead, that's an app
change, not DNS.
**Senior explanation:** deletes need the same convergence comms as adds —
RB-02's closing statement verbatim.

### T10 — "Half the intranet broke" after a wildcard change [intermediate+]
[LAB: Day 17 shadowing]
**Complaint:** After adding `metrics.apps.corp.example TXT "owner=obs"`,
users report metrics.apps... web UI down. Nothing else changed.
**Data:** `dig metrics.apps.corp.example A` → NODATA (NOERROR/0 answers).
Yesterday it resolved via `*.apps.corp.example A 10.10.60.100`.
**Diagnosis:** Wildcard shadowing: creating the exact name (any type) stops
wildcard synthesis for ALL types at that name → A queries now NODATA.
**Fix:** add explicit `metrics.apps A 10.10.60.100` alongside the TXT (or
remove the TXT).
**Tempting wrong:** "TXT records can't break A lookups" — they can, via
exact-name existence.
**Senior explanation:** wildcards synthesize only for nonexistent names;
every exact-name creation under a wildcard needs the full record set stated.
This is TM 2.4's trap, live.

### T11 — Delegated zone dead after "server refresh" [advanced] [LAB: 3b]
**Complaint:** Everything under dev.corp.example SERVFAILs since the dev
team rebuilt their DNS VM last night. corp.example fine.
**Data:** `dig NS dev.corp.example @auth1 +norecurse` → ns1.dev… (glue
172.20.0.20). `dig SOA dev.corp.example @172.20.0.20 +norecurse` → REFUSED.
**Diagnosis:** Lame delegation: rebuilt server lacks the zone (or ACLs
default-deny). Parent still points at it.
**Path:** parent NS set → interrogate each listed NS directly expecting aa
→ the REFUSED names the lame one → fix child (restore zone) or parent
(point elsewhere) — child-side here.
**Tempting wrong:** "resolver problem" (SERVFAIL at resolver is symptom);
flushing caches forever.
**Customer answer:** the rebuilt server must serve the zone again; interim
resolver-side static-stub to a surviving secondary if one exists.
**Senior explanation:** delegation health = parent set, child set, reality
agreeing (TM 2.6 audit sequence, run in 3 commands).

### T12 — Secondary serves ancient data [advanced] [LAB: 10 break 1]
**Complaint:** "Users get different answers for db1.corp.example depending
on… something. 50/50 old/new IP."
**Data:** `dig @auth1 db1` → new IP, serial 2026100907. `dig @auth1sec db1`
→ old IP, serial 2026100812. Resolver alternates (round-robins the NS set).
**Diagnosis:** Secondary stale → serial not incremented on some past change
(or transfers failing since). Check: primary log for NOTIFY, secondary log
for refresh errors; `rndc zonestatus` on secondary for last refresh/expiry
countdown.
**Fix:** serial++ (if forgotten) or repair transfer path; `rndc retransfer`
to converge now.
**Tempting wrong:** blaming the resolver's "flapping cache" — per-auth digs
kill that in 20 seconds.
**Senior explanation:** authoritative servers CAN disagree; monitoring must
track serial spread; the 50/50 pattern is the NS-rotation fingerprint.

### T13 — Zone transfer REFUSED after firewall change [advanced] [LAB: 11]
**Complaint:** Secondary alarms: corp.example transfer failing since last
night's "security hardening".
**Data:** Secondary log: `transfer of 'corp.example/IN' from
172.20.0.10#53: failed while receiving responses: REFUSED`. Primary
security log: nothing for the secondary's expected IP; instead requests
arriving from 172.20.0.99 — REFUSED (not in allow-transfer).
**Diagnosis:** The "hardening" inserted NAT/routing change → secondary's
transfer requests now source from a different IP than the ACL expects.
(TSIG variant: BADSIG lines instead.) TCP works (REFUSED ≠ timeout) — pure
policy/source-IP.
**Fix:** ACL to the true source IP (or fix the NAT); prefer TSIG so identity
isn't IP-hostage.
**Tempting wrong:** "TCP 53 blocked" — REFUSED proves the TCP conversation
happened.
**Senior explanation:** rcode-vs-timeout discipline: REFUSED = policy at the
responder; the responder's log names the observed source — always read both
ends.

### T14 — Internal users suddenly get the PUBLIC address [advanced]
[LAB: 8b]
**Complaint:** Users in new subnet 10.10.61.0/24 can't reach
portal.corp.example; it resolves to 203.0.113.40 for them; everyone else
gets 10.10.40.10.
**Data:** `dig @auth1 whichview.corp.example TXT` from an affected client →
"external". From HQ → "internal".
**Diagnosis:** View leak: new subnet missing from the internal
match-clients ACL → falls through to external view.
**Fix:** add 10.10.61.0/24 to internal-nets ACL (and to allow-recursion on
resolvers while at it); process: subnet provisioning checklist includes DNS
ACLs.
**Tempting wrong:** "zone data changed" — it differs by vantage, not time;
the marker TXT proves view selection in one query.
**Senior explanation:** every split-horizon estate should carry a marker
record; every new-subnet runbook must touch DNS ACLs. Two sentences that
prevent the entire class.

### T15 — Everything slow, then fine, in waves [advanced] [LAB: Day 37]
**Complaint:** "Random 3–5 s delays opening ANY site, then instant for a
while."
**Data:** Clients point at fwd1. `dig @fwd1 example.net` sometimes 2000+ ms
then SERVFAIL, sometimes instant. `dig @resolver1 example.net` always fast.
fwd1 config: `forwarders { 172.20.0.53; 172.20.0.99; };` — .99 was
decommissioned last month.
**Diagnosis:** Dead forwarder in the list: fwd1 intermittently tries .99,
burns timeout, then fails or fails over; cache hits mask it between waves.
**Fix:** remove the corpse; add monitoring on forwarder health.
**Tempting wrong:** "internet is slow / upstream ISP" — resolver1 direct is
fast; the pattern (waves + fixed extra delay quantum) fingerprints a
timeout in the path.
**Senior explanation:** latency quanta are diagnostic: consistent ~N-second
additions = a timeout constant somewhere; hunt the list with a corpse in it.

### T16 — Only big lookups die [advanced] [LAB: 2/9]
**Complaint:** "Mail team: DKIM validation for partner domain fails from
our network only. Their support says it works everywhere."
**Data:** `dig @resolver1 selX._domainkey.partner.example TXT` → timeout,
retries, eventually SERVFAIL. Same with +bufsize=4096. `+bufsize=512` →
TC → then TCP attempt → **connection timed out**. `dig +tcp @8.8.8.8`
from a test VM outside → works. Small records from the same domain: fine.
**Diagnosis:** TCP 53 blocked outbound from the resolver segment (and
fragments of >MTU UDP dying) → any answer too big for one UDP packet is
unreachable. The record is huge (DKIM).
**Fix:** open TCP 53 for the resolvers; keep EDNS at 1232.
**Tempting wrong:** "partner's DNS is broken" — external vantage disproves;
"corrupt record" — size-selectivity is the tell.
**Senior explanation:** the size-dependent failure signature IS the
diagnosis: small=fine/large=dead means transport, never data.

### T17 — SERVFAIL for one domain, resolver-wide [advanced] [LAB: 14b]
**Complaint:** vendorportal.example (external, real-world analog) SERVFAILs
on corporate resolvers since 02:00. Works on phone hotspots.
**Data:** `dig @resolver1 vendorportal.example` → SERVFAIL. `+cd` → answer!
`delv` → "broken trust chain: RRSIG has expired".
**Diagnosis:** The domain's DNSSEC signatures expired (their fault);
validating resolvers everywhere reject it; hotspot resolver either doesn't
validate or… check. +cd proving data-retrievable = validation-class failure.
**Action:** contact domain owner; interim (business-critical + risk-accepted
+ time-boxed): negative trust anchor for the domain — documented, expiring,
approved.
**Tempting wrong:** flushing caches, blaming firewall — +cd settles the
class in one query.
**Senior explanation:** C8 chain verbatim; SERVFAIL+cd-works+delv-verdict
is the three-step DNSSEC triage; NTA is a scalpel with a timer, never a
default.

### T18 — Kerberos/AD chaos in one branch [advanced]
**Complaint:** Branch office: logins slow, printers gone, shares fail.
"Network is fine, must be DNS."
**Data:** From branch client: `Resolve-DnsName _ldap._tcp.dc._msdcs.ad.corp.example -Type SRV`
→ NXDOMAIN. A-record lookups (portal, internet) fine. Branch clients got a
local ISP resolver via a mis-scoped DHCP option during yesterday's DHCP
work.
**Diagnosis:** Clients using an external resolver that can't see internal
AD zones → SRV discovery dead → AD services collapse while "DNS works" for
public names.
**Fix:** correct DHCP option 6 to corporate resolvers; flush clients.
**Tempting wrong:** "DC is down" — DC is fine; discovery is blind.
**Senior explanation:** AD lives on SRV + internal zones; any client not on
corporate resolvers loses AD *by design* of split-horizon. Check "which
resolver" before checking any service.

### T19 — One resolver of four lies [advanced] [LAB: variant of 6]
**Complaint:** "Intermittent wrong IP for pay.corp.example — roughly 25% of
attempts, any office."
**Data:** VIP fronts four resolver nodes. Direct digs: nodes A,B,D new IP;
node C old IP TTL 5100 falling (someone set TTL 7200 before the change).
**Diagnosis:** Per-node cache staleness — node C cached seconds before the
change. 25% = 1 of 4 nodes.
**Fix:** `rndc flushname pay.corp.example` on node C; monitoring idea:
per-node answer-consistency probe for hot names.
**Tempting wrong:** "load balancer broken / app flapping" — per-node
interrogation (bypass VIP — the ladder, rung 3) ends it.
**Senior explanation:** a VIP hides N independent caches; percentage of
failure ≈ stale-nodes/N is a fingerprint worth teaching the NOC.

### T20 — Update "applied" but server answers old — EIP context [advanced]
[LAB: Day 67]
**Complaint:** Requester: "GUI shows the new IP for erp.corp.example since
11:00, but dig still returns the old one. Your platform lies."
**Data:** L1 (object): new value, audit trail 11:00. L2:
`dig @auth1 erp… ` → old value, aa, serial unchanged since yesterday.
Platform sync status for auth1: last push FAILED 11:00 (connection refused
— auth1's management agent hung).
**Diagnosis:** Deployment layer: change staged in the object DB, push to
the managed server failed; server truthfully serves what it has.
**Fix:** restore management connectivity, re-deploy, verify L2 serial+value;
review alerting on failed pushes (why did a human find it first?).
**Tempting wrong:** "TTL/caching" — the AUTH serves old with aa; caches are
downstream of the real problem.
**Senior explanation:** three-layer report verbatim (07 §6): "L1 updated
11:00; L2 push failed (evidence); L3 irrelevant until L2 converges." That
sentence structure is what separates you from the ticket queue.

### T21 — Dynamic zone corrupted by a helpful admin [advanced] [LAB: 12]
**Complaint:** After a colleague "quickly fixed a typo directly in the zone
file", the DHCP-driven zone stopped taking updates; log spams journal
errors.
**Data:** named log: `journal rollforward failed: journal out of sync with
zone`. Zone serves, but nsupdate → SERVFAIL/update failures.
**Diagnosis:** Hand-edit of a journal-backed dynamic zone without
freeze/thaw → file/journal desync.
**Fix:** `rndc freeze` (if possible), reconcile: keep the file as desired
truth → delete the stale .jnl → `rndc thaw`/reload → verify updates flow;
then the teaching moment.
**Tempting wrong:** restoring from backup wholesale (loses the day's
dynamic records) without assessing what the journal held.
**Senior explanation:** dynamic zones' truth lives in journal+memory; the
file is a lagging snapshot. Freeze/thaw is not bureaucracy — it's the sync
protocol.

### T22 — Security blocklist ate a business site [advanced] [LAB: 13]
**Complaint:** "partner-billing.example NXDOMAIN on corporate network,
resolves fine at home. Started after yesterday's threat-feed update."
**Data:** `dig @resolver1 partner-billing.example` → NXDOMAIN. But
`dig @resolver1 … +dnssec` shows no SOA of the parent… and resolver log:
`rpz QNAME rewrite partner-billing.example`. External dig: normal answer.
**Diagnosis:** RPZ false positive from the new feed.
**Fix:** passthru exception (`partner-billing.example CNAME rpz-passthru.`)
in the local override RPZ (evaluated before the feed), vendor FP report,
documented review date.
**Tempting wrong:** "their DNS broke" — home-vs-office split + the rewrite
log line settle it.
**Senior explanation:** every feed needs a local-override zone ordered
first, an FP process, and rewrite logging shipped to SOC — say all three
and you sound like you've run this before (you have — in the lab).

### T23 — Monday-morning total DNS death, expiry edition [advanced]
[LAB: Day 53]
**Complaint:** Monday 08:30: SERVFAIL for ALL of corp.example from
everywhere. Friday change: "primary maintenance."
**Data:** Primary down since Friday 19:00 (maintenance never completed).
Secondaries: `rndc zonestatus corp.example` → expired. SOA expire: 259200
(3 days)… Friday 19:00 + ~60h ≈ Monday 07:00. Timeline fits.
**Diagnosis:** Zone EXPIRED on the secondaries — they refuse to serve
(SERVFAIL) per protocol. The outage was scheduled by the SOA record three
days in advance; nobody was watching refresh failures all weekend.
**Fix:** restore/promote primary, retransfer; systemic: alert on refresh
failure age (fraction of expire), not just server-up.
**Tempting wrong:** attacking the resolvers (they're honestly relaying
authoritative refusal); "secondaries crashed" — they're up, the ZONE state
expired.
**Senior explanation:** expire is the DR contract (TM 4.5); monitoring
must count down toward it. "Serving" and "healthy" differ by a timer.

### T24 — "EfficientIP says the record already exists" — all four ways
[advanced, EIP]
**Complaint:** Four separate requesters, same week, same error string.
**Data per case:** (a) requested app1 A 10.10.20.15 — dig shows exactly
that. (b) requested app5 A 10.10.20.61 — dig shows app5 A 10.10.20.51.
(c) requested files.corp.example A — node holds CNAME→nas.corp.example.
(d) requested PTR for 10.10.20.90 — reverse zone already auto-holds a PTR
from an IPAM assignment to another name.
**Diagnosis:** §4 taxonomy 1/2/3/4 respectively. Actions: (a) close as
satisfied with evidence; (b) owner decision — typo vs round-robin intent;
(c) design decision — replace or refuse; (d) IPAM lifecycle fix first.
**Tempting wrong:** one generic answer for four different realities;
force-flags.
**Senior explanation:** demonstrate the taxonomy table itself — this ticket
IS the oral-exam answer for "walk me through 'already exists'."

### T25 — The haunted subnet [advanced capstone-ish] [LAB: Day 81 technique]
**Complaint:** "DNS totally dead for 10.10.60.0/24. Fine everywhere else.
Resolver team says resolvers healthy."
**Data:** From a .60 host: `dig @172.20.0.53 anything` → connection timed
out (UDP and TCP). From .50: instant. Resolver `tcpdump port 53` while .60
tests: **zero packets arriving**. Traceroute from .60 to resolver dies at
the segment firewall hop. Firewall change log: new zone policy yesterday
"cleanup unused rules".
**Diagnosis:** Network/firewall drop of port 53 (both transports) from that
subnet — DNS service exonerated by the empty capture (queries never
arrive).
**Path discipline:** timeout ≠ DNS rcode → capture at the server first
(cheapest bisect: did anything arrive?) → walk the path → change log.
**Tempting wrong:** resolver ACLs (would REFUSE, not drop — and packets
would appear in capture); "client misconfig" (subnet-wide pattern).
**Customer answer:** to the firewall team with the capture attached; to the
users with restoral ETA; to your own team: the exoneration pack filed.
**Senior explanation:** "no packets at the server" is the strongest
sentence in networking — one tcpdump converts a DNS blame-war into a
one-line firewall fix.

---
**Scoring log template:**
`T## | date | my diagnosis | correct? | proof method ok? | red herring caught? | customer answer ok? | score /5`
Cumulative tracker feeds the Level 6 gate (≥80%). Tickets 26–50 (senior
difficulty: migrations gone wrong, anycast divergence, NOTIFY storms,
DNSSEC rollover failures, EIP bulk incidents, multi-cause composites) ship
in Packet 7.
