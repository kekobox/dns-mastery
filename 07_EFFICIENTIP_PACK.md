# SECTION 8 — EFFICIENTIP / SOLIDSERVER MASTERY PACK
### Packet 4b — Concepts, operational workflows, and lab-safe simulation

**Honesty frame (used throughout):** exact GUI paths and API details vary by
SOLIDserver version and by how your enterprise deployed it. Every topic here
is therefore layered as:
- **[U] Universal DNS/IPAM concept** — true on any DDI platform.
- **[E] Common EfficientIP operational pattern** — how SOLIDserver typically
  models/behaves; verify locally.
- **[L] Lab-safe simulation** — how you practice it against your BIND lab.
- **[V] Real-environment validation question** — what to check read-only in
  your corporate SOLIDserver to convert "typical" into "known here."
Never present an [E] statement to colleagues as certainty until its [V] is
answered. That discipline itself is senior behavior.

---

## §1 — What SOLIDserver IS

**[U]** A DDI platform: DNS + DHCP + IPAM under one management plane. Its
core value: DNS records stop being lines in files and become **managed
objects** with ownership, audit trails, rights, workflows, and — crucially —
**linkage to IP address objects**, so forward, reverse, and address
assignment can move as one.

**[E]** SOLIDserver appliances form a management cluster; DNS service is
delivered by **managed DNS servers** — which are commonly **BIND-based**
(EfficientIP "DNS servers" run a BIND engine; the platform can also manage
external/agentless servers, including Microsoft DNS, depending on
deployment). The management plane holds the intended state (objects) and
**deploys/synchronizes** it to the servers that actually answer queries.
"Smart architectures" are EfficientIP's abstraction for multi-server roles:
you manage ONE logical zone; the platform materializes it as
primary/secondaries (master/slave, multi-primary, stealth patterns) across
member servers.

**Consequence you must internalize:** there are now **three layers of
truth** — (1) the object database (what's intended), (2) the zone data on
managed servers (what's deployed), (3) resolver/client caches (what's
remembered). Any of the three can disagree with the others; §6 is the
discipline for proving which layer lies.

**[V] Validation questions:** Which servers in our estate are EIP-managed vs
standalone? Are our "DNS servers" EIP-native (BIND engine) or externally
managed? Which smart architecture template do our production zones use? Where
are the secondaries, and are any hidden/stealth?

## §2 — The object model, practically

**[U→E] The hierarchy you operate:**
```
DNS side:  DNS server (physical/virtual member)
             └─ DNS view (optional — internal/external universes)
                  └─ DNS zone  (type: master/slave/forward/… ; forward or reverse)
                       └─ RR (resource record objects: name, type, value(s), TTL)
IPAM side: Space (an addressing universe — e.g., prod vs lab, or per-tenant)
             └─ Network/Subnet (e.g., 10.10.20.0/24, with metadata)
                  └─ Pool (optional carving)
                       └─ IP address object (10.10.20.15 + name + state + class parameters)
```
**[E]** The magic joint: an **IP address object can carry a name and drive
DNS** — assigning `app1.corp.example` to 10.10.20.15 in IPAM can create the
A record and the PTR together (and deleting it can remove both). Records can
ALSO be created directly on the DNS side, bypassing IPAM linkage — which is
exactly how forward/reverse drift and orphan records are born in
IPAM-managed shops. **Class parameters** = attachable metadata fields
(owner, application, ticket ref) — your audit breadcrumbs.

**Your Day 63 deliverable — the equivalence map (starter, extend it):**
| EIP object | BIND equivalent | Watch out |
|---|---|---|
| DNS server | a named instance | EIP deploys config; hand edits get overwritten |
| View | view{} block | match-clients logic still decides at query time |
| Zone (master) | zone{type primary}+file | serial managed by platform |
| Zone (slave) | zone{type secondary} | transfer path/TSIG managed by platform |
| RR object | a record line | GUI shows the object, dig shows the deployment |
| IPAM address+name | A + PTR pair | only linked if created via IPAM path |
| Smart architecture | primary+secondaries+notify/transfer wiring | one logical edit, multi-server materialization |

**[V]:** In our estate, are records normally created via IPAM (address-first)
or via DNS-zone-first? Do we use views in EIP or separate internal/external
servers? Which class parameters are mandatory on RRs/addresses here?

## §3 — IPAM ↔ DNS coupling: how consistency is made and lost

**[U]** Forward and reverse are protocol-independent (TM 2.8); ONLY process
links them. A DDI platform is that process, mechanized: address-object
operations fan out to A and PTR atomically.

**[E]** Typical behaviors to verify: creating an A record can offer/perform
**automatic PTR creation** if the matching reverse zone is managed on the
platform (no managed reverse zone → forward-only silently, a classic gap);
deleting via IPAM removes the pair, deleting the A directly may orphan the
PTR (or vice versa) depending on how it was created and platform settings.

**Drift catalogue (know these cold):**
1. Record created DNS-side only → no IPAM object → next IPAM-driven
   allocation may collide or the record escapes lifecycle cleanup.
2. Reverse zone not managed/present → auto-PTR never created → forward-only
   estate that "works" until mail/security tooling cares.
3. A deleted, PTR survives (orphan PTR — your baseline C2).
4. IP reassigned in IPAM while an old CNAME still points at the old name.
5. Imports/migrations that loaded zones without back-filling IPAM.

**[L] Simulation:** your Day 64 model sheet (CSV for 10.10.20.0/24 with
columns ip,name,type,ttl,owner,ticket) IS a miniature IPAM: every lab change
this program makes must keep sheet ↔ zone files consistent — you are
role-playing the platform, which is precisely how you internalize what it
does for you and where it can't save you.

**[V]:** Is auto-PTR on here? Are all our reverse zones (10/8 slices, etc.)
under management? What's the official rule when someone needs a record for
an IP that has no IPAM object?

## §4 — "Record already exists": the taxonomy

**[U]** One error string, four different realities. Diagnose which BEFORE
reacting:

| # | Reality | Proof | Correct action |
|---|---|---|---|
| 1 | **Exact duplicate** — same name+type+value already present | GUI/RR search + `dig @auth name type` shows the requested value | No-op: the desired state exists. Close ticket with evidence; do NOT create a second copy |
| 2 | **Same name+type, different value** — potential round-robin vs conflict | dig shows other value(s) | STOP → owner question: intentional multi-A (add as additional member) or a stale/wrong record (change ticket to replace)? Never guess |
| 3 | **Type conflict** — CNAME exists at the name (or you're adding CNAME where A/TXT/etc. exist) | `dig name ANY`-style per-type checks / RR list at the node | Protocol forbids coexistence (TM 2.2). Decide which representation the name should have; that's an owner/design decision, not a force-through |
| 4 | **Collision via automation** — auto-PTR or IPAM linkage already generated the object (e.g., PTR exists from a previous address assignment) | Check the reverse zone / IPAM address object state | Fix the lifecycle: reclaim/clean the address object, then create properly |

**[E]** The platform may report all four with similar wording, and rights
models sometimes hide the conflicting object from your view (you get
"exists" but can't see it → ask an admin, don't assume it's a bug).

**[L]:** Day 65 reproduces 1–4 against lab BIND (checkzone/named refusals for
#3; manual inspection for others) — the collision matrix artifact.

**[V]:** What exact error strings does OUR version emit for each case? Can my
role see all conflicting objects, or do I need elevated eyes for case-hiding?

## §5 — Change surfaces, rights, and approval reality

**[U]** Every DDI platform offers: interactive GUI (one-offs), **bulk
import/export** (CSV-class operations), and an **API** (automation). Rights
narrow who may touch which spaces/zones; mature shops wrap changes in
ticket/approval flow regardless of tooling.

**[E]** SOLIDserver: granular rights per user/group over objects; CSV
import/export workflows for bulk RR and IPAM operations (column mapping at
import time — the mapping step is itself a classic error source); a REST API
(and CLI tooling) for automation — deferred per your program decision, but
know it exists for the oral exam. Audit trail on objects: who
changed what when — your forensic tool for "who created this record" tickets
(pair it with SmartConsole-audit instincts you already have from Check Point
work: same investigative pattern, different product).

**What a senior expects verified before ANY change (your Day 66 list —
memorize):**
1. Ticket/authorization exists and matches the request exactly (names, IPs,
   TTLs — no "while we're at it").
2. Requester owns the name/zone (or owner sign-off attached).
3. Pre-check done against **deployed** reality (dig at auth), not just GUI.
4. Collision taxonomy (§4) cleared for every touched name.
5. Reverse-DNS impact stated (auto-PTR? manual PTR? none — why?).
6. Dependencies checked: CNAMEs pointing at the name, MX/SRV/NS referencing
   it, monitoring/query-log evidence of active use for deletions.
7. TTL implications stated (convergence bound; ramp-down if needed).
8. Rollback artifact prepared BEFORE execution.
9. Post-check plan defined (what query proves success, from where).
10. Comms: who is told, including negative-TTL caveats on creates/deletes.

**[V]:** What are MY effective rights (which spaces/zones/record types)? Is
there an approval workflow inside EIP here, or does approval live only in the
ticket system? Where is the audit trail viewed, and how far back?

## §6 — GUI says X, dig says Y: the three-layer proof

**[U→E]** The layers (§1) and their interrogation:
```
L1 intended:  the RR object in EIP            → GUI/RR list/export
L2 deployed:  zone data on each managed server → dig @each-auth name type  (expect aa)
L3 remembered: resolver + client caches        → dig @each-resolver / client cache tools
```
Divergence diagnosis:
- **L1 new, L2 old** → deployment/sync layer: change staged-not-deployed,
  push failed, target server unreachable, or (ugly classic) someone
  hand-edited the managed server and the platform's state diverged. [E]
  SOLIDserver surfaces server sync status / deployment errors — find where
  in YOUR version [V]. Lab-sim [L]: Day 67 — edit zone file, skip reload:
  "object" changed, service answers old.
- **L2 new, L3 old** → normal TTL physics (TM 3.3) — not a platform issue;
  answer with the convergence timeline.
- **L1 ≠ reality with L2 fine** → stale GUI session/cache or you're reading
  a different view/space than the one deployed — re-query the object fresh,
  confirm view context.
- **Secondaries disagree among themselves at L2** → serial/transfer problem
  under the platform (Chapter 4 skills apply unchanged — it's BIND
  underneath).

**The habit:** never report state from ONE layer. Every finding names the
layer it was observed at: "object updated 14:02 (L1); auth1/auth2 both
serving new (L2, aa, serial 2026091501); resolver cache clears by 14:17
(L3)."

**[V]:** Where do I see per-server deployment/sync status? What does a failed
push look like in OUR interface, and who gets alerted?

## §7 — Single-record change workflow (the ceremony)

**[U]** The universal shape — pre-check → apply → post-check → close, each
producing evidence. Full parameterized versions live in the Runbooks file;
the EIP-flavored skeleton:

**Pre-check (evidence file 1):**
```
dig @auth1 <name> A +norecurse          # current deployed state (expect: matches ticket's 'before')
dig @auth1 <name> ANY-equivalents       # per-type sweep: CNAME? TXT? (collision taxonomy)
dig @auth1 -x <ip>                      # reverse state of the target IP
grep query logs for <name>              # deletions: is it alive?
GUI: RR object + IPAM address object    # L1 state + linkage + class params
```
Decision gate: reality matches the ticket's assumptions? Any §4 case fires?
No → STOP, back to requester. This gate is where seniors earn their title.

**Apply [E]:** via the platform (GUI/import) so L1 stays truthful — never
"quick fix on the server directly" on managed estates (the platform will
either overwrite it or diverge). Record exact timestamp.

**Post-check (evidence file 2):**
```
dig @EVERY auth serving the zone <name> — new value, aa, serial advanced
dig @resolver(s) — either new value or old-with-draining-TTL (state which + ETA)
dig -x — reverse consistent (if in scope)
GUI: object state + audit trail entry
```
**Close:** ticket updated with both evidence files + convergence ETA.

**[L]:** Days 70–71 execute this against lab, producing the artifacts.
**[V]:** Does our change process mandate evidence attachments? Where are
they filed?

## §8 — Bulk CSV operations

**[U] The CSV standard you'll defend (Day 72 baseline, adapt to local
convention):**
```
action,fqdn,type,value,ttl,ticket,owner
add,app9.corp.example.,A,10.10.20.90,300,CHG0012345,payments-team
delete,old1.corp.example.,A,10.10.20.51,,CHG0012345,payments-team
```
Rules — syntactic: FQDN format + trailing-dot convention decided and
uniform; valid types; IP syntactically valid AND in expected ranges (a fat-
fingered 10.100. vs 10.10. passes regex, fails range policy); TTL sane;
no duplicate rows; no conflicting rows (add+delete same name in one file).
Semantic (the real work): per-row §4 taxonomy against deployed reality;
for deletes — value in CSV must MATCH the deployed value exactly (name+type+
value, not name-only: name-only deletion of a round-robin member is how you
take down the wrong half of a service); dependency sweep (anything CNAME'd
to a deleted name? MX/SRV targets?); PTR plan per row; query-log liveness
for deletes.

**[E]** Platform import specifics to verify locally: column-mapping step
(mis-mapped columns = valid-looking garbage applied), behavior on row error
(abort-all vs skip-and-continue — you MUST know which before executing 400
rows), dry-run/preview availability, and export function (your rollback
artifact generator: full export of affected zone(s) BEFORE the change).

**Batching doctrine [U]:** never one 400-row shot. Batch (e.g., 50), post-
check the batch, proceed. First batch is the canary: any surprise → halt
with 350 rows unharmed.

**[L]:** Days 72–74: manual validation of a planted-error CSV, then clean
bulk execution with rollback file, then the poisoned-CSV gauntlet.
**[V]:** Our import's on-error behavior? Preview mode? Export format that
round-trips as a valid import (the ideal rollback artifact)?

## §9 — Real-environment validation questionnaire (read-only)

Answer these against corporate SOLIDserver — read-only navigation and dig
only, no changes. Each answer goes in your journal with WHERE you found it.
1. Estate map: EIP appliances, managed DNS servers, which zones live where,
   which smart architecture(s).
2. Views in EIP or separate estates for internal/external?
3. Record-creation doctrine: IPAM-first or DNS-first? Auto-PTR on?
4. All reverse zones under management? List gaps.
5. Exact "already exists" wording for §4 cases 1–3 (find historical
   tickets/screenshots rather than provoking errors).
6. My rights, precisely. The approval workflow, precisely.
7. Deployment/sync status location; what a failed push looks like.
8. Import: column mapping UI, on-error behavior, preview, export format.
9. Audit trail: location, retention, searchability.
10. TTL and SOA-minimum conventions in our zones (dig them and record).
11. Serial spread across our secondaries right now (dig SOA @each — a free
    health check that impresses exactly the right people).
12. Which zones are DNSSEC-signed, if any; where keys/policy live.

## §10 — Platform comparisons (for the oral exam and design talk)

**EIP vs raw BIND [U]:** BIND gives you the protocol truth and total
control, zero guardrails: no object model, no rights granularity, no linked
IPAM, no audit beyond logs — discipline must be human. EIP industrializes
the discipline: objects, rights, workflows, deployment, consistency
automation — at the cost of a layer that can itself desync (L1/L2) and of
"the platform's way" constraining edge cases. Senior line: "EIP manages
intent; BIND serves answers; my job is proving they agree."

**EIP vs Infoblox (where useful) [U/E]:** same species — DDI with
appliances, object DB, GUI/API/CSV, and vendor-flavored HA/distribution:
Infoblox's **Grid** (Grid Master + members, one config domain) roughly
corresponds to EIP's management cluster + smart architectures; Infoblox
**extensible attributes** ≈ EIP **class parameters**; both wrap a DNS engine
(Infoblox: BIND-derived) under management; both suffer the same three-layer
truth problem, the same IPAM/DNS drift modes, the same import-mapping
hazards. Interview-ready summary: "Concepts transfer 1:1 — objects, linkage,
deployment, audit; only nouns and menus change. I verify the [V]-class
specifics on whichever platform I'm dropped into."

**Microsoft DNS in the mix [U]:** AD-integrated zones replicate via AD
itself (not zone transfer), take GSS-TSIG dynamic updates, and are commonly
*conditionally forwarded to* rather than absorbed by the DDI platform — the
coexistence pattern from TM 3.6.

---

## §11 — Quiz bank (numbering matches the Daily Calendar)

**Q1–6 (Days 63 — model & layers):**
1. Name the three layers of truth in a DDI-managed estate and one way each
   can be wrong.
2. What does a "smart architecture" abstract away?
3. Why do hand edits on a managed DNS server end badly? Two failure shapes.
4. GUI shows the record; dig at the auth server doesn't. Which layer pair
   diverged and what class of cause?
5. What engine typically answers queries under EIP-native DNS servers, and
   why does that matter for your skills?
6. Where does the resolver cache sit in the three-layer model?

**Q7–11 (Day 64 — IPAM↔DNS):**
7. What creates the A+PTR pair atomically, and what silently prevents the
   PTR half?
8. Two ways forward/reverse drift is born in an IPAM shop.
9. Why does a DNS-side-only record threaten future IPAM allocations?
10. Your lab CSV sheet role-plays which component?
11. An IP is freed in IPAM but a CNAME elsewhere still points at its old
    name — which §3 drift class, and who should have caught it?

**Q12–16 (Day 66 — rights/approval; §5):**
12. List six of the ten pre-approval verifications from memory.
13. Why is "pre-check against the GUI" insufficient?
14. Where can approval live, and why must you know which applies here?
15. What are class parameters for, operationally?
16. A requester asks to "also fix two other records while you're in there."
    Correct response and why?

**Q17–21 (Day 70 — single-change ceremony; §7):**
17. What belongs in pre-check evidence for deleting an A record? (≥5 items)
18. Why apply via the platform even when SSH to the server is faster?
19. Post-check must query WHICH servers, and what three things prove
    success at L2?
20. What do you tell the requester at close time about visibility?
21. Which single pre-check step most often stops a bad change, in your
    judgment — defend it.

**Q22–26 (Day 72 — bulk; §8):**
22. Why must delete rows match name+type+VALUE?
23. The one platform behavior you must know before importing 400 rows?
24. What is the ideal rollback artifact for a bulk delete and when is it
    generated?
25. Defend batching to an impatient requester in two sentences.
26. Name three semantic (not syntactic) CSV validations.

**Key (terse):** 1. Object DB / deployed zone data / caches; stale object
(failed edit), failed push or hand-edit divergence, TTL physics. 2. Multi-
server primary/secondary wiring (roles, notify, transfers) behind one
logical zone. 3. Platform overwrite reverts them; or divergence where L1 no
longer predicts L2 — future pushes surprise everyone. 4. L1 vs L2;
deployment/sync class (staged, push failed, unreachable, divergence).
5. BIND — your Chapter 4 skills apply directly underneath. 6. L3.
7. IPAM address-object operations (with auto-PTR); missing/unmanaged reverse
zone. 8. DNS-side-only creates; deletes that touch one side; unmanaged
reverse; imports without IPAM backfill (any two). 9. No address object →
allocator sees the IP as free → collision. 10. The IPAM database (intent
layer). 11. Class 4; dependency sweep at decommission time. 12. Any six of
§5's ten. 13. GUI is L1 intent — the ticket's assumptions must be checked
against L2 deployed reality (and caches for user-visible claims).
14. Inside the platform or only in the ticket system; because "approved" must
mean the same thing to you and the auditor. 15. Ownership/context metadata —
audit, cleanup, blast-radius answers. 16. Refuse — scope is defined by the
approved ticket; new work = new ticket (audit integrity + rollback clarity).
17. Deployed value match, per-type collision sweep, reverse state, CNAME/MX/
SRV dependency sweep, query-log liveness, IPAM object state, ticket match.
18. L1 truthfulness: platform remains the source of intent; direct edits
diverge or get overwritten. 19. Every authoritative server for the zone
(all secondaries); aa flag, new value, advanced serial. 20. Convergence ETA:
resolver/client caches clear within old TTL (or negative TTL for creates);
what "fixed" means per audience. 21. Defensible choice; strongest candidates:
value-match on deletes, or dependency sweep — argue impact. 22. Name-only
deletion can remove round-robin members or a different record than intended —
value match pins the exact object. 23. On-error behavior: abort-all vs
skip-and-continue. 24. A full export of affected zones/records taken
immediately BEFORE execution, in import-compatible format. 25. First batch is
a canary: an error costs 50 rows to unwind, not 400; total time difference is
minutes against hours of incident. 26. Deployed-value match, collision
taxonomy per row, dependency sweep, liveness check, PTR plan, range policy
on IPs (any three).
