# SECTION 5 — TEACHER MANUAL, PART 3 (Level 4)
### Packet 4a — BIND Operations Deep Dive
Quiz numbering matches the Daily Calendar (TM 4 Q1–26).

---

# CHAPTER 4 — BIND OPERATIONS

## TM 4.1 — named.conf anatomy

**Explanation.** named.conf is a set of statements; the ones that matter
operationally:
- **options { }** — global defaults: `directory` (working dir — where dumps,
  journals, managed keys land), `recursion`, `allow-query`,
  `allow-recursion`, `allow-transfer`, `listen-on`, `forwarders`/`forward`,
  `dnssec-validation`, `minimal-responses`, `version "none";`.
- **acl name { };** — named address lists. Define once, reference
  everywhere; an unnamed sprawl of CIDRs across zone blocks is how leaks are
  born.
- **zone "name" { };** — `type primary|secondary|forward|stub|static-stub|
  hint`; `file`; per-zone overrides of the ACLs; `primaries {}` for
  secondaries; `also-notify`; `allow-update`.
- **view "name" { match-clients {}; };** — parallel universes (TM 3.9). Once
  ONE view exists, ALL zones must live inside views.
- **key "name" { algorithm; secret; };** — TSIG material; referenced by
  `allow-transfer { key x; }` and `primaries { ip key x; }`.
- **logging { channel …; category …; };** — where each category
  (queries, xfer-in, xfer-out, security, dnssec, notify, general, lame-servers)
  goes: file, severity, versions/size rotation.
- **controls { };** — rndc access (port 953, key-authenticated, loopback by
  default).

**Evaluation logic that bites:** most-specific wins (zone overrides options);
ACLs match on **source address**; first-match in views; a zone statement can
exist but the FILE can fail to load — the zone then exists in config but not
in service (logs say so; `rndc zonestatus` says so; people check neither).

**Senior version.** "I read an unfamiliar named.conf in this order: options
ACL posture (who may query/recurse/transfer), views (how many universes),
zone inventory per view, keys, logging destinations. That's the security and
blast-radius model of the server in five minutes."

**Ops checklist:** every edit → `named-checkconf` → reload → check logs for
the zone actually loading. **Troubleshooting:** REFUSED → ACL/view;
zone-not-found from a server that "has" it → file failed to load or wrong
view.

**Quiz TM 4 Q1–6:**
1. Which statement wins when options and a zone block both set allow-query?
2. What happens to zones outside any view once one view is defined?
3. Where do journals and cache dumps physically land?
4. named-checkconf passes but the zone doesn't answer — two next checks.
5. What does `controls` govern and on which port?
6. Why define ACLs by name instead of inline CIDRs? (2 reasons)

**Key:** 1. The zone block (most specific). 2. Config error — BIND refuses
to load; every zone must move into a view. 3. The `directory` path (working
directory), unless per-file paths are absolute. 4. `rndc zonestatus zone`
(loaded? serial?) and the load-time log lines (checkzone errors at load);
also confirm you're querying the right view. 5. rndc's control channel; TCP
953. 6. Single point of change (no drift between zones), self-documenting
security posture; fewer copy-paste leak bugs.

## TM 4.2 — Primary/secondary, NOTIFY, serial discipline

**Explanation.** The lifecycle of a change on a classic primary:
edit file → serial++ → `rndc reload zone` → primary loads → primary sends
**NOTIFY** to every NS-listed server (+ `also-notify` extras) → each
secondary compares SOA serial (a lightweight SOA query) → higher serial →
secondary requests transfer (IXFR if possible, else AXFR) → secondary serves
new data. NOTIFY is an *accelerator hint* only — with NOTIFY lost, the
secondary still converges at REFRESH. **Serial arithmetic (RFC 1982):**
"newer" is defined in a 32-bit circular space; a serial that appears LOWER is
treated as older → secondary never updates. Recovery from a serial that went
backwards: (a) per-secondary `rndc retransfer zone` (forces AXFR regardless
of serial), or (b) protocol-correct at scale: set serial = old + 2^31
(wraps "ahead"), let all secondaries transfer, then set the desired value and
transfer again.

**Hidden primary pattern (preview of 8.6):** the primary is NOT in the NS
set; only secondaries are public. NOTIFY then needs `also-notify` explicitly
(no NS records to derive targets from) and `notify explicit;`.

**Traps.** Editing without serial++ = the silent killer: primary answers new,
secondaries answer old, and which one a resolver asks is luck → "intermittent
wrong answer" tickets. Different serials across secondaries is your
monitoring's job to catch (serial spread check).

*(Assessment: LAB 10 breaks; quizzed within Q7–11.)*

## TM 4.3 — AXFR, IXFR, journals

**Explanation.** **AXFR:** full zone over TCP, one stream, bounded by
SOA-to-SOA framing. **IXFR:** the secondary presents its current serial; the
primary answers with the delta chain from that serial to now — IF it has the
history. History lives in the **journal** (`.jnl`): automatic for dynamic and
inline-signed zones; for static-file primaries only with
`ixfr-from-differences yes;`. No usable history (journal trimmed/deleted,
serial unknown, primary rebuilt) → primary legitimately answers the IXFR
request **with a full AXFR** — clients of the protocol must accept that.
Transfers honor `allow-transfer` ACL/TSIG; `dig @primary zone AXFR` is your
manual test (and your audit tool: if that works unauthenticated from a random
box, that's a finding).

**Reading the logs:** secondary: `zone corp.example/IN: Transfer started`,
`transferred serial 2026070812`; primary: `client 172.20.0.11#x: transfer of
'corp.example/IN': IXFR started/ended`. REFUSED vs BADSIG vs timeout in these
lines is the C4 triage.

**Quiz TM 4 Q7–11:**
7. Who initiates a zone transfer, and what are the two things that prompt it?
8. Three conditions that force IXFR to fall back to AXFR.
9. Why are transfers TCP-only?
10. What does `rndc retransfer` do differently from `rndc refresh`?
11. Unauthenticated `dig AXFR` succeeds from your laptop against a prod
    primary. Why is that a security finding? (2 reasons)

**Key:** 7. The secondary; prompted by NOTIFY receipt or its REFRESH timer
(RETRY after failures). 8. No journal/insufficient history for the
presented serial; primary doesn't support/track IXFR for that zone;
secondary has no zone yet (first transfer). 9. Arbitrarily large, must be
complete and ordered — datagram semantics don't fit. 10. retransfer forces
an immediate full AXFR ignoring serial comparison; refresh performs the
normal SOA-check-then-maybe-transfer. 11. Full zone = infrastructure map
handed to attackers (recon); also indicates allow-transfer ACL absent —
the same laxity often extends to updates/other controls.

## TM 4.4 — TSIG

**Explanation.** TSIG = transaction signatures with a **shared secret**
(HMAC, e.g. hmac-sha256): each message carries an HMAC over the message +
timestamp; both sides must hold the same key **name and secret**, and clocks
must agree within the fudge (±300 s default). Protects transfers, NOTIFY,
updates, rndc (rndc's key is the same mechanism). What TSIG is NOT:
encryption (payload is cleartext) and not DNSSEC (no public-key chain, no
third-party verifiability — purely pairwise).

**Failure signatures you must recognize in logs:**
- `tsig verify failure (BADSIG)` — secret mismatch (or key name maps to a
  different secret on one side).
- `clocks are unsynchronized` / BADTIME — skew beyond fudge (containers on
  one host rarely hit this; VMs after snapshot restores, appliances with
  dead NTP hit it constantly — real-world classic).
- Plain `REFUSED` with no TSIG log — the request wasn't signed at all and
  the ACL requires a key (`allow-transfer { key x; }` rejects unsigned).
- BADKEY — key name unknown to the receiver.

**Senior version.** "Key hygiene: unique key per relationship (not one
global key), distribution out-of-band, rotation documented, and NTP treated
as a DNS dependency — because with TSIG, time IS authentication."

*(Assessment: LAB 11 captures; quizzed within Q12–16.)*

## TM 4.5 — rndc mastery + secondary expiry

**Explanation.** rndc verbs that carry your on-call life:
- `status` — up, zone counts, recursion clients.
- `reload [zone]` — re-read config/zone; `reconfig` — config + NEW zones
  only (faster, doesn't touch existing zone data).
- `zonestatus zone` — loaded? serial? type? next refresh/expiry — THE
  secondary-health command.
- `retransfer zone` / `refresh zone` — force/prompt transfers.
- `flush` / `flushname` / `flushtree` — cache surgery.
- `freeze zone` / `thaw zone` — suspend dynamic updates to hand-edit safely.
- `querylog [on|off]` — toggle query logging live.
- `dumpdb -cache` — cache to disk for inspection.
- `notify zone` — re-send NOTIFYs.
- `rndc-confgen` — generate the control key material.

**Secondary expiry mechanics:** a secondary that cannot refresh (primary
dead, ACL broken, TSIG broken) counts toward SOA EXPIRE from its **last
successful refresh**. Until expiry: serves stale-but-working data
(and answers with AA! — expired-not-yet zones are a stealth risk). At
expiry: zone goes into "expired" state → **SERVFAIL** for every query.
The ops meaning: transfer breakage is a countdown bomb, not a cosmetic
warning — monitoring must alarm on refresh failures long before expiry.

**Quiz TM 4 Q12–16:**
12. reload vs reconfig — difference and when each.
13. Which single rndc command tells you a secondary's serial AND time to
    expiry?
14. A secondary has served a zone for 6 days since the primary died
    (expire=7d). What do clients see today and in ~24h?
15. Why must you freeze before hand-editing a dynamic zone?
16. TSIG BADTIME in transfer logs on an appliance — what non-DNS system do
    you check first?

**Key:** 12. reload re-reads config and reloads zone data; reconfig applies
config changes and loads new zones without reloading existing zone data —
use for adding zones on busy servers. 13. `rndc zonestatus <zone>`.
14. Today: normal (stale) answers with AA; in ~24h: SERVFAIL as expire hits
— per-secondary timing based on each one's last refresh. 15. Dynamic zones
are journal-backed; the on-disk file is not the live truth — editing it
desynchronizes file vs journal; freeze flushes the journal to the file and
suspends updates, thaw resumes. 16. NTP/time sync.

## TM 4.6 — Dynamic updates

**Explanation.** RFC 2136 UPDATE: a DNS message (opcode UPDATE) with
prerequisites ("only if name exists / doesn't exist / RRset matches") and
update operations (add/delete RRs), authorized by `allow-update` — which in
any sane deployment means **TSIG-keyed** (or `update-policy` for granular
per-name/per-type rules — the right tool for "this key may update only
these names"). BIND applies updates to the **journal** immediately, bumps
the serial automatically, and lazily syncs the zone file. `nsupdate` is the
client: scriptable, prerequisite-capable, the mechanism under most "DNS
API"-ish gluecode and under DHCP-server DNS registration.

**AD context (concept level):** Windows clients and DHCP servers perform
dynamic updates against AD-integrated zones with **GSS-TSIG** (Kerberos-
negotiated TSIG — "secure dynamic updates"). Consequences you must be able
to state: AD zones are never hand-edited; records carry timestamps;
**scavenging** (aging + periodic deletion of stale dynamic records) is the
cleanup mechanism — and mis-tuned scavenging deleting live records is a
famous incident class.

**Prerequisites as an ops tool:** "add A only if no CNAME exists at the
name" — encoded in the update itself:
```
prereq nxrrset app9.corp.example. CNAME
update add app9.corp.example. 300 A 10.10.20.90
send
```
This is atomic pre-checking — a concept you'll reuse in EIP thinking.

**Quiz TM 4 Q17–21:**
17. Who increments the serial for a dynamic update?
18. Why does the on-disk zone file lag the served data on dynamic zones?
19. update-policy vs allow-update — what does the former add?
20. What is GSS-TSIG in one sentence, and where do you meet it?
21. Write (conceptually) the prerequisite that makes "create app9 A" fail
    if ANY records already exist at the name.

**Key:** 17. named itself, automatically per update transaction. 18. Updates
land in the journal first; the file is rewritten lazily (or at freeze/
shutdown). 19. Granularity: which key may touch which names/types (e.g.,
self-updates only), vs allow-update's all-or-nothing zone grant.
20. TSIG with keys negotiated via Kerberos instead of static secrets — AD
secure dynamic updates. 21. `prereq nxdomain app9.corp.example.` (name must
not exist at all) before the add.

## TM 4.7 — Logging & query-log analysis

**Explanation.** Logging is category → channel plumbing. A production-shaped
config:
```
logging {
  channel query_log { file "/var/log/named/query.log" versions 5 size 50m;
                      severity info; print-time yes; };
  channel ops_log   { file "/var/log/named/named.log" versions 5 size 50m;
                      severity info; print-time yes; print-category yes; };
  category queries    { query_log; };
  category xfer-in    { ops_log; };  category xfer-out { ops_log; };
  category notify     { ops_log; };  category security { ops_log; };
  category dnssec     { ops_log; };  category lame-servers { null; };
  category default    { ops_log; };
};
```
Query log line anatomy:
`client @0x... 172.20.0.53#41234 (app1.corp.example): query: app1.corp.example IN A +E(0)K (172.20.0.10)`
— source, qname, type, flags (`+`=RD, `E`=EDNS, `T`=TCP, `D`=DO, `S`=TSIG).

**The blast-radius technique (Day 57's point):** before deleting records,
grep N days of query logs for the names. Hits → the name is ALIVE; find the
clients (source IPs) and warn/investigate before deletion. No hits over a
representative window → deletion risk drops enormously. This one habit
prevents more incidents than any tooling.

**Cost awareness:** query logging is IO-heavy at scale — know how to toggle
live (`rndc querylog`) and rotate (versions/size).

*(Assessment: Day 57 mini analysis report.)*

## TM 4.8 — RPZ: DNS firewalling & sinkholing

**Explanation.** Response Policy Zones: the resolver consults a local
policy zone before answering and can rewrite responses. Triggers: QNAME
(the name asked), IP (answer contains address in range), NSDNAME/NSIP
(delegation via listed nameservers), CLIENT-IP (who asked). Actions encoded
as the record at the policy entry:
- `CNAME .` → NXDOMAIN (block)
- `CNAME *.` → NODATA
- `A 192.168.50.250` → **sinkhole** (redirect to your capture host — where
  you log/notify/serve a block page)
- `CNAME rpz-passthru.` → whitelist/exception
Multiple RPZs evaluate in configured order; feeds are often delivered AS
zone transfers from a security vendor (RPZ is "just a zone" — everything
from Chapter 4 applies to distributing it).

**Honest scoping for security colleagues (your Day 58 explain):** RPZ
protects only clients using YOUR resolvers; DoH/other-resolver traffic
bypasses it entirely (TM 3.11); it acts at resolution time, not connection
time — direct-to-IP malware never asks. It's a cheap, wide net — not a
control you certify against.

**Quiz TM 4 Q22–26:**
22. Where does RPZ execute — authoritative or recursive — and why does that
    scope its protection?
23. Encode: block bad.example.net with NXDOMAIN; sinkhole worse.example.net
    to 192.168.50.250.
24. How do vendors typically deliver RPZ feeds, and why is that elegant?
25. Name two whole traffic classes RPZ cannot see.
26. Why log RPZ rewrites rather than silently rewriting?

**Key:** 22. Recursive — it rewrites answers to its clients; anyone not
using it is unprotected. 23. `bad.example.net CNAME .` ;
`worse.example.net A 192.168.50.250` (in the RPZ zone). 24. As standard
zone transfers (IXFR) of the policy zone — reuses battle-tested replication,
near-real-time updates. 25. Clients on other resolvers/DoH; direct-to-IP
connections (no DNS query at all). 26. The rewrite log is the detection
value: which client asked for which bad name when — feeding SOC/IR;
silent rewriting also creates unexplainable "wrong answers" for operators.

## TM 4.9 — Hardening: RRL, minimal-responses, posture

**Explanation.** The authoritative-edge hardening set:
- **response-rate-limit { responses-per-second N; };** — RRL: throttles
  identical responses to the same client prefix; the defense against being
  used as a DDoS **amplifier** (small spoofed query → big response → victim).
  RRL leaks some legitimate loss (slip/truncation mitigates: forcing TC=1
  makes real clients retry TCP, spoofed victims won't).
- **minimal-responses yes;** — trim AUTHORITY/ADDITIONAL when not required:
  smaller answers, less amplification value, marginally less info leak.
- **recursion no** + `allow-recursion { none; }` on authoritative;
  **allow-query** scoped per role; **allow-transfer** keyed;
  `version "none";` (fingerprint denial — cosmetic but standard).
- Separation of roles (authoritative vs recursive on distinct instances) as
  the master hardening move: independent failure domains, independent ACL
  postures, no cache on the internet-facing edge.

**Why open recursion is dangerous (Day 59, five sentences you must own):**
an open resolver answers anyone; UDP allows source spoofing; small queries
yield large (esp. DNSSEC/ANY) responses; attackers reflect and amplify
traffic onto victims with your bandwidth and your reputation; and your
resolver's cache becomes a poisoning/tracking surface for strangers.

*(Assessment: hardened config diff + written amplification explanation.)*

## TM 4.10 — BIND triage methodology

**Explanation.** The order of interrogation when a BIND server misbehaves —
config-and-state FIRST, queries second (queries tell you symptoms; state
tells you causes):
1. Is named running / did it restart? (`rndc status`, process, uptime.)
2. Would the config even load? `named-checkconf -z` (the `-z` also
   checkzones every zone — the one-command estate audit).
3. The specific zone: `rndc zonestatus` — loaded, serial, type, timers.
4. Logs, filtered by category: load errors, transfer lines, security
   (TSIG/ACL rejections), dnssec.
5. ONLY NOW dig: from the server itself (localhost, correct view!), then
   from a client — differences between those two locate ACL/view/network.
6. State surgery last: retransfer/freeze/flush — never as step 1, because
   surgery destroys the evidence of what was wrong.

**Senior version.** "Juniors dig first and flush second; the fault survives
because nobody read zonestatus. I go status → checkconf -z → zonestatus →
logs → dig-local → dig-remote. Six steps, ninety seconds, and the layer that
lies is identified before I've changed anything."

*(Assessment: Day 60 six-fault gauntlet, graded per fault library rubric.)*

---
**End of Part 3.** Part 4 (DNSSEC/TSIG-at-design-level, RPZ/views recap,
transfers security — Level 6–8 theory) and Part 5 (architecture, HA,
Anycast, GSLB, monitoring, migration, DR) arrive in Packet 7.
