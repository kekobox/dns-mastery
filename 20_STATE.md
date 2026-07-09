# 20 — STATE
### The classroom's memory. Paste this at the start of every session.
### The mentor emits the updated version at the end of every session;
### commit it. Git history = classroom history.

## POSITION
- Program: DNS Mastery System — Aggressive Enterprise Track
- Day 1 actual date: 2026-07-08 (baseline sat 8 Jul → ALL file 03 dates
  shift +1; Day 132 / final close = 16 Nov 2026)
- Current day: 1 COMPLETE (baseline exam done)
- Next session: Day 2 — namespace tree, domain vs zone, resolver roles;
  LAB 0 + client-container setup (Pattern A)
- Current level: 1 (core mechanics), Weeks 1–2

## SCORES
- Baseline diagnostic (2026-07-08): **35/100** — all parts weak, D
  marginally better. Graded strictly (near-misses taken as zero).
- Weekly exams: none yet
- Tickets: 0 attempted
- Oral pack: not started
- Capstones: none yet

## ACTIVE ADJUSTMENTS
- **0–39 rubric band (from baseline):**
  - +30 min/day Level 1–2 flashcards, Weeks 1–4 (day = 2.5 h total)
  - NO compression anywhere in Weeks 1–4
  - **Baseline RETAKE gate at end of Week 4** (fold into Day 27+1 =
    2026-08-03). Target: 60–79 band. Miss → extend Weeks 1–4 review
    before advancing to Level 3.
- Anki: only C/D/E-series cards active for now; later sections
  suspended until their calendar topics arrive.
- 1 Nov retake target unchanged: ≥90 (now dated 2026-11-02).

## WEAK TOPICS QUEUE
(from baseline; formal queue rules per file 14 §5 apply once daily
quizzes start)
- Cold-cache resolution flow, mechanism-level (Part A core)
- Flag semantics + output interpretation (Part B, all)
- Scenario diagnosis method — cause/proof/fix discipline (Part C, all)
- Negative caching / SOA minimum
- Delegation + glue mechanics

## ENVIRONMENT FACTS (verified 2026-07-08)
- Windows 11 + Docker Desktop (WSL2 backend, VM-based) — container IPs
  NOT directly reachable from WSL → **Pattern A: client container +
  `labdig` alias** (file 16 §3)
- WSL distro: Ubuntu; docker group fixed; clock verified sane
- Existing containers: home_monitoring stack (Grafana :3300,
  Prometheus :9091, Blackbox :9115 — file 15 extends THIS one in
  Week 6), paper_trader stack (has its own Prometheus :9090 /
  Grafana :3001 — NOT the monitoring target), open-webui :3000.
  No port-53/name collisions.
- Repo: C:\dev\dns-mastery (= /mnt/c/dev/dns-mastery in WSL), private
  GitHub kekobox/dns-mastery, flat structure, journal scaffold present,
  Anki deck imported (80/80).

## GATES STATUS
- Level 1 gate (Week 2 exam + proofs): pending
- Week 4 baseline retake gate: ARMED (2026-08-03)
- Levels 2–9 gates: pending

## ERRATA (pending append to dns-journal/errata.md)
- E001 already logged (Docker Desktop WSL reachability — file 16
  supersedes file 06's claim)

## NOTES FOR THE MENTOR
- Grade strictly; Carlos self-graded a near-miss as zero on the
  baseline — hold that standard.
- Lab commands in Pattern A form (`docker exec client ...` / labdig).
- Fault arming: mentor picks blind (replaces dice/Vanessa).
