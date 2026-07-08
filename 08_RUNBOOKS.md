# SECTION 9 — ENTERPRISE DNS RUNBOOKS
### Packet 5 — 28 runbooks. Change, verify, investigate, migrate, communicate.

**How to read these.** Placeholders: `<name>` FQDN with trailing dot in
commands, `<ip>`, `<zone>`, `<auths>` = EVERY authoritative server for the
zone (primary + all secondaries — post-checks that query one server are not
post-checks), `<resolvers>` = each resolver node directly (bypass VIP).
Lab: auths = 172.20.0.10 (+ .11), resolver = 172.20.0.53. Production: apply
via the DDI platform (EIP), evidence via dig. Risk levels: **L**ow /
**M**edium / **H**igh — H requires a change window + named second person.

**The universal ceremony (every change runbook inherits this):**
```
0. Ticket gate      — approved ticket matches request exactly (07 §5 list)
1. PRE  (evidence1) — deployed state at <auths>; collision taxonomy (07 §4);
                      dependencies; reverse impact; liveness (deletes)
2. ROLLBACK ARTIFACT— captured BEFORE apply (export / dig -x / AXFR snapshot)
3. APPLY            — via platform; timestamp recorded; serial noted
4. POST (evidence2) — every auth: aa + new state + serial advanced;
                      resolver state + convergence ETA; reverse if in scope
5. CLOSE            — ticket updated with evidence1+2 + ETA + comms sent
```

---

## PART A — CHANGE RUNBOOKS

### RB-01 Add A record — Risk L
**Purpose:** publish `<name> A <ip>`. **Inputs:** name, IP, TTL, ticket,
owner, PTR yes/no.
**Pre:** `dig @auth1 <name> A +norecurse` → expect NXDOMAIN or NODATA (else
07 §4 taxonomy: exact dup → close as already-satisfied; other value → owner
question; CNAME present → RB-03 territory/refuse). Per-type sweep:
`for t in CNAME TXT AAAA MX SRV; do dig @auth1 <name> $t +noall +answer +comments; done`
— any CNAME hit blocks. `dig @auth1 -x <ip>` → note PTR plan. IP inside
approved ranges. NOTE: if the name was recently queried while nonexistent,
negative caching applies — capture `dig @<resolvers> <name> A` now to know
who holds negatives.
**Apply:** create record (platform / lab: zone file + serial++ + `rndc
reload <zone>`).
**Post:** every auth: `dig @<auth> <name> A` → `aa`, correct IP, full TTL;
`dig @<auth> <zone> SOA +short` → serial advanced everywhere (secondaries
converged). Resolver: answer OR NXDOMAIN-with-draining-SOA-TTL → state ETA
= negative TTL remaining. PTR created if in scope (RB-05).
**Rollback:** delete the record (exact name+type+value), serial++, flush
resolvers if it was already consumed.
**Failure cases:** "already exists" (→ 07 §4); secondaries not advancing
(→ RB transfer triage inside RB-17/LAB 10 skills); works at auth, "broken"
for users (→ negative cache, quote the ETA, RB-14).
**Escalate when:** collision case 2/3 with unreachable owner; zone serial
not propagating.
**Senior explanation:** "Record live at source 14:02, all four authorities
serving it (aa, serial 2026100901). Anyone who asked for it before 14:02
holds a cached 'doesn't exist' for up to 15 minutes — full visibility by
14:17, or immediately after a targeted resolver flush, which I've done on
resolvers we own."

### RB-02 Delete A record — Risk M (H if round-robin/infra name)
**Purpose:** remove `<name> A <ip>`. **Inputs:** name, EXACT value, ticket,
owner sign-off.
**Pre:** value match: `dig @auth1 <name> A` must return exactly the ticket's
IP — extra IPs = round-robin STOP (deleting a member is capacity surgery,
needs explicit owner statement); different IP = wrong ticket, refuse.
**Liveness:** query logs, N-day grep for `<name>` → hits = who still uses it;
`dig @<resolvers> <name> A +norecurse` → cached = recently used. Live +
no-impact-statement = STOP. **Dependencies:** sweep zone exports for CNAMEs
targeting `<name>`, MX/SRV/NS pointing at it — any hit blocks (you'd create
dangling references). **Reverse:** does PTR for `<ip>` point here → plan its
removal (orphan-PTR prevention).
**Rollback artifact:** the exact record line (name/type/value/TTL) saved.
**Apply:** delete via platform; serial++.
**Post:** every auth → NXDOMAIN (or NODATA if other types remain) with aa;
resolvers → old answer with draining TTL (quote ETA) — do NOT flush unless
the deletion is security-driven; PTR removed per plan.
**Rollback:** re-add saved line; note: clients who received NXDOMAIN
meanwhile hold negatives → flush or quote negative-TTL ETA.
**Failure cases:** deleted wrong round-robin member (symptom: capacity/
health alarms — rollback fast); dangling CNAME discovered post-hoc
(→ RB-16 NXDOMAIN pattern on the alias).
**Escalate:** any liveness hits without impact sign-off; name referenced by
NS/MX.
**Senior explanation:** "Deletion verified at all authorities 15:10. Caches
serve the old answer up to TTL 300 — final disappearance by 15:15. Query
logs showed zero hits in 14 days and no records reference the name, so
blast radius is empty; rollback is a one-line re-add held in the ticket."

### RB-03 Add CNAME — Risk M
**Purpose:** alias `<name>` → `<target>`. **Inputs:** name, canonical
target, TTL, ticket.
**Pre:** node must be EMPTY: per-type sweep at `<name>` — ANY existing
record (A, TXT, MX…) blocks (CNAME-and-other-data, TM 2.2); `<name>` must
not be zone apex; **target health:** `dig @resolver <target> A/AAAA` resolves
(a CNAME to nothing ships an outage); target is not itself a long CNAME
chain (>1 hop = smell, >2 = refuse pending design talk); target must not be
an MX/NS-target relationship you'd be breaking.
**Apply/Post:** as ceremony; post includes following the chain end-to-end
from a resolver: `dig @resolver <name> A` → chain + final address.
**Rollback:** delete CNAME (node returns to empty).
**Failure cases:** "exists" because an A is there → this is a REPLACE
request in disguise — separate decision + downtime math (delete A + add
CNAME is two changes with a gap); wildcard interactions (name now exact-
exists → wildcard stops covering it for all other types → NODATA surprises).
**Escalate:** apex-CNAME requests (offer alternatives, TM 2.2), replace-
disguised requests.
**Senior explanation:** "web.corp.example is now an alias for
portal.corp.example — one lookup chain, resolvers return the chain plus
portal's address. Chose CNAME over a second A so future portal IP changes
propagate with zero edits here."

### RB-04 Delete CNAME — Risk L/M
**Pre:** confirm the node holds exactly the expected CNAME→target; liveness
via query logs; check nothing DOCUMENTS the alias as an interface (app
configs — ask owner). **Apply/Post/Rollback:** ceremony; rollback = re-add
one line. **Failure:** users of the alias get NXDOMAIN post-delete —
that's the intended outcome ONLY if liveness said dead; otherwise you just
learned your liveness window was too short. **Senior explanation:** "Alias
removed; canonical name untouched and unaffected. Alias consumers — query
logs showed none in 21 days — would see NXDOMAIN with negative caching of
15 minutes."

### RB-05 Add PTR — Risk L
**Purpose:** `<ip>` → `<name>` reverse mapping. **Inputs:** ip, fqdn,
ticket. **Pre:** reverse zone for the subnet EXISTS and is served
(`dig @auth1 <rev-zone> SOA` — missing zone is a different, bigger ticket:
RB-06); existing PTR at the octet? (replace vs add decision — multi-PTR
legal but policy says one); **forward consistency:** `dig @auth1 <name> A` →
should return `<ip>` (PTR to a name that doesn't forward-resolve = orphan at
birth; document exception or fix forward first).
**Apply/Post:** ceremony; post: `dig @<auths> -x <ip>` → aa + name;
round-trip check: name→ip→name closes.
**Rollback:** remove PTR line.
**Senior explanation:** "Forward and reverse now agree — app1→10.10.20.15→
app1 round-trips. Mail, SSH reverse checks, and SIEM attribution for that
address are clean."

### RB-06 Fix missing/stale reverse DNS — Risk L→M
**Purpose:** repair the C2 class: reverse absent or pointing at history.
**Inputs:** ip(s), correct fqdn(s), evidence of current forward truth.
**Pre:** classify: (a) no reverse ZONE (subnet unmanaged — create/delegate
zone: an infrastructure change, H-adjacent, own runbook step with resolver
routing per LAB 4 note), (b) zone exists, PTR absent → RB-05, (c) PTR stale
→ this: `dig -x <ip>` shows old name; `dig <oldname> A` (often NXDOMAIN —
orphan proof); `dig <newname> A` = `<ip>` (current truth).
**Apply:** replace PTR (delete old value, add correct — one transaction
where platform allows). **Post:** round-trip closes; orphan gone.
**Failure:** multiple stale PTRs at one IP (accumulated history) — clean
all, keep one; IPAM object still carrying the old name → fix the object or
the platform will happily recreate the past.
**Senior explanation:** "The reverse zone was healthy; the DATA was stale —
a forward rename last year never touched reverse. Fixed the pair and the
IPAM object so the platform's intent matches; added round-trip consistency
to the post-checks of rename tickets so this class dies."

### RB-07 Add MX / TXT / SRV / CAA — Risk M (MX/TXT: mail-impacting → treat as M/H)
**Shared pre:** node not a CNAME; type-specific:
- **MX:** target is a hostname WITH A/AAAA and NOT a CNAME; preference
  agreed relative to existing MX set; mail team sign-off mandatory.
- **TXT/SPF:** if `v=spf1` — there must remain EXACTLY ONE spf TXT
  (merging is a mail-team edit, not two records); >255-char strings split
  correctly (DKIM: verify the published key reassembles — post-check with
  `dig <sel>._domainkey.<zone> TXT +short` and compare to source).
- **SRV:** `_service._proto` labels exact; target hostname with A/AAAA,
  not CNAME; priority/weight/port confirmed against the service owner.
- **CAA:** understand issuance impact — a wrong CAA blocks cert renewals
  estate-wide at the worst moment; security team sign-off.
**Post:** type-appropriate dig from auths + resolver; for mail records,
explicitly hand the mail team the evidence and let THEM confirm function.
**Senior explanation (MX flavor):** "MX added at preference 20 as backup
route; primary at 10 untouched; target resolves A from all resolvers. Mail
flow validation is with messaging — DNS layer evidence attached."

### RB-08 Bulk add from CSV — Risk M→H by size/content
**Purpose:** N record creations as one governed operation. **Inputs:** CSV
per 07 §8 standard, ticket, owner, window if H.
**Pre (the gate):** syntactic pass (format, dupes, conflicts, ranges) →
semantic pass per row (07 §4 taxonomy at auths; PTR plan; dependency notes)
→ produce a **validation report**: rows OK / rows blocked+why. ANY blocked
row → decision: repaired CSV (new file, re-validated) or partial execution
explicitly approved. Import mapping preview checked; on-error behavior
known.
**Rollback artifact:** zone export (all touched zones) timestamped now +
the CSV itself (its inverse = the delete file).
**Apply:** batches of ≤50; after each batch spot-check 5 rows at auths
(aa + value) before continuing. First batch = canary; surprise → HALT.
**Post:** 100% row verification loop at one auth + sampled verification at
every other auth; serial spread zero; report: applied/verified/anomalies.
**Rollback:** execute the inverse (bulk delete of exactly these
name+type+value rows) — you generated it before starting.
**Failure cases:** mapping shifted one column (canary catches it — this is
WHY canary); mid-run platform error with skip-and-continue semantics → the
verification loop, not the import log, defines what actually applied.
**Escalate:** validation report ≥10% blocked (the request is dirty —
back to requester wholesale).
**Senior explanation:** "312 of 320 rows validated; 8 blocked (5 exact-
duplicates closed as satisfied, 2 CNAME conflicts returned to owner, 1
out-of-range IP). Applied in 7 batches with canary verification; 100%
post-verified across all four authorities; inverse file and pre-export
filed as rollback."

### RB-09 Bulk delete from CSV — Risk H
Everything in RB-08 PLUS per-row: **value match** (name+type+value against
deployed — mismatch = block), **liveness** (query-log window — hits =
block pending owner), **dependency sweep** (zone-export grep for each name
as a CNAME/MX/SRV/NS target — hits = block), **PTR companion plan** per
row. Batches smaller (≤25). Post: NXDOMAIN/NODATA verified per row at all
auths; comms MUST carry the negative-TTL caveat ("names invisible
everywhere ≤ old TTL; re-creation within <negTTL> would be delayed —
speak now"). Rollback = the pre-export re-imported (then flush resolver
negatives for any re-added names).
**Escalate:** ANY liveness hit; any NS/MX/glue name in the file (that's
not a bulk row, that's an architecture change smuggled into a CSV).
**Senior explanation:** "400 requested; 361 executed. 27 blocked live
(query hits ≤14d — list attached with source IPs), 9 value mismatches
(ticket data stale vs reality), 3 were CNAME targets. The 361 verified
gone at all authorities; negative caching means re-adding any of them
today costs up to 15 min visibility lag — rollback pre-export is filed."

## PART B — VERIFICATION MICRO-RUNBOOKS (the reusable atoms)

### RB-10 Detect duplicate records — Risk none (read-only)
Zone export (platform export / `dig @auth <zone> AXFR` where permitted) →
normalize (lowercase, strip TTL) → sort → group by (name,type):
- same name+type+**same** value twice: true duplicate (platform artifact/
  import residue) → cleanup candidate.
- same name+type+**different** value: NOT automatically a duplicate —
  round-robin vs conflict → owner question with evidence (this distinction
  is the whole skill).
- same name different type: fine, EXCEPT anything coexisting with CNAME.
Report: classified list, no action without owners.

### RB-11 Validate existing records before change — Risk none
The pre-check atom: for each name in scope — deployed value at auths
(aa), per-type sweep, reverse state, dependency grep, liveness, IPAM/L1
object state, platform audit trail (who touched it last — context gold).
Output: a table `name | deployed | expected-per-ticket | verdict
(match / mismatch / collision-case-N)`. Any non-match verdict = the change
does not proceed as written.

### RB-12 Confirm authoritative answer — Risk none
`dig @<each-listed-NS> <name> <type> +norecurse` → require: `aa` set, full
zone TTL, consistent across ALL listed NS (parent NS set per RB-21 first if
in doubt), serial equal across servers (`dig @each <zone> SOA +short`).
Any server missing aa or lagging serial → that server is the story.

### RB-13 Confirm recursive cached answer — Risk none
Two queries, few seconds apart, to ONE resolver node: no `aa`, TTL
decrementing → cached, learn-time = zoneTTL − remaining. `+norecurse`
returns it → confirmed in-cache. Per-node loop across the farm → cache
divergence map (who cached what when).

### RB-14 Force or wait for TTL expiry — Risk L (flush touches prod behavior)
Decision: **wait** when remaining TTL < urgency threshold or resolvers
aren't yours (state ETA = remaining TTL, checked via RB-13). **Force** when
business impact says so AND you own the resolvers:
`rndc flushname <name>` per node (flushtree for a zone-wide fix), then
client caches (`Clear-DnsClientCache` guidance to affected users /
`resolvectl flush-caches`), THEN verify with RB-13 that the next fetch
pulled fresh data — flushing while the authority still serves old data
just re-caches the problem (fix order: authority first, always).

## PART C — INVESTIGATION RUNBOOKS
All read-only until root cause; each = symptom → ladder (CMD §11) →
proofs → fix-class → escalation line.

### RB-15 Stale cached answer
**Symptom:** "DNS returns the old IP." **Path:** RB-12 at auths (new value?
NO → not a cache problem at all — data problem, stop, fix data); YES →
RB-13 per resolver node (find the node(s) with old RRset + draining TTL) →
client cache check. **Fix:** RB-14 decision. **Root-cause duty:** WHY was
old data cached this long — TTL policy? change executed without ramp-down?
one farm node that never converged (its own forwarder path stale)? The
flush is relief; the answer is the WHY. **Escalate:** stale AFTER TTL
mathematically expired (clock issues, >TTL caching by an appliance, or
someone's "helpful" pinning — now it's interesting).

### RB-16 NXDOMAIN
**Order:** typo/suffix reality first — `dig +qr` / `Resolve-DnsName -DnsOnly`
to see the EXACT fqdn asked (Windows suffix expansion is suspect #1) →
RB-12: does the name exist at auths? NO → was it ever supposed to?
(creation ticket lost? record deleted? — platform audit trail) → YES at
auth but NXDOMAIN at resolver → negative cache (RB-13 shows the SOA-timer
entry; RB-14) OR the resolver resolves the name via a DIFFERENT tree
(split-horizon/forwarding scope — RB-20) → wildcard expectations ("it
should wildcard-match" → TM 2.4 shadowing rules).

### RB-17 SERVFAIL
**Meaning:** the responding server tried and failed. **Bisect:** `+cd`
retry FIRST (works with +cd → DNSSEC class → RB-23). Else per-hop direct
queries down the chain (client's resolver → its forwarder/upstream → auths):
first hop failing direct interrogation owns it. At that hop: recursion
broken (can it reach roots/upstream? egress?), zone broken (expired
secondary — `rndc zonestatus`; load error in logs), delegation broken
(RB-21), upstream ACL (REFUSED upstream surfaces as SERVFAIL downstream —
check the upstream's security log). **Escalate:** SERVFAIL for MANY
unrelated zones on one resolver = that resolver's recursion/egress, treat
as incident.

### RB-18 REFUSED
**Meaning:** policy said no — config, not failure. Enumerate against the
refusing server: are you in `allow-query`? asking recursion where
`allow-recursion` excludes you (or recursion no)? hitting a view whose
match-clients doesn't include your SOURCE address (NAT!)? asking a server
for a zone it doesn't serve while recursion is off? unsigned transfer where
TSIG required? **Proof:** the server's security-category log names the
denied ACL. **Fix-class:** correct the ACL/view OR correct the client's
resolver target (half of REFUSED tickets are clients configured at the
wrong server). **Senior line:** "REFUSED is the server working as
configured — the question is whether the configuration or the client's
expectation is wrong."

### RB-19 Intermittent DNS issue
The senior differentiator. **First move: turn 'sometimes' into a
distribution** — intermittent by WHAT? (a) **by resolver node**: per-node
RB-13 sweep → one bad node (stale/divergent/broken) behind the VIP;
(b) **by authoritative server**: RB-12 across all NS → one lame/stale/
expired secondary answering its share of queries; (c) **by size/transport**:
fails only for big answers → LAB 9 matrix → RB-22; (d) **by time**:
correlates with TTL expiry moments (each expiry = one slow/failing
re-fetch → upstream weakness), or with load (RRL, capacity);
(e) **by client population**: subnet/VPN/view boundary → RB-20/RB-22.
Capture BEFORE it heals: timestamps, exact rcode, which server answered
(`;; SERVER:` line) — intermittents are solved with evidence hygiene, not
inspiration. **Escalate:** cross-zone intermittents on shared
infrastructure = incident, not ticket.

### RB-20 Split-horizon mismatch
**Symptom:** different answers for the same name by vantage point —
determine INTENDED vs LEAK. Map: which resolver did each client use
(`ipconfig /all`, `Resolve-DnsName -Server` tests, NRPT, DoH suspicion)
→ which VIEW/estate answered (the marker-TXT trick: `dig whichview.<zone>
TXT @server` from each vantage) → view selection inputs (client SOURCE ip
as the server sees it — NAT boundaries) → per-view zone DATA (maybe views
are fine and one view's data is stale — serial check per view).
**Classic causes:** new subnet/VPN pool missing from internal ACL; client
hardcoded 8.8.8.8/DoH; internal record accidentally created only in the
external view (or vice versa); NAT translating internal clients to an
address the ACL reads as external.
**Senior explanation:** "Not flapping data — two coherent universes and the
client crossed the boundary. Fixed the boundary (ACL), not the data."

### RB-21 Broken delegation
**Audit (TM 2.6 Q30):** parent's NS set (`dig NS <child> @<parent-auth>
+norecurse` — referral view), child's own NS set (`dig NS <child>
@<child-NS> +norecurse` — expect aa), REALITY: `dig SOA <child>
@<every-listed-NS> +norecurse` — every listed server must answer aa.
Classify: lame server (listed, not serving — LAB 3b variants), missing/
wrong glue (referral's ADDITIONAL empty/wrong), parent-child NS drift
(sets disagree), all-lame (SERVFAIL for the whole subtree — C3).
**Fix at the layer that's wrong** (parent data vs child config) — and
flushtree the child domain on resolvers after (they cached the bad
referral). **Escalate:** parent zone not under your control (registrar/
another team) — evidence pack + handoff.

### RB-22 Firewall-related DNS failure
**Signature grammar:** timeout = drop (nothing returned); REFUSED/SERVFAIL
= DNS-level responses — the packet ARRIVED, firewall likely innocent.
**Matrix:** UDP small (`dig +bufsize=512` forcing small) vs UDP large
(bigtxt-class) vs TCP (`+tcp`) — from BOTH a working and failing vantage:
- all fail from one subnet, work from another → path/ACL for that subnet;
- UDP ok, TCP times out → TCP 53 blocked (transfers + truncation retries
  dying — C7/C4 flavors);
- small ok, large UDP silent-fails, TCP ok → fragment filtering (cap EDNS
  1232 / fix filter);
**Prove direction:** capture at both ends (`tcpdump -ni any port 53` on
server; client-side capture) — query arriving? answer leaving? answer
arriving back? The missing leg names the device to interrogate.
**Escalate:** to firewall team WITH the pcap pair and the exact 5-tuple —
never with "DNS is blocked, please check."

### RB-23 DNSSEC-related failure
**The C8 chain, operationalized:** symptom SERVFAIL → `+cd` works ⇒
validation failure class → `delv <name> @<resolver>` verdict text
("fully validated" vs "broken trust chain" / "signature expired") →
localize: OUR problem (only our resolvers fail; public validators fine →
stale trust anchor, clock skew, middlebox stripping EDNS/DO, forwarder
mangling) vs THEIR problem (public validating resolvers also SERVFAIL →
domain's chain broken: `dig DS <zone> @parent` vs `dig DNSKEY <zone>
+dnssec` mismatch, or RRSIG inception/expiration outside now — read the
timestamps).
**Fixes:** ours → anchor/NTP/path repair; theirs → contact owner; business-
critical dependency meanwhile → a **Negative Trust Anchor** (temporary
validation exemption for that zone) as the documented, expiring workaround
— never "turn off validation globally," career-limiting sentence.
**Senior explanation:** "Their DS at the parent doesn't match any published
KSK — a botched key rollover on their side. Everyone validating fails;
non-validating resolvers mask it. NTA applied for 24h with auto-expiry;
tracking their fix."

## PART D — LIFECYCLE & PROCESS

### RB-24 Migrate a zone — Risk H
**Purpose:** move `<zone>` between servers/platforms with zero-to-bounded
impact. **Phases & gates:**
1. **Inventory:** full export old estate; record set diff tooling ready;
   current NS/TTL/SOA documented; consumers identified (resolver configs
   pointing at old servers: static-stubs, forwarders, delegations!).
2. **TTL ramp:** lower NS-record TTLs AND key record TTLs ≥ one old-TTL
   before cutover (TM 3.4 math).
3. **Parallel serve:** new servers loaded (transfer or import), **content
   diff old-vs-new = zero** (gate: any diff explained or fixed), new
   servers answering correctly while NOT yet referenced.
4. **Cutover:** update delegation at the PARENT (NS + glue) / update the
   resolver-side references (stub/forwarder targets) — this is the
   no-going-back-cheaply point; old servers KEEP serving (converging
   traffic drains along NS TTL).
5. **Verify:** RB-12 against new estate; watch query volume MOVE (old
   servers' query logs draining = the truth signal); serial discipline on
   the new primary going forward.
6. **Decommission window:** old servers serve until traffic ≈ 0 AND
   ≥ old-NS-TTL passed, THEN RB-25 them. Premature shutdown = the classic
   migration outage.
**Rollback:** phases 1–3 fully reversible (nothing referenced); post-
cutover rollback = revert parent NS/glue + references (fast because TTLs
are still low — which is WHY you don't restore TTLs until stability
declared).
**Escalate/abort criteria:** content diff non-zero at gate 3; parent
change lead-time (registrar/team) longer than window.

### RB-25 Decommission a zone — Risk H
**Pre:** WHY is it dead — owner attestation + query-log evidence over a
LONG window (weeks); dependency sweep across ALL zones (CNAMEs/MX/SRV
into it), resolver configs (stubs/forwarders referencing it), delegations
FROM it (children!) and TO it (parent cleanup duty), DNSSEC: DS at parent
must be removed BEFORE the zone stops signing/serving (else validating
resolvers hard-fail the leftovers).
**Sequence:** freeze changes → final export (the archive + rollback) →
remove parent delegation (+DS) → let NS TTL drain → stop serving → keep
export N months.
**Failure classic:** zone removed while parent still delegates → lame
delegation + SERVFAILs (C3 self-inflicted); or internal resolvers still
static-stubbing it → SERVFAIL island internally.
**Senior explanation:** "Decommission is a delegation change plus a
retention task — the deletion itself is the trivial part."

### RB-26 Prepare a DNS change ticket
**A complete ticket contains:** WHAT (exact records: name/type/value/TTL —
copy-pasteable), WHY (business line + owner), WHERE (zone/view/estate),
RISK (class per RB matrix + blast radius statement), PRE-CHECK RESULTS
(RB-11 table attached — yes, before approval), WINDOW (or "standard"),
ROLLBACK (artifact named + steps), POST-CHECK PLAN (which queries, from
where, success criteria), COMMS (who's told what, incl. TTL/negative-TTL
caveats), APPROVALS (owner + change authority). **The test:** a colleague
who has never seen the request could execute it from the ticket alone —
if not, it's not ready.

### RB-27 Prepare rollback
**Doctrine:** rollback is designed BEFORE apply, artifact-based, and
tested-in-kind (lab-proven pattern). Per change class: single record →
the exact prior line(s); bulk → pre-execution export in import-compatible
format + inverse CSV; migration → phase-gated reversibility map (RB-24);
zone content → export/AXFR snapshot. **The half-applied problem:** every
rollback plan states what to do if the change PARTIALLY applied (which is
why post-verification loops enumerate per-row/per-record — the rollback
input is the verified-applied list, not the intended list). **Rollback
also propagates:** rolled-back data obeys the same TTL/negative-TTL
physics — say so in the plan's timing.

### RB-28 Communicate findings
**Three artifacts, three audiences:**
- **Incident/status update (app teams, management):** what users
  experience, since when, current state, ETA in wall-clock time — never
  "after the TTL expires," always "by 14:17." No mechanism lecture.
- **Technical findings (peers/seniors):** layer-tagged evidence (L1/L2/L3
  language from 07 §6), commands + outputs, root cause distinguished from
  trigger, what proves it (and what would falsify it).
- **Closure note:** timeline, root cause, fix, WHY it can't silently recur
  (process/monitoring change) — or the honest "it can, and here's the
  detection we added."
**Standing rules:** never promise instant global visibility after any
create/delete (TTL honesty); "DNS is fine" claims ship with the
exoneration evidence pack (Day 86); wrong-layer blame gets corrected with
data, not adjectives.

---
**Cross-reference:** ceremony details 07 §7–8; command semantics file 05;
cache physics TM 3.x; transfer/TSIG failures TM 4.x; every investigation
runbook is drilled by tickets in file 09.
