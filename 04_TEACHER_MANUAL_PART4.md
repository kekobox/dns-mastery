# SECTION 5 — TEACHER MANUAL, PART 4 (Levels 6–7 + DNSSEC)
### Packet 7b — Troubleshooting methodology, change management, DNSSEC
Quiz numbering matches the Daily Calendar (TM 6 Q1–5, TM 7 Q1–5, TM 8 Q1–11).

---

# CHAPTER 6 — TROUBLESHOOTING & INCIDENT RESPONSE

## TM 6.1 — The universal isolation method, formalized

**Explanation.** Every DNS incident is one of four symptom classes; each has
a canonical opening move. Your Day 77 decision tree formalizes:

**WRONG ANSWER** → provenance ladder (CMD §11): client cache → each
resolver node directly → each authoritative → parent delegation. The
deepest layer serving the wrong data owns it. Then: is "wrong" actually
stale (TTL physics), a different-universe answer (views/split), rewritten
(RPZ), or truly wrong at source (data/deploy problem)?

**NO ANSWER (rcode)** → classify the rcode FIRST: NXDOMAIN (name absence —
real? negative-cached? wrong suffix expansion? wrong universe?), NODATA
(type absence — wildcard shadowing? AAAA-vs-A?), SERVFAIL (upstream/zone/
DNSSEC — bisect per hop, +cd early), REFUSED (policy — ACL/view/role; read
it at the hop that emitted it, remembering chains launder it into
SERVFAIL).

**NO ANSWER (timeout)** → transport, not DNS logic: capture at the server
("did anything arrive?" — the strongest bisect in networking), UDP vs TCP
separately, size-dependence (EDNS matrix), then path/firewall.

**SLOW/INTERMITTENT** → hunt the timeout quantum (fixed +N s = a corpse in
a list: dead forwarder/NS/lame member); per-node and per-instance
interrogation (VIP/anycast hide divergence); size/time correlation;
health-flap inputs (GSLB).

**Senior version.** "I classify before I touch: symptom class → canonical
opening → evidence at each hop → the owning layer named with proof. I
never flush, restart, or retransfer before the owning layer is identified —
surgery destroys evidence."

**Quiz TM 6 Q1–5:**
1. Why does REFUSED rarely reach the end client in a forwarding chain?
2. Give the opening move for each of the four symptom classes.
3. What single capture most cheaply splits "DNS problem" from "network
   problem"?
4. Wrong answer at the resolver, correct at auth — three distinct
   mechanisms it could be.
5. Why does "found a fault" not end a senior investigation?

**Key:** 1. Each hop treats upstream REFUSED as resolution failure and
emits SERVFAIL downstream. 2. Wrong→provenance ladder; rcode→classify
rcode then bisect per hop; timeout→capture at server + transport matrix;
slow→find the quantum, interrogate per node/instance. 3. tcpdump port 53
at the server while the client reproduces — arrival vs silence.
4. Stale RRset (TTL), negative cache, RPZ rewrite (also: wrong view
selected for that client, or one stale node behind a VIP). 5. Composites
exist (T49); the ladder runs to completion and each fault needs
independent evidence.

## TM 6.2 — Packet-level DNS: tcpdump/Wireshark

**Explanation.** The five fields you read first in any DNS capture: (1)
direction+addresses (who asked whom — is it even the server you think),
(2) the QNAME/QTYPE actually on the wire (suffix expansion surprises die
here), (3) rcode+flags of the response, (4) transaction ID matching
query↔response (unmatched responses/dup IDs = interesting), (5) sizes and
TC (transport story). Then timing (gap query→response; retransmission
patterns). Capture recipes: `tcpdump -ni any port 53 -c 100` (live triage),
`-w file.pcap` for Wireshark (filters: `dns`, `dns.flags.rcode != 0`,
`dns.qry.name contains "corp"`, `tcp.port == 53`). Transfers: follow the
TCP stream — SOA…records…SOA framing for AXFR, delta framing for IXFR.
Your pcap library (Day 78) is the reference deck: healthy resolution,
TC+TCP retry, XFR, SERVFAIL exchange, NOTIFY — diffing a live capture
against a known-good one is faster than remembering what good looks like.

**Trap.** Capturing on the wrong interface/nat side and concluding
"no traffic"; always prove the capture point sees SOMETHING first.

## TM 6.3 — Proving a negative: "DNS is fine"

**Explanation.** Exoneration is a deliverable with a standard: (1) the
question as the app experiences it — getent/Resolve-DnsName on the
affected host, not dig from your laptop; (2) correct answer shown at
client-path, resolver, and authority with flags/TTLs; (3) the actual
fault located and named (hosts file line, pinned IP in config, app cache
setting, connection pool) — "not DNS" lands only when paired with "it is
X, here"; (4) timestamped, filed in the ticket. The tone rule: evidence
without adjectives. App teams argue with opinions, not with a getent
output next to their own config line.

## TM 6.4 — Incident communication

**Explanation.** Three artifacts, each with a job:
**Initial ack (≤10 min):** what's confirmed impacted (scope), what's being
done now, next update time. No speculation on cause.
**Mid-incident update:** cause status (confirmed/leading hypothesis +
evidence level), actions, ETA or "ETA at next update"; user-visible
workaround if honest.
**Resolution note:** what happened (one paragraph, mechanism-true), when
fixed AT SOURCE, **the convergence caveat** — after DNS changes/deletes,
"resolved" always ships with the TTL/negative-TTL tail ("stragglers until
HH:MM") — plus follow-ups owned. The TTL-honesty habit is the most senior
sentence in the whole discipline: never promise instant global visibility.

---

# CHAPTER 7 — CHANGE MANAGEMENT (manual discipline)

## TM 7.1 — The enterprise change lifecycle

**Explanation.** Request → **validation** (07 §5's ten checks — where the
engineering happens) → approval/CAB (risk story understandable by
non-DNS people: what, blast radius, window, rollback, comms) → window
execution (ceremony, batches, evidence) → verification → closure (evidence
attached) or rollback (pre-built artifact). What the CAB actually needs
(your Day 91 ticket must contain): plain-language intent, affected
names/zones/consumers, risk class + why, precise steps, pre/post-check
commands with expected outputs, rollback trigger criteria ("we roll back
if X by T+15"), comms plan, convergence bound stated as clock time.

## TM 7.2 — Risk classification by record type

**Explanation.** Risk = blast radius × reversibility-lag × dependency
fan-out. The matrix logic (build yours Day 92):
- **NS/delegation/glue:** highest — misdirects an entire namespace;
  convergence governed by NS TTLs (often long); errors strand resolvers.
- **SOA timer changes:** high-sneaky — alters replication/negative physics
  estate-wide with zero visible "record" change.
- **MX/SPF-TXT:** high — mail is instant-visible, external, reputational.
- **Wildcard add/remove/change:** high — semantic change for infinite
  names; shadowing side-effects.
- **CNAME target changes:** medium-high — fan-out via everything pointing
  at the alias.
- **A/AAAA change:** medium — bounded by consumers of one name.
- **Delete (any type):** one class above the corresponding add — negative
  caching + you must prove non-use.
- **PTR:** low direct, medium reputational (mail/security attribution).
- **Adds to virgin names:** lowest.

**Quiz TM 7 Q1–5:**
1. Why do NS changes outrank a hundred A additions?
2. What makes SOA edits "high-sneaky"?
3. Why is every delete one class above its add?
4. Which single number governs a delegation change's convergence?
5. Compose the CAB one-liner for changing a wildcard's target.

**Key:** 1. Namespace-wide misdirection potential, long NS TTL
convergence, resolver stranding — blast radius is the whole subtree.
2. No visible record diff, estate-wide behavioral change (replication
timers, negative TTL). 3. Negative caching penalty + burden of proving
non-use + dangling-reference risk. 4. The NS RRset (and glue) TTL.
5. "Every currently-nonexistent name under X changes destination at once;
existing exact names are unaffected; blast radius unknown-by-design,
hence window + instant rollback line."

## TM 7.3 — TTL choreography for planned changes

**Explanation.** The timeline math (Day 93 executes it): let old TTL = T.
**t−(T+margin):** lower TTL to t_small (this edit itself takes T to be
universally held — the step everyone schedules too late). **t0:** change
value. **t0+t_small:** world converged; verify. **t0+t_small+soak:**
restore TTL to T. Deletes: same, plus SOA-minimum awareness for the
negative tail. Migration variant: pointers (NS/glue) get their OWN ramp —
T26's lesson. Rule of thumb: any change wanting sub-5-minute convergence
is a ramp-down plan initiated at least one old-TTL early, or it's a flush
plan across resolvers you own — and flushing the internet is not a plan.

## TM 7.4 — Rollback engineering

**Explanation.** Rollback ≠ undo-button. Principles: (1) the artifact is
captured BEFORE apply, in re-applicable form (import-compatible export /
exact record lines / zone snapshot + serial note); (2) rollback has its
own pre/post-checks (it's a change); (3) design for the HALF-APPLIED case
— batch-boundary bookkeeping makes "roll back batches 3–4, keep 1–2"
possible; state-comparison (current vs pre-export diff) is the recovery
compass (T32); (4) rollback triggers are pre-agreed and objective ("post-
check X fails at T+15") — deciding criteria during the incident is how
hybrids are born; (5) cache reality: rolling back re-raises the
convergence question; negative caches from the broken interval may need
targeted flushes. Your Day 94 drill proves state-equality after rollback
(diff of exports), not vibes.

---

# CHAPTER 8 (part 1) — DNSSEC & SECURITY DESIGN

## TM 8.1 — DNSSEC theory: the chain of trust

**Explanation.** DNSSEC adds *authenticity and integrity* (never
confidentiality) to DNS data via offline signatures:
- **DNSKEY** (at the child): the zone's public keys. Convention: **KSK**
  (flag 257) signs the DNSKEY RRset only; **ZSK** (flag 256) signs
  everything else. Split exists so the frequently-used key (ZSK) can roll
  without parent interaction.
- **RRSIG:** a signature per RRset, with inception/expiration timestamps —
  signatures are perishable (T31).
- **DS** (at the PARENT): a digest of the child's KSK — the cross-zone
  link. The chain: trust anchor (root key, or a configured anchor) → root
  signs TLD's DS → TLD's DS matches TLD DNSKEY → … → your zone's DNSKEY →
  RRSIGs over your data.
- **NSEC/NSEC3:** authenticated denial — signed proof that a name/type
  does NOT exist (NSEC links existing names in order, enabling zone-walk
  enumeration; NSEC3 hashes names to resist casual walking; NSEC3
  opt-out exists for huge delegation-heavy zones). Negative answers get
  signatures too — that's why signed zones' NXDOMAINs are big.
Validation outcomes: **secure** (chain verifies, AD set), **insecure**
(a parent proved, via signed absence of DS, that the child is unsigned —
legitimate, no AD), **bogus** (chain SHOULD verify but fails → SERVFAIL
to protect the client). The bogus/insecure distinction is the exam
favorite: unsigned ≠ broken; broken = signed-but-invalid.

**Quiz TM 8 Q1–6:**
1. Which key does DS digest, and where does DS live?
2. Why does the KSK/ZSK split exist?
3. Secure vs insecure vs bogus — define and give the resolver behavior.
4. Why are signed zones' negative answers large?
5. What can DNSSEC never provide, despite the name?
6. AD flag vs aa flag — who sets each and what does each claim?

**Key:** 1. The KSK; in the parent zone. 2. ZSK rolls locally/frequently
without parent DS updates; KSK is the stable parent-linked key.
3. Secure: validated, served with AD. Insecure: provably unsigned
(signed DS-absence at parent), served without AD. Bogus: validation
fails on a signed chain → SERVFAIL. 4. NSEC/NSEC3 + RRSIGs must
accompany the denial to make "no" provable. 5. Confidentiality —
payloads are cleartext (that's DoT/DoH territory). 6. AD: validating
RESOLVER asserts chain-verified. aa: AUTHORITATIVE server asserts
zone-data origin. Different actors, different claims, often mutually
exclusive in one response.

## TM 8.2 — Signing operations (KASP era)

**Explanation.** Modern BIND: `dnssec-policy` (KASP) automates key
generation, signing, re-signing, and timed rollovers — the operator's job
shifts to policy definition + the parent-DS step + monitoring. What
changes when a zone signs: DNSKEY/RRSIG/NSEC* appear, answers grow (EDNS/
TCP posture matters — Chapter 3 pays rent here), serials churn with
re-signing, and the zone acquires *expiry-class liveness requirements*
(signing must keep running). The two eternal manual duties: getting DS
into the parent (registrar/TLD/EIP-parent workflow — CDS/CDNSKEY can
automate where supported), and watching signature validity margins like
cert expiry.

## TM 8.3 — Breaking and diagnosing DNSSEC

**Explanation.** The triage you drilled (C8/LAB 14b), as doctrine:
1. `dig name @resolver` → SERVFAIL.
2. `dig name @resolver +cd` → answers? → validation-class confirmed
   (data retrievable, chain rejected). Still failing? → not (only) DNSSEC.
3. `delv name @resolver` → verdict + failing link ("expired", "no valid
   RRSIG", "broken trust chain / no matching DS").
4. Localize the link: `dig DS child @parent` vs `dig DNSKEY child
   +dnssec` (DS↔KSK match?); RRSIG timestamps (`dig +dnssec +multiline`,
   read inception/expiration vs clock); check YOUR side (resolver clock,
   trust anchors, a forwarder stripping DO/OPT — T48).
5. Attribution: fails on every validator (8.8.8.8/1.1.1.1 too) → domain's
   fault; only yours → your resolver/path.
Failure catalogue: expired RRSIG (T31), DS↔DNSKEY mismatch post-rollover
(T30), clock skew (validator or signer), middlebox stripping (T48), stale
trust anchor, forwarder that doesn't pass DNSSEC material.
**NTA (negative trust anchor):** per-domain validation bypass — emergency
scalpel: documented, approved, time-boxed, with removal date. Never a
setting that lives forever.

## TM 8.4 — Rollovers

**Explanation.** **ZSK roll (pre-publish):** new ZSK published in DNSKEY →
wait (DNSKEY TTL — caches must hold both) → sign with new → wait (max
RRSIG TTL — old signatures age out of caches) → remove old. Local, safe,
automatable — KASP does it.
**KSK roll (the scary one):** publish new KSK (sign DNSKEY RRset with
both) → submit new DS to PARENT → **wait: parent DS TTL + parent
publication lag** (the step you don't control — T30's grave) → remove old
DS → wait again → retire old KSK. The invariant at every instant: every
cached validation path must complete — some resolver may hold old DS +
new DNSKEY or vice versa; both combinations must verify during the
overlap.
**Algorithm rollover:** strictest variant — publish signatures with both
algorithms before any DS switch (validators expect complete RRSIG sets
per signaled algorithm). Know it exists and that it's the one to
over-plan.

**Quiz TM 8 Q7–11:**
7. Which TTLs gate a ZSK roll's two waits?
8. Why is the KSK roll a parent-coordination problem?
9. State the rollover invariant in one sentence.
10. What are CDS/CDNSKEY for?
11. Post-roll, validators SERVFAIL; DS at parent digests a key absent
    from DNSKEY. Name the error and both directions of fix.

**Key:** 7. DNSKEY RRset TTL (both keys visible), then max RRSIG TTL
(old sigs drained). 8. The DS lives in the parent; its update timing and
TTL are outside your control and gate every step. 9. At every moment,
every combination of cached DS/DNSKEY/RRSIG a resolver may hold must
still validate. 10. Child-published records signaling the parent to
update DS automatically (where the parent supports scanning them).
11. T30: premature old-KSK removal (or wrong DS submitted); fix by
re-publishing the old KSK, or expediting correct DS and waiting out its
TTL.

## TM 8.5 — Transfers & updates security review (design level)

**Explanation.** The estate audit checklist (Day 102):
every transfer path: TSIG-keyed (unique key per relationship), ACL as
belt-and-braces, unauthenticated `dig AXFR` fails from an arbitrary host
(test it — the one-command audit); every dynamic-update path:
keyed + `update-policy` least-privilege (which key → which names/types);
NOTIFY hygiene (role-directional — T29); rndc keys unique per host,
loopback-bound controls; role separation enforced (no recursion on
authoritative edges, RRL on external); logging: security/xfer categories
retained and shipped; time: NTP monitored as a DNS dependency (TSIG,
RRSIG validity). The ten-bullet security baseline you write Day 102 is
this section compressed into your own words — and it's an oral-exam
answer verbatim.

---
**End of Part 4.** Part 5 (architecture, HA, Anycast, GSLB, monitoring,
migration, DR, platform mapping — TM 8.6–8.11) is Packet 7c.
