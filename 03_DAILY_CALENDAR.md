# SECTION 4 — DAILY CALENDAR: 7 JULY → 15 NOVEMBER 2026
### Packet 1d — 132 days, minimum 2 h/day

Format per day: **Topic / objective** → **Hands-on (tools)** → **Explain + self-test (proof)** → **Review**.
- "Explain" = written answer, no notes, filed in journal. "Proof" = saved artifact (dig output, config, diagram, pcap).
- Every Saturday (or last weekday of the block): **weekly exam** (file 12). Every Sunday: retrospective + weak-topic redo (file 14 protocol).
- Review column = spaced repetition item; if it's on your weak-topics list, it overrides the listed item.
- TM = Teacher Manual (file 04). LAB = Lab Environment (file 06). CMD = Command Pack (file 05). EIP = EfficientIP pack (file 07). RB = Runbooks (file 08). TK = Tickets (file 09).

---

## WEEK 1 (Jul 7–12) — LEVEL 1: Core mechanics + lab build

| Day | Date | Topic / objective | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 1 | Tue 07 Jul | **Baseline diagnostic** (file 01). Objective: honest skill inventory. | Take 90-min exam closed-book; create journal structure; install Docker Desktop + verify WSL2. | Grade with rubric; write gap analysis in journal. Proof: exam file + score. | — |
| 2 | Wed 08 Jul | **The DNS tree, zones vs domains, roles.** TM 1.1–1.2. Objective: name every actor (stub/recursive/forwarding/authoritative) and its job. | LAB 0: build base Docker network `172.20.0.0/16`; run first BIND container; `dig @container . NS`. Tools: docker compose, dig (WSL). | Explain: "domain vs zone, with corp.example delegating dev.corp.example." Quiz TM 1 Q1–8. Proof: compose file + first dig output. | Baseline weakest question |
| 3 | Thu 09 Jul | **DNS message anatomy: header, flags, 4 sections.** TM 1.3. Objective: read any dig output line by line. | `dig +qr +all example.net` from WSL; annotate every line of query AND response by hand. Tools: dig, CMD §dig. | Explain each flag: QR AA TC RD RA AD CD — who sets it, when. Quiz TM 1 Q9–16. Proof: annotated output. | Day 2 roles |
| 4 | Fri 10 Jul | **Iterative resolution: root → TLD → authoritative. Referrals & glue.** TM 1.4. | `dig +trace www.example.net`; identify each referral, spot glue in ADDITIONAL. Then draw the flow on paper. | Explain cold-cache resolution from memory (the D1 oral question). Self-test: redraw without notes. Proof: photo of diagram. | Day 3 flags |
| 5 | Sat 11 Jul | **Build the core lab.** LAB 1: recursive resolver + authoritative `corp.example` + client testing. | Deploy LAB 1 compose stack (auth1, resolver1); load corp.example zone; resolve from Windows host via `Resolve-DnsName -Server`. Tools: docker, named-checkconf, named-checkzone, dig, PowerShell. | Explain: the exact path a query takes inside your lab. Quiz: LAB 1 troubleshooting questions. Proof: working dig with `aa` from auth1, without `aa` from resolver1. | Day 4 resolution flow |
| 6 | Sun 12 Jul | **Week 1 retro + authoritative vs cached evidence drill.** | Drill: produce the same answer 3 ways (auth / resolver cache / Windows client cache) and capture flag+TTL evidence for each. `ipconfig /displaydns`. | Weekly retrospective per file 14. Update weak-topics.md. Proof: 3-way evidence file — this is Level 1 proof artifact #2. | Whole week flashcards |

## WEEK 2 (Jul 13–19) — LEVEL 1: Transport, EDNS, caches everywhere

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 7 | Mon 13 Jul | **UDP vs TCP 53, truncation, EDNS(0), fragmentation, 1232.** TM 1.5. | `dig +noedns +ignore` vs `+bufsize=512` vs `+tcp` against lab; create an oversized TXT record and watch TC=1. Tools: dig, tcpdump in container. | Explain: three reasons DNS switches to TCP; what breaks if TCP 53 is firewalled. Quiz TM 1 Q17–22. Proof: pcap or tcpdump text of a TC=1 + TCP retry. | Day 5 lab paths |
| 8 | Tue 14 Jul | **Every cache between app and zone: stub, resolver, forwarder, negative.** TM 1.6. | Build the "cache map" diagram; verify each cache empirically in lab (query, then `rndc dumpdb -cache`, `ipconfig /displaydns`). | Explain: "where can a stale answer live and how do I purge each?" (Level 3 preview, seeded now.) Proof: cache map v1. | Day 7 TCP triggers |
| 9 | Wed 15 Jul | **Linux resolver stack:** /etc/resolv.conf, nsswitch, systemd-resolved, glibc behavior. TM 1.7. | In WSL: inspect resolv.conf generation; `resolvectl status`, `resolvectl query`, flush systemd cache; getent vs dig difference demo. | Explain: why `dig` can succeed while `ping <name>` fails (nsswitch/hosts). Quiz TM 1 Q23–27. Proof: getent-vs-dig demo output. | Day 8 cache map |
| 10 | Thu 16 Jul | **Windows resolver behavior:** DNS Client cache, suffix search list, LLMNR/mDNS, registration. TM 1.8. | On host: `Get-DnsClientCache`, suffix list experiments (short name vs FQDN), `Get-DnsClient*` cmdlets vs lab resolver. | Explain: how a short name `app1` becomes an FQDN on Windows and what can go wrong. Proof: suffix experiment log. | Day 9 Linux stack |
| 11 | Fri 17 Jul | **rd/ra semantics + `+norecurse` cache inspection + query ID/source-port randomization (poisoning defense concept).** TM 1.9. | Drill: use `+norecurse` against resolver1 to prove cache contents before/after TTL expiry. | Explain B4-style scenario in writing. Quiz TM 1 Q28–32. Proof: norecurse before/after capture. | Day 10 Windows cache |
| 12 | Sat 18 Jul | **WEEK 2 EXAM** (Level 1 exam, file 12) + Level 1 proof check. | 60-min written exam + 30-min practical (3 evidence tasks). | Grade; anything <85% → weak-topics. Proof: exam + grades. | — |
| 13 | Sun 19 Jul | Retro + remediation of Week 2 exam gaps. Redo failed practical items. | Re-run failed drills until clean. | Retro per file 14. | All L1 flashcards |

## WEEK 3 (Jul 20–26) — LEVEL 2: SOA, records, zone files

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 14 | Mon 20 Jul | **SOA record: every field. Serial discipline. Minimum = negative TTL.** TM 2.1. | Modify corp.example SOA values in lab; observe refresh/retry/expire meaning (conceptually + config); break serial (forget to increment) and observe secondary later this week. | Explain: each SOA field to a junior in one sentence each. Quiz TM 2 Q1–6. Proof: annotated SOA. | Day 11 norecurse |
| 15 | Tue 21 Jul | **A/AAAA, CNAME + exclusivity rule, the apex problem.** TM 2.2. | Add records to lab zone; try to add TXT next to a CNAME → capture named-checkzone/named error; try CNAME at apex → capture error. | Explain D4 oral question in writing. Quiz TM 2 Q7–12. Proof: both error captures. | Day 14 SOA fields |
| 16 | Wed 22 Jul | **MX, TXT, SPF/DKIM/DMARC at DNS level.** TM 2.3. | Build a full mail-DNS set for corp.example in lab: MX, SPF TXT, DKIM selector TXT (long, multi-string), DMARC TXT. Query each; note TXT string splitting. | Explain: what each of SPF/DKIM/DMARC records *does* at DNS level and the MX-must-not-be-CNAME rule. Quiz TM 2 Q13–18. Proof: dig outputs. | Day 15 CNAME rule |
| 17 | Thu 23 Jul | **SRV, CAA, NAPTR, wildcards.** TM 2.4. | Add `_ldap._tcp` SRV, CAA, a wildcard `*.apps.corp.example`; test wildcard shadowing (create `x.apps` and see wildcard stop matching for it). | Explain: SRV field meanings; the wildcard trap. Quiz TM 2 Q19–24. Proof: wildcard shadowing demo. | Day 16 mail records |
| 18 | Fri 24 Jul | **Zone file syntax mastery: $TTL, $ORIGIN, relative names, trailing dot.** TM 2.5. | Deliberately break a zone 5 ways (missing dot, bad $ORIGIN, dup CNAME, bad TTL, missing NS) and diagnose each with named-checkzone before fixing. | Explain: the trailing-dot bug in one paragraph with an example of the resulting broken FQDN. Proof: 5 break/fix pairs. | Day 17 SRV/wildcards |
| 19 | Sat 25 Jul | **WEEK 3 EXAM** + record-type risk table. | Exam file 12; then write the "record risk table": for each type, what breaks when it's wrong. | Grade. Proof: exam + risk table (Level 2 proof artifact). | — |
| 20 | Sun 26 Jul | Retro + remediation. | Redo weakest zone-file drill. | Retro. | L2 flashcards so far |

## WEEK 4 (Jul 27 – Aug 2) — LEVEL 2: Delegation, reverse DNS + JULY CAPSTONE

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 21 | Mon 27 Jul | **Delegation mechanics: parent NS, glue, in-bailiwick.** TM 2.6. | LAB 3: stand up auth2 as `dev.corp.example`; delegate from corp.example WITH glue; resolve through resolver1 and trace the referral. | Explain: when glue is mandatory and the circular dependency without it. Quiz TM 2 Q25–30. Proof: working delegation dig +trace-style walk. | Day 18 zone syntax |
| 22 | Tue 28 Jul | **Lame delegation break/fix.** TM 2.7. | LAB 3b: break the delegation 3 ways (NS to dead server; NS to server without the zone; missing glue). Diagnose each from resolver symptoms only, then fix. | Explain C3 scenario in writing. Proof: 3 diagnosis logs. | Day 21 glue |
| 23 | Wed 29 Jul | **Reverse DNS: in-addr.arpa, PTR, classless /24s, RFC 2317 concept.** TM 2.8. | LAB 4: create `20.10.10.in-addr.arpa` + `50.168.192.in-addr.arpa`; PTRs matching forward records; test `dig -x`; create one deliberate forward/reverse mismatch and detect it. | Explain: how 10.10.20.15 maps to a PTR name, octet by octet; why reverse breaks silently. Quiz TM 2 Q31–36. Proof: dig -x outputs + mismatch detection. | Day 22 lame delegation |
| 24 | Thu 30 Jul | **NXDOMAIN vs NODATA vs wildcard interaction; negative caching first contact.** TM 2.9. | Drill: produce NXDOMAIN, NODATA, wildcard-synthesized answers on demand in lab; watch negative TTL by querying resolver for a missing name, then creating it, timing when it appears. | Explain A3+A4 in writing. Proof: timed negative-cache experiment log. | Day 23 reverse |
| 25 | Fri 31 Jul | Buffer/consolidation day: finish any incomplete L2 lab; pre-capstone review. | Re-run delegation + reverse labs cold (from empty configs, no notes). | Self-test: rebuild speed + correctness log. | Weeks 3–4 all |
| 26 | Sat 01 Aug | **JULY CAPSTONE** (file 12): "Stand up a complete corp.example estate" — forward zone all record types, delegated child, both reverse zones, all validated — from scratch, 2 h limit, then written walkthrough. | Full build against rubric. | Grade against capstone rubric. Proof: capstone folder. | — |
| 27 | Sun 02 Aug | Capstone review + remediation. | Fix anything failed; re-run. | Retro; update weak-topics. | L1+L2 flashcards |

## WEEK 5 (Aug 3–9) — LEVEL 3: Caching deep dive

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 28 | Mon 03 Aug | **Resolver cache internals: RRset caching, TTL decrement, cache dump reading.** TM 3.1. | `rndc dumpdb -cache` on resolver1; read the dump; find your cached RRsets, negative entries, and the decrement in action. | Explain: what exactly is cached (RRsets, not "queries"). Quiz TM 3 Q1–5. Proof: annotated cache dump excerpt. | Day 24 negative cache |
| 29 | Tue 04 Aug | **Negative caching (RFC 2308) mastery.** TM 3.2. | LAB 5: tune SOA minimum vs record TTLs; measure NXDOMAIN persistence precisely; `rndc flushname` as targeted purge. | Explain: "I created the record but it still says NXDOMAIN" — full mechanism + comms you'd send the app team. Proof: measurement table. | Day 28 cache dump |
| 30 | Wed 05 Aug | **Stale-cache anatomy: the change-propagation timeline.** TM 3.3. | LAB 6 (stale cache lab): change a record at auth, track staleness across resolver + Windows cache; practice targeted flushes at each layer; document who sees what, when. | Explain C1 scenario end-to-end with your own lab timestamps. Proof: propagation timeline. | Day 29 negative TTL |
| 31 | Thu 06 Aug | **TTL strategy: choosing TTLs, pre-change lowering, round-robin interaction.** TM 3.4. | Drill: plan + execute a "TTL ramp-down" change in lab (300→60→change→restore); create a 2-record round-robin and observe rotation at resolver. | Explain: TTL policy you'd propose for corp zones (and why not "everything 60s"). Quiz TM 3 Q6–10. Proof: ramp-down log. | Day 30 propagation |
| 32 | Fri 07 Aug | **Cache inspection & flush command drill across all layers.** CMD focus day. | Speed drill: given 6 staleness scenarios (self-armed via LAB 6 variants), identify layer + flush it, <5 min each. rndc flush/flushname/flushtree, resolvectl flush-caches, ipconfig /flushdns, Clear-DnsClientCache. | Explain: why `rndc flush` (everything) is a bigger hammer than flushname — risks. Proof: drill times + results. | Day 31 TTL strategy |
| 33 | Sat 08 Aug | **WEEK 5 EXAM** + cache-map v2. | Exam; update cache map with everything learned (Level 3 proof artifact). | Grade. Proof: exam + cache map v2. | — |
| 34 | Sun 09 Aug | Retro + remediation. | Redo weakest cache drill. | Retro. | L3 flashcards |

## WEEK 6 (Aug 10–16) — LEVEL 3: Forwarding architectures

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 35 | Mon 10 Aug | **Forwarders: forward-first vs forward-only; the forwarder's own cache.** TM 3.5. | LAB 7: add fwd1 container forwarding to resolver1; trace a query through the chain with query logging on both; observe double caching. | Explain: where SERVFAIL originates in a forwarder chain and how to bisect it. Quiz TM 3 Q11–15. Proof: two-hop query log trace. | Day 32 flush drill |
| 36 | Tue 11 Aug | **Conditional forwarding & stub zones; AD DNS coexistence pattern.** TM 3.6. | LAB 7b: conditional-forward `dev.corp.example` directly to auth2, bypassing normal path; discuss (written) how AD zones are typically conditionally forwarded to DCs. | Explain: conditional forward vs stub zone vs delegation — when each. Proof: working conditional forward + written comparison. | Day 35 forwarder chain |
| 37 | Wed 12 Aug | **Failure modes in forwarding hierarchies.** TM 3.7. | Break the chain 4 ways (upstream dead → SERVFAIL vs timeout; wrong ACL → REFUSED; forward-only vs forward-first behavior difference under failure). | Explain A13 (SERVFAIL/REFUSED/timeout) with lab evidence for each. Proof: 4 failure captures. | Day 36 conditional fwd |
| 38 | Thu 13 Aug | **Internal vs external DNS architecture; why enterprises split.** TM 3.8. | Design on paper: corp.example internal + external estate (servers, zones, flows); implement the *external* auth container (auth-ext) with the public-view zone content. | Explain: data-flow of an internal user resolving an internal name vs an internet name in your design. Quiz TM 3 Q16–20. Proof: architecture diagram v1. | Day 37 failure modes |
| 39 | Fri 14 Aug | **Split-horizon with BIND views.** TM 3.9. | LAB 8: single BIND with two views (internal/external) for portal.corp.example; verify different answers by source IP; capture both. | Explain A10 + how views match clients and the ordering trap. Proof: dual-answer capture. | Day 38 architecture |
| 40 | Sat 15 Aug | **WEEK 6 EXAM** + split-horizon leak drill. | Exam; then LAB 8b: arm the "internal client gets external answer" leak (ACL gap) and diagnose it cold. | Grade. Proof: exam + leak diagnosis log. | — |
| 41 | Sun 16 Aug | Retro + remediation. | — | Retro. | Forwarding flashcards |

## WEEK 7 (Aug 17–23) — LEVEL 3: Transport, EDNS, DoT/DoH, client quirks

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 42 | Mon 17 Aug | **EDNS deep dive + fragmentation failures.** TM 3.10. | LAB 9: giant TXT record; test bufsize 512/1232/4096; simulate frag-hostile path (conceptually + truncation observation); prove `+tcp` bypass. | Explain C7 scenario fully. Quiz TM 3 Q21–25. Proof: bufsize matrix results. | Day 39 views |
| 43 | Tue 18 Aug | **DoT & DoH: what changes operationally; enterprise policy view.** TM 3.11. | Test a public DoT/DoH resolver from WSL (kdig/curl DoH or dig +https where available); written analysis: what breaks corporate split-horizon when clients use DoH. | Explain: "should we block DoH on the corporate network?" — argue both sides, land a recommendation. Proof: analysis memo. | Day 42 EDNS |
| 44 | Wed 19 Aug | **Windows client deep quirks:** search suffix ordering, cache of negative answers, NRPT concept, multi-NIC resolver selection. TM 3.12. | Experiments on host: negative caching on Windows; multi-adapter DNS ordering (Wi-Fi vs vEthernet); document surprises. | Explain: "user on VPN resolves internal names wrong" — three Windows-side causes. Proof: experiment log. | Day 43 DoH memo |
| 45 | Thu 20 Aug | **Linux client deep quirks:** systemd-resolved split DNS, per-link domains, stub listener 127.0.0.53. TM 3.13. | WSL/VM: configure per-link routing domain for lab.internal → resolver1; watch resolvectl route the query. | Explain: how 127.0.0.53 confuses dig users; the resolvectl equivalent of your Windows findings. Proof: resolvectl query trace. | Day 44 Windows quirks |
| 46 | Fri 21 Aug | **Level 3 integration drill:** full-path staleness + split-horizon + forwarding combined scenario. | Self-arm the LAB 6+7+8 combined scenario (file 06); solve cold with written diagnosis first. | Explain D2 (the full decision sequence) — record yourself saying it in <2 min. Proof: recording noted + written tree. | Day 45 Linux quirks |
| 47 | Sat 22 Aug | **WEEK 7 EXAM** (Level 3 gate). | Exam + practical. | Grade; L3 proof criteria check per mastery map. | — |
| 48 | Sun 23 Aug | Retro + remediation. | — | Retro. | L3 full deck |

## WEEK 8 (Aug 24–30) — LEVEL 4: BIND core + AUGUST CAPSTONE

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 49 | Mon 24 Aug | **named.conf anatomy: options, acl, zone, logging, controls.** TM 4.1. | Rewrite your lab configs from scratch, commented line-by-line; validate with named-checkconf; enable structured logging channels (queries, xfer, security). | Explain: what each block in your config does — to a junior. Quiz TM 4 Q1–6. Proof: commented named.conf. | Day 46 decision tree |
| 50 | Tue 25 Aug | **Primary/secondary, NOTIFY, serial discipline.** TM 4.2. | LAB 10: add secondary for corp.example; watch NOTIFY + transfer in logs; break it with a non-incremented serial; fix; then the serial-went-backwards disaster + 2^31 recovery technique. | Explain: life of a zone change edit→answer; the serial-rewind fix. Proof: log excerpts of NOTIFY/XFR. | Day 49 named.conf |
| 51 | Wed 26 Aug | **AXFR vs IXFR, journals.** TM 4.3. | LAB 10b: observe IXFR in logs/tcpdump; trim journal → watch AXFR fallback; inspect .jnl behavior. | Explain A15 with your own evidence. Quiz TM 4 Q7–11. Proof: IXFR + fallback captures. | Day 50 serials |
| 52 | Thu 27 Aug | **TSIG: keys, signed transfers, failure signatures.** TM 4.4. | LAB 11: generate key (tsig-keygen), secure the transfer, prove unsigned AXFR now REFUSED; break with wrong secret + simulated clock skew; read the exact log signatures. | Explain C4 fully with evidence. Proof: TSIG success + 2 failure log signatures. | Day 51 IXFR |
| 53 | Fri 28 Aug | **rndc mastery + zone expiry on secondaries.** TM 4.5. | Drill all relevant rndc verbs (status, reload, retransfer, flush*, freeze/thaw, zonestatus, dumpdb); kill the primary and fast-forward the expiry concept (short expire timer) → watch secondary SERVFAIL. | Explain: why a secondary suddenly SERVFAILs a zone it "has". Quiz TM 4 Q12–16. Proof: expiry demo log. | Day 52 TSIG |
| 54 | Sat 29 Aug | **AUGUST CAPSTONE part 1** (file 12): BIND estate build — hidden-ish primary + 2 secondaries, TSIG everywhere, logging, monitored serials — timed. | Capstone build. | Grade vs rubric. Proof: capstone folder. | — |
| 55 | Sun 30 Aug | **AUGUST CAPSTONE part 2:** armed break/fix gauntlet (5 faults injected per capstone doc) + retro. | Solve gauntlet with written diagnoses. | Grade; retro. | L4 so far |

## WEEK 9 (Aug 31 – Sep 6) — LEVEL 4: Dynamic updates, logging, RPZ

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 56 | Mon 31 Aug | **Dynamic DNS updates: nsupdate, journals, freeze/thaw.** TM 4.6. | LAB 12: allow-update with TSIG; add/delete records via nsupdate; hand-edit trap: edit zone file without freeze → observe the mess → recover properly. | Explain: why you must freeze dynamic zones before editing; how AD clients do this at scale (concept). Quiz TM 4 Q17–21. Proof: nsupdate session + recovery log. | Capstone weak point |
| 57 | Tue 01 Sep | **BIND logging & query-log analysis.** TM 4.7. | Enable querylog; generate traffic; analyze: top names, NXDOMAIN rate, who queried a name before deleting it (the blast-radius technique). | Explain: how query logs de-risk deletions. Proof: mini analysis report. | Day 56 dynamic updates |
| 58 | Wed 02 Sep | **RPZ / DNS firewalling / sinkholing.** TM 4.8. | LAB 13: create an RPZ zone; block `bad.example.net` → NXDOMAIN; then sinkhole it to 192.168.50.250; verify precedence + logging. | Explain: RPZ to a security engineer — what it can/can't do, and the DoH bypass problem. Quiz TM 4 Q22–26. Proof: block + sinkhole captures. | Day 57 query logs |
| 59 | Thu 03 Sep | **Rate limiting, hardening, minimal-responses, version hiding.** TM 4.9. | Apply RRL + hardening options to lab auth; test behavior; document each option's purpose. | Explain: why open recursion is dangerous (amplification) in 5 sentences. Proof: hardened config diff. | Day 58 RPZ |
| 60 | Fri 04 Sep | **BIND troubleshooting methodology consolidation.** TM 4.10. | Gauntlet: 6 pre-armed BIND faults (file 06 fault library) solved cold, using named-checkconf/checkzone/logs/rndc first, dig second. | Explain: your BIND triage order and why config-check precedes queries. Proof: 6 diagnosis logs. | Day 59 hardening |
| 61 | Sat 05 Sep | **WEEK 9 EXAM** (Level 4 gate). | Exam + practical. | Grade; L4 proof criteria check. | — |
| 62 | Sun 06 Sep | Retro + remediation. | — | Retro. | L4 full deck |

## WEEK 10 (Sep 7–13) — LEVEL 5: EfficientIP/SOLIDserver concepts

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 63 | Mon 07 Sep | **SOLIDserver conceptual model: appliance, managed servers, smart architectures, views, zones, RRs.** EIP §1–2. | Build the written object map: every EIP object → its BIND-file equivalent. If corp access available: read-only browse to confirm structure (NO changes). | Explain: "what actually happens between clicking Add in the GUI and a client resolving it." Quiz EIP Q1–6. Proof: object map. | Day 60 BIND triage |
| 64 | Tue 08 Sep | **IPAM ↔ DNS relationship: spaces, networks, addresses, auto-PTR.** EIP §3. | Model an IPAM sheet for 10.10.20.0/24 (CSV as stand-in); map each column to lab zone data; identify where forward/reverse consistency is enforced vs drifts. | Explain: how IPAM-driven DNS prevents — and still permits — stale PTRs. Quiz EIP Q7–11. Proof: model sheet. | Day 63 object map |
| 65 | Wed 09 Sep | **"Record already exists" taxonomy.** EIP §4. | Reproduce each collision class in lab BIND (exact dup, same name diff value, CNAME vs A, auto-PTR collision); write the EIP-context interpretation of each error. | Explain: the four different things "already exists" can mean and the check for each. Proof: collision matrix. | Day 64 IPAM model |
| 66 | Thu 10 Sep | **EIP change surfaces: GUI, CSV import, API (conceptual); rights & approval workflow.** EIP §5. | Design your team's ideal change flow on paper; list the read-only validation questions to answer in your real environment (EIP §9 questionnaire) and answer what you can. | Explain: what a senior expects verified before approving a change. Quiz EIP Q12–16. Proof: questionnaire progress. | Day 65 collisions |
| 67 | Fri 11 Sep | **GUI-says-X-but-dig-says-Y: deployment/propagation layer.** EIP §6. | Simulate in lab: change zone data but don't reload (staged ≠ deployed); practice the proof sequence GUI/object → managed-server zone data → resolver cache. | Explain: the three layers that can disagree and the query that isolates each. Proof: layered proof capture. | Day 66 change flow |
| 68 | Sat 12 Sep | **WEEK 10 EXAM.** | Exam + practical (collision matrix defense). | Grade. | — |
| 69 | Sun 13 Sep | Retro + real-environment read-only validation session (if reachable) or questionnaire completion. | Read-only verification of Week 10 concepts against corp SOLIDserver. | Retro. Proof: verified questionnaire. | EIP deck |

## WEEK 11 (Sep 14–20) — LEVEL 5: EIP operational workflows

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 70 | Mon 14 Sep | **Single-record change workflow: pre-check → apply → post-check.** EIP §7 + RB (add/delete A). | Execute RB "Add A record" and "Delete A record" against lab exactly as written, producing every evidence artifact the runbook demands. | Explain: why pre-check compares name+type+value+TTL, not existence. Quiz EIP Q17–21. Proof: 2 completed runbook records. | Day 67 layers |
| 71 | Tue 15 Sep | **CNAME & PTR workflows + dependency analysis.** RB (CNAME, PTR, fix reverse). | Execute CNAME add where an A exists (blocked → resolve properly); fix a missing PTR end-to-end; build the "what references this name" checklist (CNAME targets, MX, SRV, NS). | Explain C2 + A7 combined as one operational story. Proof: runbook records. | Day 70 pre-checks |
| 72 | Wed 16 Sep | **Bulk CSV change design: format, validation rules, batching.** EIP §8. | Write your CSV standard (columns, allowed values); manually validate a provided 50-row add CSV (file 12 supplies it) against lab: find all planted errors. | Explain: your validation rule list, ordered. Quiz EIP Q22–26. Proof: validation findings. | Day 71 dependencies |
| 73 | Thu 17 Sep | **Bulk execution + rollback artifacts.** RB (bulk add/delete). | Execute the clean 50-row bulk add in lab in batches with mid-checks; generate the rollback file BEFORE executing; then bulk-delete using it — full circle. | Explain D5 in writing, improved with today's experience. Proof: full bulk evidence folder. | Day 72 CSV rules |
| 74 | Fri 18 Sep | **The poisoned-CSV gauntlet** (Level 7 preview, run now). | 50-row delete CSV with landmines (dupes vs round-robin, records that don't match, CNAME targets, active-query names) — find 100% before "executing". | Explain: each landmine class + the check that caught it. Proof: landmine report. | Day 73 rollback |
| 75 | Sat 19 Sep | **WEEK 11 EXAM** (Level 5 gate). | Exam + oral-pack EIP section dry run. | Grade; L5 proof criteria check. | — |
| 76 | Sun 20 Sep | Retro + remediation. | — | Retro. | L5 deck |

## WEEK 12 (Sep 21–27) — LEVEL 6: Troubleshooting under fire + SEPTEMBER CAPSTONE

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 77 | Mon 21 Sep | **The universal isolation method, formalized.** TM 6.1. | Write your master decision tree (v1) covering: wrong answer / no answer / slow / intermittent. Test it against 3 armed labs. | Explain D2 again — compare with Day 46 recording; note improvement. Proof: decision tree v1. | Day 74 landmines |
| 78 | Tue 22 Sep | **tcpdump/Wireshark for DNS.** TM 6.2 + CMD §tcpdump. | Capture healthy resolution, truncation+TCP retry, XFR, SERVFAIL exchange; build a personal "known-good pcap library". | Explain: how to read a DNS packet capture — 5 fields you check first. Quiz TM 6 Q1–5. Proof: pcap library. | Day 77 tree |
| 79 | Wed 23 Sep | **Tickets 1–8** (TK part 1). | Solve 8 tickets: written diagnosis (cause/proof/fix/red-herring) before opening answers. | Grade per ticket rubric. Proof: ticket log. | Day 78 pcaps |
| 80 | Thu 24 Sep | **Tickets 9–16.** Intermittent failures focus. | Solve 8 tickets, including armed-lab reproductions where marked. | Grade. Proof: ticket log. | Weakest ticket class |
| 81 | Fri 25 Sep | **Tickets 17–24.** Firewall/network-interaction focus. | Solve 8 tickets; for two of them, reproduce in lab with the firewall-simulation technique (file 06). | Grade. Proof: ticket log. | Day 79–80 misses |
| 82 | Sat 26 Sep | **SEPTEMBER CAPSTONE part 1** (file 12): live incident — stale cache + split-horizon leak combined, under 45-min clock, with incident-report template. | Timed incident. | Grade vs rubric. Proof: incident report #1. | — |
| 83 | Sun 27 Sep | **SEPTEMBER CAPSTONE part 2:** report review + retro; rewrite the report to model standard. | Compare vs model report; rewrite. | Retro. Proof: final report. | L6 deck |

## WEEK 13 (Sep 28 – Oct 4) — LEVEL 6: Senior-grade diagnosis

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 84 | Mon 28 Sep | **Tickets 25–30.** Delegation + zone-transfer failures. | Solve 6 tickets. | Grade. Proof: log. | Incident report lessons |
| 85 | Tue 29 Sep | **Tickets 31–35.** EIP-context tickets ("already exists", GUI-vs-dig, bulk gone wrong). | Solve 5 tickets. | Grade. Proof: log. | Day 84 misses |
| 86 | Wed 30 Sep | **Proving a negative: "DNS is fine."** TM 6.3. | Drill: for 3 armed app-side problems (hosts file, pinned IP, app cache), produce the evidence pack that exonerates DNS convincingly. | Explain: the exoneration evidence standard — what an app team can't argue with. Proof: 3 evidence packs. | Day 85 misses |
| 87 | Thu 01 Oct | **Communication under incident: updates, ETAs, TTL honesty.** TM 6.4. | Write the 3 comms artifacts for incident #1: initial ack, mid-incident update, resolution note with negative-TTL caveat. | Explain: why you never promise "fixed now" after a delete. Proof: comms templates (yours). | Day 86 exoneration |
| 88 | Fri 02 Oct | **Tickets 36–40** (senior difficulty). | Solve 5 tickets. | Grade. Proof: log. | Comms templates |
| 89 | Sat 03 Oct | **WEEK 13 EXAM** (Level 6 gate): 2 armed incidents back-to-back, 40 min each. | Timed practicals. | Grade; L6 proof criteria check (≥80% ticket accuracy required). | — |
| 90 | Sun 04 Oct | Retro + ticket-class remediation. | Re-solve every missed ticket class with a fresh variant. | Retro. | L6 deck |

## WEEK 14 (Oct 5–11) — LEVEL 7: Change management mastery (manual discipline)

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 91 | Mon 05 Oct | **The enterprise change lifecycle end-to-end.** TM 7.1 + RB (prepare ticket). | Write a complete change ticket (your real team's format) for a fictional 20-record change: justification, risk, pre/post, rollback, comms. | Explain: what a CAB member needs to approve confidently. Proof: ticket document. | Day 89 incidents |
| 92 | Tue 06 Oct | **Risk classification by record type & blast radius.** TM 7.2. | Build the risk matrix: each change type (add A, delete A, change CNAME target, MX change, NS change, wildcard change...) × risk × mandatory extra checks. | Explain: why an NS or MX change outranks 100 A additions. Quiz TM 7 Q1–5. Proof: risk matrix. | Day 91 ticket |
| 93 | Wed 07 Oct | **TTL choreography for planned changes & migrations.** TM 7.3. | Plan + execute in lab: a zero-user-impact IP change using TTL ramp-down, parallel-run, cutover, restore. | Explain: the timeline math (when to lower TTL relative to window). Proof: choreography log. | Day 92 risk matrix |
| 94 | Thu 08 Oct | **Rollback engineering.** TM 7.4 + RB (rollback). | For 4 change classes, produce the rollback artifact BEFORE the change, then actually roll back in lab and verify state equality with pre-change snapshot. | Explain: rollback ≠ undo — the half-applied-change problem. Proof: 4 rollback demos. | Day 93 TTL plan |
| 95 | Fri 09 Oct | **Full bulk change ceremony, timed.** | 60-row mixed CSV (adds+deletes) executed with full ceremony in 90 min: validate, pre-check, batch-apply, post-check, report. | Explain: what you'd cut under time pressure and what you never cut. Proof: full evidence folder. | Day 94 rollbacks |
| 96 | Sat 10 Oct | **WEEK 14 EXAM** (Level 7 gate): poisoned bulk change under clock — refuse/repair/execute decisions. | Timed practical. | Grade; L7 proof check. | — |
| 97 | Sun 11 Oct | Retro + remediation. | — | Retro. | L7 deck |

## WEEK 15 (Oct 12–18) — LEVEL 8: DNSSEC + transfers security

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 98 | Mon 12 Oct | **DNSSEC theory: keys, RRSIG, DS, chain of trust, NSEC/NSEC3.** TM 8.1. | Paper first: draw the validation chain root→lab zone. Then quiz before touching lab. | Explain A14 + why DS lives at the parent. Quiz TM 8 Q1–6. Proof: chain diagram. | Day 95 ceremony |
| 99 | Tue 13 Oct | **Sign a zone.** TM 8.2. | LAB 14: dnssec-policy sign lab.internal; configure resolver1 with the lab trust anchor; validate with delv ("fully validated"). | Explain: what changed in the zone file and in answers (DO/AD bits, RRSIG). Proof: delv validation output. | Day 98 chain |
| 100 | Wed 14 Oct | **Break DNSSEC + diagnose.** TM 8.3. | LAB 14b: expire signatures (clock jump / stop re-signing) → SERVFAIL; then wrong trust anchor/DS mismatch → SERVFAIL; diagnose each with dig +cd/+dnssec and delv, per C8 method. | Explain C8 with your own captures. Proof: 2 failure diagnosis logs. | Day 99 signing |
| 101 | Thu 15 Oct | **Rollovers & operational DNSSEC.** TM 8.4. | Simulate a ZSK rollover in lab (pre-publish concept via dnssec-policy timing); write the KSK/DS rollover runbook (paper — DS parent step). | Explain: why KSK rollovers are scary and the DS-timing rule. Quiz TM 8 Q7–11. Proof: rollover runbook. | Day 100 failures |
| 102 | Fri 16 Oct | **Transfers + updates security review; TSIG revisited at design level.** TM 8.5. | Audit your whole lab estate: every transfer/update path signed? every ACL least-privilege? Fix gaps; write the audit report. | Explain: your DNS security baseline in 10 bullets you could defend. Proof: audit report. | Day 101 rollover |
| 103 | Sat 17 Oct | **WEEK 15 EXAM.** | Exam + DNSSEC break/fix practical. | Grade. | — |
| 104 | Sun 18 Oct | Retro + remediation. | — | Retro. | DNSSEC deck |

## WEEK 16 (Oct 19–25) — LEVEL 8: Architecture, HA, Anycast, migration

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 105 | Mon 19 Oct | **Reference architectures: hidden primary, resolver tiers, internal/external estates, AD coexistence.** TM 8.6. | Convert lab to hidden-primary topology (primary unlisted in NS, secondaries public-facing); verify clients never touch the primary. | Explain: hidden primary benefits + its failure modes. Quiz TM 8 Q12–16. Proof: topology diagram + NS proof. | Day 102 audit |
| 106 | Tue 20 Oct | **HA: anycast vs VIP vs multi-NS; health & failure behavior.** TM 8.7. | Simulate "two anycast instances diverge" with two resolvers behind one client-side story; write detection method (per-instance monitoring, instance-ID TXT trick). | Explain: why "the resolver IP responds" is not HA health. Proof: divergence detection note. | Day 105 hidden primary |
| 107 | Wed 21 Oct | **GSLB / DNS load balancing basics; monitoring & metrics design.** TM 8.8. | Design the monitoring spec for your lab estate: what to poll, thresholds (SERVFAIL rate, latency, xfer lag, serial spread, expiry margin, cert/sig expiry). | Explain: 5 DNS metrics that predict incidents before users notice. Quiz TM 8 Q17–21. Proof: monitoring spec. | Day 106 anycast |
| 108 | Thu 22 Oct | **Zone migration planning.** TM 8.9 + RB (migrate zone). | Execute a full lab migration of corp.example between servers: TTL ramp, parallel-serve, NS/glue cutover, verification, decommission — evidence at every gate. | Explain: the migration gate checklist and the no-going-back point. Proof: migration evidence folder. | Day 107 monitoring |
| 109 | Fri 23 Oct | **DR: expiry math, restore drills, "primary is gone" playbook.** TM 8.10 + RB (decommission). | Drill: destroy the primary; promote/recover within expiry window; document RTO you achieved; then execute the zone-decommission runbook on a test zone. | Explain: how SOA expire defines your real DR deadline. Proof: DR drill log. | Day 108 migration |
| 110 | Sat 24 Oct | **WEEK 16 EXAM** + Infoblox/EIP/BIND mapping table. | Exam; write the three-platform concept mapping table (TM 8.11 material). | Grade. Proof: mapping table. | — |
| 111 | Sun 25 Oct | Retro + remediation. | — | Retro. | Architecture deck |

## WEEK 17 (Oct 26 – Nov 1) — LEVEL 8 close + OCTOBER CAPSTONE + BASELINE RETAKE

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 112 | Mon 26 Oct | **Design defense prep:** architecture doc for fictional enterprise (from mastery map L8 proof). | Write the full design doc: estate, flows, HA, security, DNSSEC stance, monitoring, change process. | Self-challenge with oral-pack architecture questions. Proof: design doc v1. | Day 109 DR |
| 113 | Tue 27 Oct | **Design defense:** red-team your own doc. | Answer, in writing, the 15 hardest oral-pack architecture/DNSSEC questions against your design; amend the doc. | Proof: Q&A defense record + doc v2. | Design doc |
| 114 | Wed 28 Oct | **Tickets 41–45** (senior). | Solve 5 tickets. | Grade. Proof: log. | Weakest L8 topic |
| 115 | Thu 29 Oct | **Tickets 46–50** (senior). | Solve final 5 tickets. Cumulative ticket accuracy must be ≥80%. | Grade; if <80%, schedule remediation into Week 18 buffer. Proof: final ticket stats. | Day 114 misses |
| 116 | Fri 30 Oct | Consolidation: handbook (file 13) first full read-through with annotations. | Annotate handbook with lab references + your own gotchas. | Proof: annotated handbook v1. | Ticket stats |
| 117 | Sat 31 Oct | **OCTOBER CAPSTONE** (file 12): design review simulation + DNSSEC incident + migration decision, timed. | Timed capstone. | Grade vs rubric. Proof: capstone folder. | — |
| 118 | Sun 01 Nov | **BASELINE EXAM RETAKE** (file 01) — target ≥90 — + retro. | 90-min closed-book retake; compare per-section deltas vs 7 July. | Retro; final weak-topics list for Weeks 18–19. Proof: retake + delta analysis. | — |

## WEEK 18 (Nov 2–8) — LEVEL 9: Final capstone preparation + oral exam

| Day | Date | Topic | Hands-on | Explain + self-test | Review |
|---|---|---|---|---|---|
| 119 | Mon 02 Nov | **Oral exam pack: fundamentals + recursion + caching sections.** | Answer aloud, record, grade against tiers; rework every non-excellent answer. | Proof: section scores. | Retake gaps |
| 120 | Tue 03 Nov | **Oral pack: records/zones/delegation/reverse + TTL.** | Same protocol. | Proof: scores. | Day 119 reworks |
| 121 | Wed 04 Nov | **Oral pack: BIND + EfficientIP sections.** | Same protocol. | Proof: scores. | Day 120 reworks |
| 122 | Thu 05 Nov | **Oral pack: DNSSEC + troubleshooting + change mgmt.** | Same protocol. | Proof: scores. | Day 121 reworks |
| 123 | Fri 06 Nov | **Oral pack: migration + architecture** + full weak-answer second pass. | Same protocol; any question still below "excellent" gets a written model answer in your own words. | Proof: final oral scores (target ≥80% excellent). | All reworks |
| 124 | Sat 07 Nov | **Final capstone dress rehearsal:** rebuild the entire lab estate from scratch, from your own docs only, timed. | Full estate rebuild ≤ 2.5 h. | Grade rebuild completeness. Proof: rebuild log. | — |
| 125 | Sun 08 Nov | Retro + buffer: fix anything the rehearsal exposed; remediation of any <80% areas. | — | Retro. | Everything flagged |

## WEEK 19 (Nov 9–15) — LEVEL 9: FINAL ENTERPRISE CAPSTONE

| Day | Date | Component (file 12 defines each fully) | Time-box | Proof |
|---|---|---|---|---|
| 126 | Mon 09 Nov | **Capstone C1 — Enterprise change:** 40-record mixed change with ticket, ceremony, evidence, comms. | 2 h | Change evidence folder |
| 127 | Tue 10 Nov | **Capstone C2 — Stale-cache incident** (armed): diagnose, fix, report. | 45 min incident + 45 min report | Incident report |
| 128 | Wed 11 Nov | **Capstone C3 — Delegation failure + C4 — BIND config fault** (armed, back-to-back). | 45 min each | 2 diagnosis logs |
| 129 | Thu 12 Nov | **Capstone C5 — Bulk operation** (poisoned CSV, EIP-style workflow): refuse/repair/execute + rollback artifact. | 2 h | Bulk evidence folder |
| 130 | Fri 13 Nov | **Capstone C6 — Senior design review:** defend your architecture doc against the hostile-question script; **C7 — rollback plan** for a failed migration scenario. | 2 h | Defense record + rollback plan |
| 131 | Sat 14 Nov | **Capstone C8 — Written incident report** (composite scenario) + full capstone self-grading vs rubric. | 2 h | Final report + scorecard |
| 132 | Sun 15 Nov | **Program close:** final retrospective; handbook final annotation; write your "continuing plan" per file 14 §10 (post-program maintenance loop). | 2 h | Completion dossier |

---

### Standing rules
1. **Missed a day?** The next day is 3 h: 1 h catch-up + normal block. Two missed days = weekend becomes full make-up. The 15 Nov date does not move.
2. **Weekly exam <85%** → Sunday is remediation, and the failed topics re-appear as the Review column for the next 5 days.
3. **Never advance past a level gate** (Weeks 2, 7, 9, 11, 13, 14 exams) without meeting the mastery-map proof criteria — even if the calendar says move on. Compress later lesson time, not proof.
4. Every proof artifact goes in `dns-journal/proofs/` named `DDD-topic.ext` (e.g., `023-reverse-mismatch.txt`). On 15 Nov you should have 130+ artifacts. That folder *is* your evidence you did the work.
