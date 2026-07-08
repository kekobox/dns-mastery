# SECTION 14 — WEEKLY EXAMS & MONTHLY CAPSTONES
### Final packet — Exam engine, gate exams, capstones, rubrics, remediation

## 1. THE WEEKLY EXAM ENGINE (all Saturdays)

Every weekly exam is assembled the same way — 60 min written + 30 min
practical, closed book:

**Written (60 min, 20 pts):**
- 8 questions drawn from the week's Teacher Manual quizzes, RE-WORDED by
  you the night before (Friday, 10 min: copy the quiz questions into the
  exam file, paraphrase each — writing the paraphrase without answering is
  allowed and is itself review). 1.5 pts each.
- 2 oral-pack questions from the current topic group, answered in writing
  at E-tier standard. 3 pts each.
- 1 "explain to a senior" prompt from the week's calendar entries,
  answered cold. 2 pts.

**Practical (30 min, 10 pts):**
- 2 evidence tasks: produce a specific proof artifact from the live lab
  (e.g., "show the same answer from cache and from authority with flag
  evidence" — pick from the week's proof list). 3 pts each.
- 1 armed fault from the Fault Library (06 §end), diagnosed with written
  cause+proof+fix. 4 pts. Have Vanessa pick the fault number so you can't
  self-select an easy one.

**Grading:** ≥85% (25.5/30) passes the week. Below → Sunday is remediation
(see §4) and the failed items enter weak-topics.md + next week's Review
column.

**Gate weeks** (2, 7, 9, 11, 13, 14): passing the exam is necessary but
NOT sufficient — the Mastery Map's proof-of-mastery artifacts for that
level must exist in `proofs/` and be checked off explicitly.

## 2. GATE-WEEK PRACTICAL SUPPLEMENTS

**Week 2 (Level 1):** rebuild resolver1's config from an empty file, from
memory, until recursion works (30 min cap). Pass = working + every line
explained aloud.

**Week 7 (Level 3):** the combined scenario — arm simultaneously: a stale
record at the forwarder, a view-ACL leak, and a negative-cache landmine
(three cards from the Fault Library + LAB 6/8 variants). 45 min to produce
three written diagnoses with layer-proofs. Pass = 3/3 layers correctly
named with evidence.

**Week 9 (Level 4):** the transfer gauntlet — arm: non-incremented serial
on one zone, TSIG secret corrupted on another, allow-transfer reverted on
a third. 45 min, logs-first discipline required (grade FAILS any diagnosis
that started with a flush/retransfer before evidence).

**Week 11 (Level 5):** the collision defense — for each of the four
"already exists" classes, present (aloud, recorded) the proof and the
correct action in ≤2 min each; then execute one full single-record
ceremony producing both evidence files.

**Week 13 (Level 6):** two armed incidents back-to-back, 40 min each,
each closing with the three comms artifacts (ack / update / resolution
with TTL honesty). Rubric per incident: cause 3, proof 3, fix 2, comms 2.

**Week 14 (Level 7):** the poisoned bulk exam — see §5 CSV-B. 90 min.
Pass = 100% of landmines found + a written refuse/repair/execute decision
per landmine + rollback artifact produced before any "execution".

## 3. PLANTED-ERROR CSVs (build them Friday of Week 10)

Construct these yourself against the CURRENT lab zone state (that's why
they can't be pre-written here — the landmines must contradict live
reality). Recipes:

**CSV-A (Week 11, Day 72 — validation drill, 50 add rows):** plant exactly:
2 duplicate rows (identical); 1 add colliding with an existing CNAME;
2 adds whose name exists with a DIFFERENT value; 3 malformed (bad IP
octet, missing dot convention violation, illegal hostname character);
2 IPs outside approved ranges (10.100.x typo pattern); 1 TTL of 0;
1 row whose reverse zone isn't served. Log the answer key separately;
finding rate must be 12/12.

**CSV-B (Week 14 exam + Day 74 — poisoned delete, 50 delete rows):**
plant: 3 rows deleting members of a live round-robin (create the RR set +
generate query traffic first); 2 rows whose value doesn't match deployed
reality; 2 names that are CNAME targets of other records; 1 name
referenced by an MX; 2 names with recent query-log hits; 1 name that
doesn't exist at all (delete of nothing — what's the correct disposition?);
1 duplicate delete pair. Answer key separate; 12/12 + correct disposition
statements required.

## 4. REMEDIATION PLAN (any failed exam/gate)

1. Same day: write, without notes, what you got wrong AND the correct
   answer with mechanism — the error analysis is the study unit.
2. Sunday: re-run the failed practical against a FRESH variant (re-arm a
   different fault card from the same class).
3. Failed items become flashcards (own words) + 5 days of Review-column
   priority.
4. Re-test Wednesday: the same question class, new wording. Two clean
   re-tests remove the item from weak-topics.md.
5. Two consecutive weekly failures on the same LEVEL = stop the calendar
   for 2 days, redo that level's Teacher Manual chapter + labs end to end.
   The 15 Nov date holds by compressing later lesson time, never proofs.

## 5. MONTHLY CAPSTONES

### JULY CAPSTONE (Sat 01 Aug) — "Stand up the estate" — 2 h hard cap
Build from scratch (empty directories; docs allowed EXCEPT copy-paste of
your own previous configs): corp.example with every record type from the
Teacher Manual ch.2, delegated dev.corp.example with glue, both reverse
zones, all served through resolver1, everything validated.
**Rubric (30):** zones load clean via named-checkconf -z (6); all record
types present + correct syntax incl. multi-string TXT (6); delegation
resolves end-to-end + parent referral shown (6); reverse consistent with
forward, proven with dig -x sweep (6); written walkthrough of one full
resolution through your estate (6). Pass ≥25. **Remediation:** re-run the
following Saturday with a fresh 2 h.

### AUGUST CAPSTONE (Sat 29 – Sun 30 Aug) — "BIND estate + gauntlet"
**Part 1 (2 h):** hidden-style primary + two secondaries, TSIG on every
transfer path, NOTIFY correct-and-directional, logging channels live,
serial-spread check script-of-the-mind (manual SOA sweep) documented.
**Rubric (30):** transfers signed + proven with one deliberate unsigned
failure (8); NOTIFY/IXFR observed in logs (6); logging categories landing
where declared (5); expiry timers read from zonestatus + interpreted (5);
commented configs (6). Pass ≥25.
**Part 2 (2 h):** five faults armed blind from the Fault Library (cards
1,4,5,6 + one wildcard pick). **Rubric:** per fault — layer named ≤5 min
(2), proof command shown (2), fix+verify (2) = 30. Pass ≥24 and ZERO
evidence-before-surgery violations.

### SEPTEMBER CAPSTONE (Sat 26 – Sun 27 Sep) — "Live incident + report"
**Part 1 (45 min + 45 min):** arm (Vanessa picks order): stale cache at
two layers + a view leak, simultaneously. Clock starts with a realistic
complaint sentence. Produce: diagnosis log with per-layer evidence, fix,
and the three comms artifacts.
**Rubric (30):** correct layers with proofs (10); no surgery before
evidence (4); fix verified at every layer (6); comms: ack ≤10 min mark
(3), resolution note contains TTL-honesty sentence (4); timeline accuracy
in the log (3). Pass ≥25.
**Part 2:** rewrite the incident report against the model structure
(RB-28): timeline, evidence, root cause, fix, prevention, convergence
statement. Compare; file both versions.

### OCTOBER CAPSTONE (Sat 31 Oct) — "Design review + DNSSEC + migration
decision" — 3 h
**Component 1 (60 min):** defend your architecture doc: answer, aloud and
recorded, oral-pack Q130–Q140 as a hostile reviewer would fire them
(Vanessa reads the F-lines as follow-ups).
**Component 2 (60 min):** DNSSEC incident armed (LAB 14b variant, blind
choice of expired-sigs vs anchor mismatch): full C8-method diagnosis +
written attribution (ours vs theirs) + the NTA decision with guardrails.
**Component 3 (60 min):** a migration plan review — take RB-24, produce
the concrete plan for migrating corp.example between lab servers with
real dates/TTL math for a fictional window next Tuesday 09:00; mark the
no-going-back point.
**Rubric (30):** design defense — tradeoffs owned, no risklessness claims
(10); DNSSEC — correct class in ≤3 commands, correct attribution (10);
migration — pointer-TTL math correct, gates named, rollback split
pre/post point-of-no-return (10). Pass ≥25.

## 6. FINAL ENTERPRISE CAPSTONE (Week 19, Days 126–132)

You are the DNS engineer on duty. Every component timed, every artifact
filed in `proofs/final/`. Vanessa (or dice) makes all blind choices.
Overall pass: ≥80% aggregate AND no component below 60%.

**C1 — Enterprise change (Mon, 2 h, 20 pts):** a 40-record mixed change
(write the request yourself Sunday night from a template: 25 adds incl.
MX/SRV/TXT, 10 deletes, 5 CNAME ops, at least 3 deliberate conflicts you
must catch as if a requester wrote it). Full ceremony: ticket, CSV
validation, pre-checks, rollback artifact, batched apply, post-checks at
every auth, closure comms. Rubric: conflicts caught 6; ceremony
completeness 6; evidence quality 4; comms with convergence clock 4.

**C2 — Stale-cache incident (Tue, 45+45 min, 10 pts):** armed multi-layer
staleness; diagnosis + fix + full incident report. Rubric: layers+proof 4;
fix order (source-first) 2; report to RB-28 standard 4.

**C3 — Delegation failure (Wed am, 45 min, 10 pts):** armed from Fault
cards 7 or 2 (blind). Rubric: three-command audit executed 4; correct
side (parent vs child) fixed 4; regression-proof verification 2.

**C4 — BIND config fault (Wed pm, 45 min, 10 pts):** armed from cards
1/3/5/6 (blind). Rubric: triage order honored (state before queries) 4;
root cause + fix 4; a one-line prevention (monitoring/config hygiene) 2.

**C5 — Bulk operation, EIP-style (Thu, 2 h, 20 pts):** a fresh CSV-B-class
poisoned file (build it Sunday with new landmines; answer key sealed).
Refuse/repair/execute decisions per landmine, rollback artifact BEFORE
execution, batched run of the clean subset, post-checks. Rubric: landmine
detection 8; disposition quality (incl. at least one justified refusal) 6;
rollback artifact validity (test-restore one record) 3; batching evidence 3.

**C6 — Senior design review (Fri am, 60 min, 10 pts):** final defense of
the architecture doc, recorded; five hostile questions minimum from
Q130–140 F-lines. Rubric: mechanism-level answers 6; tradeoffs owned 2;
no invented facts — "I'd verify X" used where honest 2.

**C7 — Rollback plan (Fri pm, 60 min, 10 pts):** scenario: yesterday's C1
change is declared faulty at T+20h (pick one applied batch as "bad").
Produce and EXECUTE the rollback for that batch only, with state-equality
proof (export diff) and the second-tail comms (negative caches from the
interval). Rubric: scoped rollback (not full revert) 4; state-equality
diff 3; comms honesty 3.

**C8 — Written incident report (Sat, 2 h, 10 pts):** composite report
covering C2–C4 as one operational week: executive summary, per-incident
timeline+evidence+root cause, systemic findings (what monitoring/process
would have prevented each — cite the Day 107 spec), and a 90-day
improvement plan. Rubric: accuracy vs your own logs 4; systemic findings
concrete 4; readable by a non-DNS manager 2.

**Sun 15 Nov — Program close:** aggregate scoring; final retrospective;
handbook final annotation pass; write the post-program maintenance plan
(Mentor Loop §10). If aggregate <80%: the program doesn't "fail" — it
extends: two remediation weeks re-running the failed components with
fresh arming, because the deadline was the forcing function, but the bar
is the point.
