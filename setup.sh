#!/bin/bash
# One-time repo bootstrap. Run from inside the cloned repo folder.
set -e
mkdir -p dns-journal/daily dns-journal/proofs dns-journal/exams
touch dns-journal/daily/.gitkeep dns-journal/proofs/.gitkeep dns-journal/exams/.gitkeep
[ -f dns-journal/weak-topics.md ] || echo "# Weak Topics Queue" > dns-journal/weak-topics.md
[ -f dns-journal/errata.md ] || cp errata-seed.md dns-journal/errata.md
echo "Journal scaffold ready under ./dns-journal/"
