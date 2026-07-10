# 23 — CLASSROOM APP NOTES (design record for future maintainers)
### Companion to 22_CLASSROOM.html — read before extending it.

## What it is
A single-file, local-first virtual classroom for the DNS Mastery System.
Curriculum, state, question banks, journal, and usage all live in the
browser's localStorage; the Anthropic API is called only for judgment
(grading) and generation (question banks, exams), batched and cached.

## How to run (Carlos: this is your part)
1. Open `22_CLASSROOM.html` in a browser (double-click; Chrome/Edge fine).
2. First run: enter API key (stored in localStorage only — never in the
   repo), select ALL the curriculum .md files from the repo folder,
   confirm day/date. Every file pill must be green except optional ones.
3. Thereafter: open the file → session menu → press `class`. Everything
   else is driven for you.
4. End of session: download STATE.md + journal via sidebar buttons, save
   into the repo (overwrite 20_STATE.md, journal file into
   dns-journal/daily/), commit. **The repo remains the source of truth;
   the browser is a cache** — export + commit daily, and the full-backup
   button covers browser-wipe disasters.

## Architecture decisions (why it's built this way)
- **Local-first:** lesson display, quiz administration, key reveals,
  oral tiers, retro, fault cards — zero API. Judgment only goes out.
- **Batched grading:** one call per class day carrying review answers +
  socratic answers + lab evidence + explain task (+ quiz if not
  self-scored). JSON in, scorecard out.
- **Prompt caching:** mentor prompt + day slice sent as cache_control
  ephemeral blocks — repeat calls in a session pay ~10% for them.
- **Slicing, not shipping:** the calendar row's TM/LAB/EIP/quiz refs are
  parsed by regex and only those sections are sent (verified: 132/132
  calendar rows parse; 60/60 TM refs and 21/21 LAB refs resolve; 27/27
  quizzes extract, incl. the Day-78 cross-section fallback).
- **Tiered grading:** quizzes/oral default to reveal-key self-scoring
  (free, preserves the offline method); free-text always mentor-graded.
- **Question banks:** per-TM-section 8-question banks generated once by
  the cheap model, stored forever — fresh interrogation at zero marginal
  cost afterward.
- **Bounded role-play:** tickets cap at 8 turns; the reporter persona is
  instructed never to reveal Path/Diagnosis; grading uses the ticket's
  own hidden answer as key.
- **Model routing (settings):** gen=Haiku, grade=Sonnet, heavy=Opus by
  default; all editable text fields so future model names just work.

## Cost model
Typical class day: 1 grading call (+1 gen call the first time a section
is met) ≈ €0.03–0.10. Exam day: 1 heavy gen + 1 heavy grade ≈ €0.25–0.60.
The sidebar meter shows cumulative estimate (edit prices via
localStorage key dmc_prices if list prices change).

## Known limits / extension points
- Calendar Week-19 capstone rows render via the 5-column fallback; run
  capstones through file 12 text + `exam`/`ticket` modes rather than
  `class`.
- CORS: calls use the anthropic-dangerous-direct-browser-access header —
  fine for a personal local file; don't host this publicly with a key.
- No streaming (batch responses are short; simplicity won).
- STATE export is one-way by design (app → repo). If localStorage is
  lost, restore from the backup JSON or re-seed via first-run + set day.
- Natural v2 ideas: import backup JSON, RFC-teaching mode (drop any RFC
  text in as a "curriculum file" and reuse the bank/quiz engine — the
  slicer already treats sections generically), spaced-repetition
  scheduling of weak topics.

## Handoff note
Built by Fable (Claude) on 2026-07-08, tested against the real
curriculum files with Node-simulated parsers before delivery. Any model
maintaining this: the grading law is in the MENTOR constant — vague =
zero. Do not soften it; that constant is the teacher.
