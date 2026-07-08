# README — DNS MASTERY SYSTEM
### Aggressive Enterprise Track · 7 July → 15 November 2026
### START HERE. This page tells you how to use everything else.

---

## WHAT THIS IS

A complete, self-contained, offline training system that takes you from
intermediate DNS operator to senior enterprise DNS engineer in 132 days
at ≥2 hours/day. It contains the curriculum, the daily schedule, the
teaching material, a full Docker-based lab, runbooks, 50 tickets, 150
oral exam questions, flashcards, exams, capstones, and the self-mentoring
protocol. No external books, videos, or courses are required. The
trainer who built it is gone; file 14 replaces him.

## THE 24 FILES, IN ONE TABLE

| File | What it is | When you use it |
|---|---|---|
| **README.md** | This page | Now, and whenever lost |
| **00** Package Map & Mission | Objective, rules, assumptions, full index | Day 1, then reference |
| **01** Baseline Diagnostic | Entry exam + key + rubric | Day 1 (and retake 1 Nov) |
| **02** Mastery Map | 9 levels + proof-of-mastery criteria | At every level gate |
| **03** Daily Calendar | All 132 days, concrete work per day | **Every single day — this file is your boss** |
| **04** Teacher Manual (Parts 1–5) | The actual lessons + quizzes + keys | The Lesson slot, as the calendar assigns |
| **05** Command Mastery Pack | dig/delv/rndc/tcpdump/PowerShell + proof techniques | Alongside every lab; over-learn §2 and §11 |
| **06** Lab Environment | Docker compose, all configs/zones, LAB 0–14, fault library | Day 2 build, then daily |
| **07** EfficientIP Pack | SOLIDserver concepts, workflows, [V] questionnaire | Weeks 10–11 + before real changes |
| **08** Runbooks | 28 enterprise runbooks | Weeks 10–14 drills; keep forever at work |
| **09** Tickets (Parts 1–2) | 50 diagnosis tickets with scoring | Weeks 12–17, per calendar |
| **10** Oral Exam Pack | 150 questions, graded tiers, traps | Week 18 (and gate-week samples) |
| **11** Flashcards | The full deck, prose form | Daily Review slot |
| **12** Exams & Capstones | Weekly exam engine, CSV recipes, 5 capstones, final capstone rubrics | Every Saturday + month-ends + Week 19 |
| **13** Expert Handbook | Mental models, trees, cheat sheets, templates | Annotate from Day 116; keep at your desk for life |
| **14** Mentor Loop | Daily structure, self-grading, retros, post-program plan | Read Day 1; run it every day |
| **15** Observability Annex | Prometheus/Grafana/bind_exporter wiring | Build during Week 6; use from Week 12 |
| **16** First-Run Debugging | Docker/WSL reality, access patterns, gotchas | **READ BEFORE DAY 2** |
| **17** Errata Protocol | Source-of-truth hierarchy, RFC map, errata log | Day 1 (create the log); whenever lab disagrees with docs |
| **18** Anki Deck (.tsv) | All 80 flashcards, importable | Import Day 1 |

## SETUP — DAY 0/1 CHECKLIST (≈1 hour + the exam)

1. **Save everything.** Put all 24 files in a permanent folder, ideally a
   git repo (`dns-mastery/`). These files are yours to edit — corrections
   and annotations are part of the method (file 17).
2. **Create the journal structure** (from 00):
   ```
   dns-journal/
     daily/  proofs/  exams/  weak-topics.md  errata.md
   ```
3. **Import the Anki deck:** Anki → File → Import → `18_ANKI_DECK.tsv`
   (it self-configures; deck name "DNS Mastery").
4. **Verify prerequisites:** Windows + WSL2 + Docker
   (`docker info` works from WSL). Nothing else needed.
5. **Take the baseline exam** (file 01): 90 min, closed book. Grade with
   the rubric. Log score + gap analysis in `exams/`. Your rubric band
   tells you whether to adjust the program (see file 01 §rubric).
6. **Read file 14** (Mentor Loop) and file 16 §1–3 tonight — tomorrow's
   lab build depends on the access-pattern decision in 16.

## THE DAILY LOOP (2 hours, fixed — full detail in file 14)

```
0:00 REVIEW   flashcards (failed first) + one written recall
0:10 LESSON   today's Teacher Manual section (calendar names it)
0:45 LAB      today's hands-on (calendar names it; file 06 has the lab)
1:45 CLOSE    written "explain to a senior" → quiz → grade → journal
```
Open **file 03**, find today's row, do exactly what it says. Every day
ends with a proof artifact saved as `proofs/DDD-topic.ext` and a graded
self-test. Ungraded = failed. Saturdays: weekly exam (file 12 engine).
Sundays: retrospective (file 14 §9) + remediation.

## THE RULES THAT MAKE IT WORK

1. **The calendar is the boss; the proofs are the law.** You advance on
   proof-of-mastery artifacts (file 02), never on days elapsed.
2. **Recall before recognition.** Never look at an answer key before
   writing your attempt.
3. **Evidence before surgery** in every lab and ticket — no flushing or
   restarting before the owning layer is proven.
4. **Vague = wrong.** The grading standard from file 14 §4: if you had
   to reread the key to decide whether you matched it, you didn't.
5. **Missed days are made up, not skipped.** The 15 Nov date holds
   (Standing Rules, end of file 03).
6. **The package can be wrong.** Lab > RFC > ARM > vendor > package.
   Log errata (file 17); erratum E001 is already in there as the model.
7. **Blind arming.** Faults and capstone choices are picked by dice or
   by Vanessa — never by you.

## FILE CROSS-REFERENCE CONVENTIONS

Throughout the package: **TM x.y** = Teacher Manual section (file 04),
**LAB n** = lab in file 06, **RB-nn** = runbook in file 08, **Tnn** =
ticket in file 09, **Qnn** = oral question in file 10, **CMD §n** =
Command Pack section, **EIP §n** = file 07 section, **[U]/[E]/[L]/[V]**
= the EfficientIP honesty tags (universal / typical-EIP / lab-sim /
verify-in-your-real-estate).

## KEY DATES

| Date | Event |
|---|---|
| 7 Jul | Day 1 — baseline exam |
| 1–2 Aug | July capstone (build the estate) |
| 29–30 Aug | August capstone (BIND estate + gauntlet) |
| 26–27 Sep | September capstone (live incident + report) |
| 31 Oct | October capstone (design review + DNSSEC + migration) |
| 1 Nov | Baseline retake — target ≥90 |
| 9–15 Nov | Final capstone C1–C8 |
| 15 Nov | Program close + post-program plan (file 14 §10) |
| Dec 2026 | Un-defer the automation toolkit (Section 10) |

## IF YOU FALL OFF THE HORSE

Life happens. The re-entry protocol: don't "restart from Day 1" — open
weak-topics.md and your last journal entry, run one full daily block on
the last completed day's topic as a warm-up, then resume the calendar
with the make-up rule (3-hour days until caught up). The program
survives interruptions; it doesn't survive abandonment of the grading
honesty. Two weeks fully lost → shift every remaining date by two weeks
and write the new dates into file 03 — a moved deadline you keep beats
an original deadline you quietly drop.

## ONE-LINE SUMMARY OF THE WHOLE SYSTEM

Every day: recall → learn → build → prove → grade → log. Every week:
exam → retro. Every month: capstone. Every claim, forever:
**evidence, layer, bound, rollback.**

Good luck. — F.
