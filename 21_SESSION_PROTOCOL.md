# 21 — SESSION PROTOCOL (the whole frontend, one page)
### How to attend class. This is all you ever need to remember.

## ONE-TIME SETUP (10 minutes)

1. claude.ai → **Projects → New Project** → name it `DNS Mastery
   Classroom`.
2. **Project knowledge:** upload files 00–18 (all curriculum .md files
   + the .tsv). Skip 19–21 as knowledge; 19 goes elsewhere:
3. **Project instructions:** open `19_MENTOR_PROMPT.md`, copy everything
   below its divider line, paste into the Project's custom
   instructions field.
4. Done. Every chat inside this Project is a class.

## EVERY SESSION (this is the entire routine)

1. New chat in the Project.
2. Paste the current contents of `20_STATE.md`, then one word:

   | You type | You get |
   |---|---|
   | `class` | today's full session (review → lesson → lab → grading) |
   | `exam` | Saturday weekly exam, administered + graded |
   | `retro` | Sunday retrospective interview |
   | `ticket` | live ticket role-play |
   | `arm a fault` | blind fault injected for you to diagnose |
   | `capstone` | the current month's capstone, run + graded |
   | `oral` | oral exam drill from file 10 |
   | `catch-up` | missed days → make-up plan, dates shifted |
   | `question: ...` | off-calendar help (work incident, curiosity) |

3. Attend: answer when interrogated, run lab commands with your own
   hands, paste outputs, write your answers BEFORE any reveal.
4. At the end, the mentor emits **JOURNAL** and **STATE** blocks:
   - JOURNAL → save as `dns-journal/daily/YYYY-MM-DD.md`
   - STATE → overwrite `20_STATE.md`
   - proof outputs from the lab → `dns-journal/proofs/DDD-topic.txt`
5. Commit:
   ```
   git add . && git commit -m "Day NNN" && git push
   ```
That's it. STATE + one word in; journal + state + commit out.

## MODEL CHOICE

- Daily `class` / `ticket` / `retro`: **Sonnet-class** is plenty.
- `exam` grading, `capstone`, `oral`, design reviews (Weeks 15–19):
  use the **strongest model available** — judgment depth pays there.
- Any current or future Claude model works; the prompt + STATE carry
  everything. Nothing depends on the model that wrote this.

## RULES YOU ENFORCE ON YOURSELF (the mentor enforces the rest)

1. Never peek at answer keys in the project files — the mentor grades;
   the keys stop being yours to read outside of grading reveals.
2. Labs are your hands. If you catch yourself asking the mentor to
   "just tell you" what the output would be, stop — run it.
3. The commit is the session. No commit = session didn't happen
   (you've already proven twice that git settles "did I do X").
4. Anki stays yours: the daily flashcard slot (plus the +30 min L1–2
   grind while the 0–39 adjustment is active) happens outside the
   chat, on your phone or desktop, before or after class.

## IF THINGS DRIFT

- Lost the thread mid-week? → `catch-up`.
- STATE feels wrong/corrupted? → paste the last committed version from
  git (`git log -- 20_STATE.md`, restore) — the repo is the memory,
  the chat never is.
- The mentor contradicts the lab or an RFC? → file 17 hierarchy, log
  the erratum, move on. The mentor is a teacher, not an oracle —
  same as the one who wrote it.
