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

This checklist is written from an actual first run (Windows 11 + Docker
Desktop + WSL2 Ubuntu), including every snag that first run hit and its
exact fix — not generic advice. Follow it in order.

### 1. Get the repo onto your machine

```powershell
mkdir C:\dev\dns-mastery
cd C:\dev\dns-mastery
git clone https://github.com/<your-username>/dns-mastery.git .
```
(Or, if starting from the zip instead of a clone: extract it here so the
24 numbered files + `dns-journal/` sit directly at `C:\dev\dns-mastery\`
— NOT inside a nested subfolder. Verify with `ls` — you should see
`00_PACKAGE_MAP...`, `README.md`, etc. directly, no extra folder layer.
If you do have a nested folder from an extract, flatten it:
```powershell
Move-Item .\<nested-folder>\* . -Force
Move-Item .\<nested-folder>\.gitattributes . -Force -ErrorAction SilentlyContinue
Move-Item .\<nested-folder>\.gitignore . -Force -ErrorAction SilentlyContinue
Remove-Item .\<nested-folder> -Recurse -Force
git add -A; git commit -m "Flatten repo structure"; git push
```
Confirm on GitHub: the breadcrumb should read just `<your-repo> /
README.md`, not `<your-repo> / <nested-folder> / README.md`.

### 2. Verify Docker Desktop + WSL2 (the real check, not "should work")

```powershell
docker info
```
If this errors with `failed to connect to the docker API` — **Docker
Desktop isn't running.** Open it from the Start menu, wait ~30-60s for
the whale icon to settle, retry.

Once it responds, confirm the backend:
```powershell
docker info | findstr /i "operating system"
```
Expect `Operating System: Docker Desktop` with a
`...-microsoft-standard-WSL2` kernel — this confirms you're on the
Docker Desktop VM-based architecture, which means **container IPs will
NOT be reachable directly from WSL** by default. This is exactly the
reality file 16 describes — you'll use the client-container pattern
(Pattern A) there, not raw container-IP access.

Also check for surprises before building anything:
```powershell
docker ps -a
```
Confirms no existing container already uses port 53/5353 or a name
this lab will create (`root1`, `tld1`, `auth1`, `auth2`, `auth1sec`,
`resolver1`, `fwd1`, `client`). If you already run a Prometheus/Grafana
stack (e.g. from kekobox/home-monitoring), note its container names now
— file 15 (Observability Annex) will extend that exact stack in Week 6,
not create a new one.

### 3. Enable Docker inside WSL (the step people miss)

```powershell
wsl -l -v
```
If your distro (e.g. Ubuntu) shows `Stopped`, start it: `wsl -d Ubuntu`.

Inside that WSL shell:
```bash
date                      # sanity-check the clock NOW — see note below
which docker
docker info
```
**If `which docker` points at a path under `/mnt/c/...`** (a Windows
binary shimmed into WSL) or **`docker info` says "could not be found in
this WSL 2 distro"** — WSL Integration is off. Fix: Docker Desktop →
**Settings → Resources → WSL Integration** → enable the general toggle
AND the specific toggle for your distro → **Apply & Restart**.

**If `docker info`/`docker ps` then says "permission denied ... docker.sock"**
— your WSL user isn't in the `docker` group yet:
```bash
sudo usermod -aG docker $USER
```
Group changes need a fresh session to apply — either run `newgrp docker`
in the same shell, or close the WSL window and reopen it
(`wsl --shutdown` from PowerShell, then `wsl -d Ubuntu` again).

Verify clean:
```bash
docker ps
```
should list your containers (or be empty on a fresh machine) with no
error.

**About that `date` check:** file 16 flags WSL clock drift after your
laptop sleeps as a real, recurring cause of TSIG (`BADTIME`) and DNSSEC
validation failures in Weeks 8–9 and 15 — nothing is "broken" in the
lab, the VM's clock just lagged. Confirming it's sane today gives you a
baseline; if labs misbehave later after a sleep/resume, `date` in WSL
vs. your Windows clock is the first thing to check, and
`sudo hwclock -s` (or `wsl --shutdown` + restart) is the fix.

### 4. Create the journal structure (should already exist if you cloned
   the repo/extracted the zip — verify, don't assume)

```bash
cd /mnt/c/dev/dns-mastery      # WSL path to the same folder
find dns-journal -type f
```
Expect: `dns-journal/daily/.gitkeep`, `dns-journal/exams/.gitkeep`,
`dns-journal/proofs/.gitkeep`, `dns-journal/errata.md`,
`dns-journal/weak-topics.md`. If any are missing, either re-run
`setup.sh` from the repo root or create them by hand per file 00.

### 5. Install Anki and import the deck

1. Download from **https://apps.ankiweb.net/** (Windows installer).
2. Install, launch. The AnkiWeb account prompt on first run is optional
   — skip it if you want to stay fully offline.
3. **File → Import** → browse to `C:\dev\dns-mastery\18_ANKI_DECK.tsv`.
   Anki auto-detects the format from the file's header lines. Confirm
   the import dialog shows deck name **"DNS Mastery"**.
4. Click **Import**. Expect: **"80 notes found in file. 80 new notes
   imported."** with every row showing status "Added".
5. Back on the main screen, confirm a deck called "DNS Mastery" exists
   with 80 cards; open it and preview one card (front like
   `[C01] Domain vs zone?`, back showing the answer plus bolded
   **Why:** / **Trap:** lines) to confirm rendering is correct.

### 6. Take the baseline exam

Open `01_BASELINE_DIAGNOSTIC.md`. 90 minutes, closed book, no notes, no
lab, no internet. Grade yourself against the rubric in that same file.
Log your score and per-section breakdown in
`dns-journal/exams/YYYY-MM-DD-baseline.md`. **This is the real starting
gun** — whatever date you actually sit it becomes Day 1 of 132 (shift
every date in file 03 accordingly if it's not literally 7 July; the
Standing Rules at the end of file 03 already account for this).

### 7. Read before tomorrow

Read file 14 (Mentor Loop) and file 16 §1–3 tonight — tomorrow's Day 2
lab build depends on the access-pattern decision made in file 16 (given
the Docker Desktop architecture confirmed in step 2, you'll be using
the **client-container pattern**, Pattern A).

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
