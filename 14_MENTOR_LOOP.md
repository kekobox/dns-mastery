# SECTION 16 — SELF-RUNNING MENTOR LOOP
### The mentor, after the mentor is gone.

The premise: strictness is a procedure, not a personality. Everything a
strict mentor did for you — refusing vagueness, forcing recall, choosing
what you repeat, not letting you advance — is reproducible as rules you
run on yourself. This file is those rules.

## 1. THE DAILY 2-HOUR BLOCK (fixed shape)

```
00:00–00:10  REVIEW    yesterday's flashcards (failed first) + ONE written
                       recall: "explain <yesterday's topic> from memory"
00:10–00:45  LESSON    assigned Teacher Manual section, actively: write ≥2
                       margin questions you'd ask a mentor
00:45–01:45  LAB       the day's hands-on; proof artifact saved to
                       proofs/DDD-topic.ext before you stop
01:45–02:00  CLOSE     written explain-to-a-senior (no notes) → self-test
                       quiz → grade → journal entry (5 lines, see §7)
```
Non-negotiables: the block starts with recall, never with reading; the
lab produces a file, never just "it worked"; the day ends graded.

## 2. HOW TO REVIEW YESTERDAY

Not re-reading. Three moves: (1) failed flashcards from yesterday, (2)
one blank-page recall of yesterday's core mechanism — write it, THEN
diff against the manual, and the DIFF (not the rewrite) goes in the
journal; (3) the Review column item from the calendar — if weak-topics.md
is non-empty, it overrides the column.

## 3. HOW TO TEST YOURSELF

Recall before recognition, always: attempt every quiz answer in writing
before looking at any key. Practical tests are armed blind — pre-write
fault cards, let Vanessa pick numbers, or roll dice; self-selected faults
teach nothing. Oral answers are RECORDED and replayed: hedge-words
("probably", "I think", "some kind of") are graded as vagueness even when
the content is right.

## 4. HOW TO GRADE YOURSELF (the honesty protocol)

Grade against the written keys/tiers, and apply the strict rule: **if you
had to reread the answer to decide whether yours matched, yours didn't.**
Half-credit exists only where the key says so. Practical grading is
binary per element: the artifact exists and shows the required evidence,
or it doesn't. Record every grade the same day; ungraded work counts as
failed. Once a week, re-grade one old exam cold — drift between your
past and present grading is itself a finding.

## 5. REPEATING WEAK TOPICS

weak-topics.md is a queue with rules: an item enters on any quiz <80%,
any ticket <3/5, any exam-failed element, any hedged oral answer. An
item leaves ONLY after two clean re-tests spaced ≥3 days, on FRESH
variants (new wording / newly-armed fault of the same class). While
queued, it occupies the daily Review slot and Saturday exam space. If
the queue exceeds 6 items, the calendar pauses for a consolidation day
— a long queue means you're moving faster than you're learning.

## 6. SIMULATING STRICT MENTOR FEEDBACK

Run these scripts on your own output:
- **The vagueness pass:** reread today's written explanation and delete
  every sentence a skeptic could answer with "which one?" or "how do you
  know?". What survives is your actual knowledge; rewrite the gaps.
- **The follow-up gun:** after any oral answer, fire the oral-pack
  F-line at yourself (or have Vanessa read them — she doesn't need to
  understand DNS, only to read the F: line and look unconvinced).
- **The "prove it" rule:** any claim about system state must be paired
  with the command that would prove it. No command = not a claim, a
  hope.
- **The red-team hour (Sundays):** attack your own week's best artifact
  — find three ways it's wrong, incomplete, or would fail in production.
  Written.

## 7. THE JOURNAL

`daily/YYYY-MM-DD.md`, five lines minimum: what I built/proved; what
broke and why (mechanism, not narrative); what surprised me; the
question I'd ask a mentor; grade for the day (pass/fail vs the day's
calendar row). The mentor-questions accumulate: every Sunday you must
ANSWER your own open questions from the week — with the manual, the
lab, or a designed experiment. A question that survives two Sundays
becomes a lab you invent.

## 8. LEVEL ADVANCEMENT DECISIONS

You advance when the Mastery Map's proof-of-mastery artifacts exist in
proofs/ and the gate exam passed — never on calendar sympathy. The
self-check before declaring a level done: open the Mastery Map's "must
be able to explain" list and speak each item aloud, cold, recorded. Any
stumble = not done, regardless of the exam score. If the calendar and
your readiness disagree, the calendar loses lesson time, never proof
time (Standing Rule 3).

## 9. WEEKLY SELF-RETROSPECTIVE (Sundays, 30 min, written)

Four questions, always the same: (1) What can I now do that I couldn't
last Sunday — stated as capabilities, with the artifact that proves each?
(2) Where did I fool myself this week (grades, skipped steps, hedges)?
(3) What is the single weakest link going into next week, and what
exactly will I do about it Monday? (4) Is the pace honest — am I
compressing learning or compressing proof? Then: prune weak-topics.md,
schedule remediation, pre-build next Saturday's exam file.

## 10. AFTER 15 NOVEMBER 2026 — KEEPING THE EDGE

The program ends; the loop shrinks but never stops:
- **Weekly (1 h):** 20 flashcards + one ticket re-solved cold from a
  random number + one oral-pack question recorded.
- **Monthly (2 h):** one Fault Library card armed and solved in the lab
  (keep the lab alive — it costs nothing idle); redraw the resolution
  flow and the cache map from memory; one handbook section annotated
  with anything new from work.
- **Quarterly:** re-take the baseline diagnostic (target: ≥90 forever);
  rebuild the entire lab from your own docs (the Day 124 rehearsal,
  repeated — infrastructure knowledge rots exactly as fast as you stop
  rebuilding it); update the [V] questionnaire against the real estate —
  platforms drift, and your verified knowledge should drift with them.
- **Continuously:** every real incident at work gets the report
  treatment (RB-28 structure) in your journal, and every genuinely new
  failure mode becomes a ticket you write in the T-format and add to
  file 09 — the simulator should grow with your career.
- **December 2026:** un-defer Section 10. Your first scripts encode the
  checks you now perform manually — CSV validation, forward/reverse
  consistency, serial-spread sweep, the bulk pre-check. You'll write
  them in a week, because the hard part — knowing what to check and why
  — is what the last four months built.

The last rule is the first rule, restated: **you are allowed to be
wrong; you are not allowed to be vague.** A mentor's real gift is the
refusal to accept fog. Keep refusing it on your own behalf, and you
won't need one.
