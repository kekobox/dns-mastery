# SECTION 17 (ADDENDUM C) — ERRATA & SOURCE-OF-TRUTH PROTOCOL
### How to correct your teacher after he's gone.

**The premise, stated bluntly:** this entire package came from one
source — a language model writing in July 2026. It is carefully built
and internally consistent, but it is not scripture, and four months of
daily lab work WILL surface points where it is imprecise, outdated for
your BIND version, or wrong. That's not a flaw in the program; handled
correctly, it's part of the training. Seniors are defined by how they
handle authoritative-looking sources that disagree with reality.

## 1. THE AUTHORITY HIERARCHY (memorize)

When sources disagree, they win in this order:
1. **Your lab, reproduced.** A behavior you can demonstrate on the wire
   beats any document — including RFCs' descriptions of what
   implementations "should" do.
2. **The RFCs** — for protocol truth (what the bits mean).
3. **The BIND ARM** (Administrator Reference Manual, matching YOUR
   version: `named -v`, then the ARM for 9.18.x) — for implementation
   truth (what named actually does with a directive).
4. **Vendor docs** (EfficientIP for [E]-tagged claims) — for platform
   truth; your [V] questionnaire converts these into verified local
   facts.
5. **This package.** Useful, structured, fallible. Rank 5 by design.

Disagreement between ranks is a JOURNAL EVENT, not a crisis: reproduce
(rank 1), read the higher rank, log the erratum, correct the file (the
files are yours — edit them), and make a flashcard of the corrected
fact. Corrected knowledge sticks harder than received knowledge.

## 2. THE ERRATA LOG

Create `dns-journal/errata.md` on Day 1. Format:
```
E### | date | file+section | claim as written | what's actually true |
how I proved it (command/RFC/ARM ref) | fixed in file? Y/N
```
Seeded with the first entry, logged by the author:
```
E001 | 2026-07-07 | 06 §2 client-access note | "Docker Desktop's WSL
integration routes container IPs from WSL" | often false — container IPs
live in the Desktop VM; use the client-container or published-port
patterns | Addendum B §1–3, verified by Day-2 matrix | Y (16 supersedes)
```
Target discipline, not volume — but if the log is still empty by
September, suspect your skepticism before suspecting the package.

## 3. RFC MAP (protocol truth, by topic)

| Topic | Primary RFCs |
|---|---|
| Core concepts & message format | 1034, 1035 |
| Negative caching (SOA MINIMUM semantics) | 2308 |
| Serial arithmetic | 1982 |
| Dynamic update | 2136 (TSIG: 8945, formerly 2845) |
| Zone transfer | 5936 (AXFR), 1995 (IXFR), NOTIFY 1996 |
| EDNS(0) | 6891 (+ the 2020 flag-day 1232 convention — community, not RFC) |
| DNS over TCP requirements | 7766 |
| DNSSEC core | 4033, 4034, 4035; NSEC3 5155; aggressive NSEC 8198; 8020 (NXDOMAIN cut) |
| Classless in-addr delegation | 2317 |
| CAA | 8659 |
| SVCB/HTTPS records | 9460 |
| DoT / DoH | 7858 / 8484 |
| Terminology (settles arguments) | 9499 |
Reading protocol: you don't read RFCs cover-to-cover during the program;
you OPEN them at the disputed sentence. The map exists so a dispute
costs five minutes, not an evening.

## 4. KNOWN SIMPLIFICATIONS — DECLARED UP FRONT

Honesty inventory; none invalidate the training, all are worth knowing:
1. **The fake root** uses invented TLDs (`tld.`, `root.`, plus real-name
   `net./example./internal.` mixes) — pedagogically ideal, cosmetically
   nonstandard. Real root operations (priming, RFC 8109) differ in
   detail.
2. **LAB 14 DNSSEC** uses a static trust anchor instead of a full
   signed root→TLD chain (declared in the lab). The Day 99 explain task
   covers why; production chains always run through the parent DS.
3. **EfficientIP [E] claims** are typical patterns, deliberately
   unversioned — the [V] questionnaire is the correction mechanism, not
   optional homework.
4. **bind_exporter metric names** in Addendum A: verify against
   /metrics on first run (noted there).
5. **Log-line wordings** (TSIG errors, transfer messages, RPZ rewrites)
   are representative of BIND 9.18; exact strings drift across
   versions. Match the CLASS, then record your version's exact string
   as a flashcard.
6. **Command flags** were written for current dig/PowerShell; a flag
   that errors on your build means check `dig -h` / `Get-Help`, log it,
   move on.
7. **The 132-day calendar's topic sizing** is a professional estimate
   of one person's pace, not a law — Standing Rule 3 (proofs over
   pace) is the governing correction.
8. **Anything about post-July-2026 software** (new BIND minor
   versions, EIP releases) is unknown to the author by construction;
   version-specific behavior discovered later belongs in the errata
   log, not in doubt about fundamentals — RFCs 1034/1035/2308 will
   outlive us all.

## 5. THE DISAGREEMENT DRILL (run it the first three times for real)

When lab behavior contradicts the package: (1) reproduce cleanly —
minimal case, fresh cache, right view; (2) rule out the usual suspects
first (CRLF, clock, serial, wrong node — Addendum B's table);
(3) consult rank 2/3 at the disputed point; (4) verdict: package wrong
(erratum + fix + flashcard) / package right, my setup wrong (journal
the trap) / both defensible, version-dependent (erratum with version
note). Time-box to 30 minutes; unresolved goes to weak-topics as a
designed experiment, not a rabbit hole.

## 6. WHY THIS FILE MIGHT BE THE MOST IMPORTANT ONE

The program's real product isn't DNS facts — it's the epistemics: claim
→ layer → proof → bound. A package that demanded belief would train the
opposite. Treat the author as you'd treat a departed senior colleague's
wiki: gratefully, and with dig in hand.
