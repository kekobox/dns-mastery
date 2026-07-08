# DNS MASTERY SYSTEM — AGGRESSIVE ENTERPRISE TRACK
## July 2026 → 15 November 2026
### Packet 1a — Package Map & Mission Briefing

---

## SECTION 1 — MISSION BRIEFING

**Objective:** Convert an intermediate DNS/network engineer into someone who can
sit in the senior DNS chair: own enterprise DNS changes end-to-end, diagnose
incidents under pressure, explain resolution mechanics to senior network/security
engineers without hand-waving, and operate EfficientIP/SOLIDserver and BIND
professionally.

**Deadline:** 15 November 2026. 132 calendar days. Minimum 2 h/day. This is a
~270-hour program. Nothing here is optional. Skipped days are made up, not skipped.

**Final expected skill level — you pass the program when you can:**

1. Draw the full recursive resolution flow from stub resolver to root → TLD →
   authoritative, cold cache, from memory, including where glue, delegation,
   and negative caching enter the picture — and defend it against interruption
   questions from a senior engineer.
2. Prove, with commands and flags (AA, RA, TTL behavior), whether any given
   answer came from an authoritative server, a resolver cache, or a client cache
   — and therefore where a stale/wrong answer must be fixed.
3. Run a BIND lab (authoritative, recursive, forwarder, views, TSIG transfers,
   broken delegation, DNSSEC failure) and break/fix each deliberately.
4. Execute an enterprise DNS change on EfficientIP-style workflows: pre-check,
   validate CSV, apply, post-check, rollback — and articulate the risk of each
   record type change (A vs CNAME vs PTR vs MX).
5. Work 50 realistic tickets to correct diagnosis, including the tempting-wrong
   diagnosis and why it's wrong.
6. Pass a 150-question senior oral exam at "excellent answer" level on ≥80% of
   questions.

**How to use this package after today:**

- The **Calendar (file 03)** is your boss. Open it every day. Do the day's block.
- The **Teacher Manual (04)** is the lesson content the calendar points to.
- The **Lab Environment (06)** is built in Week 1 and used daily thereafter.
- The **Mentor Loop (14)** replaces me. It contains the self-grading protocol.
  You grade yourself in writing, every day, in a journal. Vague self-assessment
  = failed day. Redo it.
- **Nothing is passive.** Every day ends with a written explanation task (you
  write the answer as if presenting to a senior engineer) and a proof artifact
  (command output, config file, or diagram saved into your journal folder).

**Rules of engagement (strict mentor mode):**

- If you cannot explain a topic in writing without looking, you do not know it.
- "It's probably a cache issue" is not a diagnosis. A diagnosis names the exact
  cache (client / resolver / negative), the evidence, and the fix.
- Every command you run, you must be able to state *why* before running it.
- All labs use synthetic domains only: `lab.internal`, `corp.example`,
  `example.net`, and RFC1918 space (`10.10.0.0/16`, `172.20.0.0/16`,
  `192.168.50.0/24`). Real corporate tools are **read-only validation only**.

---

## PACKAGE MAP (all packets)

| Packet | File | Content | Status |
|---|---|---|---|
| 1a | 00_PACKAGE_MAP_AND_MISSION.md | This file | ✅ |
| 1b | 01_BASELINE_DIAGNOSTIC.md | Diagnostic exam + answer key + rubric + gap interpretation | ✅ |
| 1c | 02_MASTERY_MAP.md | 9-level mastery map with proof-of-mastery criteria | ✅ |
| 1d | 03_DAILY_CALENDAR.md | Full daily plan 7 Jul → 15 Nov 2026 | ✅ |
| 2a | 04_TEACHER_MANUAL_PART1.md | Fundamentals → records/zones/delegation/reverse (Levels 1–2) | ✅ |
| 2b | 06_LAB_ENVIRONMENT.md | Docker/WSL BIND lab: compose files, configs, zones, all break/fix labs | ✅ |
| 3a | 04_TEACHER_MANUAL_PART2.md | Recursion, caching, forwarding, split-horizon, negative caching, EDNS, transport (Level 3) | ✅ |
| 3b | 05_COMMAND_MASTERY_PACK.md | dig/nslookup/host/delv/rndc/named-check*/tcpdump/Resolve-DnsName/ipconfig, flag interpretation | ✅ |
| 4a | 04_TEACHER_MANUAL_PART3.md | BIND operations deep dive (Level 4) | ✅ |
| 4b | 07_EFFICIENTIP_PACK.md | SOLIDserver conceptual model + operational workflows (Level 5) | ✅ |
| 5 | 08_RUNBOOKS.md | All enterprise runbooks (add/delete/bulk/investigate/migrate/rollback) | ✅ |
| 6a | 09_TICKETS_PART1.md | Tickets 1–25 (intermediate → advanced) | ✅ |
| 6b | 09_TICKETS_PART2.md | Tickets 26–50 (advanced → senior) | ✅ |
| 7a | 04_TEACHER_MANUAL_PART4.md | DNSSEC, TSIG, transfers, dynamic update, RPZ, views (Levels 6–7 theory) | ✅ |
| 7b | 04_TEACHER_MANUAL_PART5.md | Architecture, HA, Anycast, GSLB, monitoring, migration, DR (Level 8) | ✅ |
| 8 | 10_ORAL_EXAM_PACK.md | 150 senior oral questions, graded answer tiers, traps | ✅ |
| 9 | 11_FLASHCARDS.md | Full spaced-repetition deck | ✅ |
| 10 | 12_EXAMS_AND_CAPSTONES.md | Weekly exams, answer keys, monthly capstones, final capstone | ✅ |
| 11 | 13_EXPERT_HANDBOOK.md | Compact final handbook: mental models, decision trees, cheat sheets | ✅ |
| 12 | 14_MENTOR_LOOP.md | Daily self-training loop, grading, journal, retrospectives | ✅ |
| — | (Section 10 automation toolkit) | **DEFERRED by your instruction** — revamp after mastery | ⏸ |

**Stated assumptions (per your instruction to assume and state):**

1. Lab runs on Windows + WSL2 + Docker Desktop; BIND 9.18+ containers
   (`internetsystemsconsortium/bind9:9.18`).
2. You have no EfficientIP lab appliance; SOLIDserver training uses:
   universal DNS/IPAM concepts + common EfficientIP operational patterns +
   BIND-based lab simulation + "verify in your real read-only environment"
   validation questions.
3. Weekly rhythm: 6 study days + 1 exam/review day. Monthly capstone replaces
   the last weekly exam of each month.
4. "Senior" is calibrated to enterprise operations (telco/MSP scale), not
   registry/root-operator scale.
5. Windows-client behavior is trained via your Windows host itself (PowerShell,
   ipconfig) against the lab resolvers.

---

## HOW EACH DAY WORKS (summary — full protocol in file 14)

1. **10 min** — Review: yesterday's flashcards + one written recall ("explain X
   from memory").
2. **30–40 min** — Lesson: read the assigned Teacher Manual section actively
   (write margin questions).
3. **50–60 min** — Lab: the day's hands-on task. Save proof output to journal.
4. **15 min** — Written explanation task: answer the day's "explain to a senior"
   prompt in writing, no notes.
5. **10 min** — Self-test: day's quiz. Grade with answer key. Score <80% → the
   topic re-enters tomorrow's review slot and Saturday's exam.
6. **5 min** — Journal entry: what broke, what surprised you, what you'd ask a
   mentor. (You will answer your own questions on review days.)

Journal structure (create in Week 1, Day 1):

```
dns-journal/
  daily/2026-07-07.md ...
  proofs/        # dig outputs, configs, pcaps
  exams/         # weekly exam answers + self-grades
  weak-topics.md # living list; a topic leaves only after 2 clean re-tests
```

## ADDENDA (added on request, 8 Jul 2026)
| File | Content |
|---|---|
| 15_OBSERVABILITY_ANNEX.md | bind_exporter + blackbox probes + SOA-sweep wired into your Prometheus/Grafana stack; Telenor Module A prototype |
| 16_FIRST_RUN_DEBUGGING.md | READ BEFORE DAY 2 — Docker Desktop/WSL2 reachability reality, the client-container pattern, CRLF/clock/rndc gotchas, Day-2 acceptance test |
| 17_ERRATA_PROTOCOL.md | Source-of-truth hierarchy, RFC map, declared simplifications, errata log (seeded with E001) |
| 18_ANKI_DECK.tsv | All 80 flashcards, Anki-importable (File → Import, deck "DNS Mastery") |
