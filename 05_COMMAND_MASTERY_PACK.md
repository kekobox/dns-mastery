# SECTION 6 — COMMAND MASTERY PACK
### Packet 3b — Tools, outputs, flags, and proof techniques
Drill target: by Week 7 every technique here is reflex — you type it while
thinking about the *problem*, not the syntax.

---

## 1. dig — the primary instrument

**Purpose:** ask exactly the question you mean, to exactly the server you
mean, and read the entire response.

**Core syntax:** `dig [@server] name [type] [+options]`

**Options you must own:**
| Option | Effect / when |
|---|---|
| `@172.20.0.53` | choose the server — the single most important habit; no @ = your system resolver, an uncontrolled variable |
| `+norecurse` | RD=0 — cache X-ray against resolvers; referral view against authorities |
| `+trace` | dig iterates itself from root — shows the public/lab tree, NOT your resolver's view |
| `+tcp` | force TCP — truncation/fragment/firewall bisection |
| `+bufsize=N` / `+noedns` | EDNS size games — transport matrix |
| `+dnssec` | set DO — request RRSIGs; watch for `ad` |
| `+cd` | checking disabled — "give me the data even if bogus" — THE DNSSEC bisector |
| `+short` | answer only — for scripts/eyeballs, never for diagnosis |
| `+noall +answer +comments` | compact but keeps rcode/flags |
| `+qr` | print the query too — see what you actually sent (suffix surprises) |
| `-x 10.10.20.15` | reverse lookup — builds the in-addr.arpa name for you |
| `AXFR` | as type: attempt zone transfer — `dig @auth corp.example AXFR` |
| `+multiline` | readable SOA/DNSKEY |
| `+time=2 +retry=1` | fail fast when probing suspected-dead servers |

**Good output (recursive answer):**
```
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4711
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; ANSWER SECTION:
app1.corp.example. 212 IN A 10.10.20.15
;; SERVER: 172.20.0.53#53
```
Read order: **status → flags → counts → answer → TTL → SERVER**. Here:
success; response; recursion requested and available; no `aa` ⇒ resolver;
TTL below zone value ⇒ cached; and confirm you asked whom you meant.

**Good output (authoritative):** `flags: qr aa rd` (ra usually absent), TTL
at full zone value every time.

**Bad outputs and their meaning:**
- `status: NXDOMAIN` + SOA in AUTHORITY → name doesn't exist per that server
  (note the SOA — that's your negative-TTL clock).
- `status: NOERROR, ANSWER: 0` + SOA → NODATA (name exists, type doesn't).
- `status: SERVFAIL` → the server tried and failed (recursion broken,
  zone broken/expired, DNSSEC bogus). Retry with `+cd`: works ⇒ DNSSEC class.
- `status: REFUSED` → policy: ACL/view/not-my-zone-and-no-recursion.
- `;; connection timed out; no servers could be reached` → nothing answered:
  network/firewall/dead — dig never even got a DNS-level response.
- `;; Truncated, retrying in TCP mode` → normal; a problem only if the TCP
  leg then fails.
- `;; WARNING: recursion requested but not available` → you asked a
  non-recursing server to recurse — expected against pure authorities.

## 2. Proof techniques (the section to over-learn)

**Prove an answer is AUTHORITATIVE:** `dig @<server> name type` shows `aa`
AND the server is listed in the zone's NS (or is your known hidden primary).
`aa` from the horse's mouth + full TTL on repeat queries = zone truth.

**Prove an answer is CACHED:** no `aa`, and TTL decreases across two queries
a few seconds apart to the *same node*. Bonus proof: `+norecurse` still
returns it (it's in cache), and `rndc dumpdb -cache` shows the entry.

**Prove WHERE stale data lives:** ladder method — same question to
(1) authoritative, (2) each resolver node directly (bypass VIP),
(3) the client cache (`Get-DnsClientCache` / `resolvectl query`).
The deepest layer still showing old data owns the staleness.

**Follow recursion manually (what +trace automates):**
```
dig @172.20.0.2  app1.corp.example +norecurse     # root → referral to example.
dig @172.20.0.3  app1.corp.example +norecurse     # TLD  → referral to corp.example
dig @172.20.0.10 app1.corp.example +norecurse     # auth → aa answer
```
Do this by hand until the referral chain is muscle memory — it is the
skeleton of every delegation diagnosis.

**Prove a delegation healthy:** parent's view
`dig NS child @parent +norecurse` → then `dig SOA child @every-listed-NS
+norecurse` expecting `aa` from each. Any listed server not `aa` = lame.

**Prove the negative-cache clock:** on NXDOMAIN, read the SOA TTL in
AUTHORITY — that value (counting down on a resolver) is exactly how long the
"no" persists.

**Flag interpretation table (commit to memory):**
| Flags seen | Meaning |
|---|---|
| `qr aa rd` | authoritative answer (rd merely echoed) |
| `qr rd ra` | recursive/cached answer |
| `qr rd ra ad` | recursive answer, DNSSEC-validated by that resolver |
| `qr rd ra cd` | validation was bypassed on request — data may be bogus |
| `qr rd` (no ra, no aa) | server neither owns it nor offers recursion — check REFUSED/referral; you're talking to the wrong box |
| `qr ra tc` | grab the TCP retry; judge nothing from a truncated body |

## 3. nslookup — for Windows fluency and translation

**Purpose:** ubiquitous on Windows; you must read its dialect fluently
because tickets arrive written in it.
**Syntax:** `nslookup name [server]`; interactive: `nslookup` →
`server 172.20.0.53` → `set type=MX` → `name`. `set debug` ≈ dig's full view.
`set norecurse`, `set vc` (TCP) exist and mirror dig options.
**Good:** `Server/Address` header (who answered) then `Non-authoritative
answer:` + records — that label is NORMAL for resolver answers, not an error.
**Bad:** `*** server can't find name: NXDOMAIN` (or SERVFAIL/REFUSED — it
does print the rcode); `DNS request timed out`.
**Traps:** it prints the resolver from reverse-lookup of its IP (an
unrelated PTR failure makes the header look broken); querying default server
when you meant a specific one; older habit `set type=any` gives modern
minimal/refused ANY answers — never diagnose with ANY.

## 4. host — the quick glance
`host name [server]`, `host -t MX corp.example`, `host 10.10.20.15`
(reverse), `host -a` (≈ dig +all). Purpose: terse existence checks in loops;
switch to dig the moment anything needs *interpretation* — host hides flags.

## 5. delv — the DNSSEC verdict tool
**Purpose:** dig that validates: fetches AND runs the full DNSSEC chain
logic, then tells you the verdict in words.
`delv @172.20.0.53 srv1.lab.internal A` (add `-a keyfile +root=zone` for
lab anchors).
**Good:** `; fully validated` above the records.
**Bad:** `; unsigned answer` (no DNSSEC — fine if expected) or
`;; resolution failed: SERVFAIL` with `broken trust chain` /
`no valid RRSIG` / `signature expired` — delv NAMES the failure that plain
dig only shows as SERVFAIL. Use in every DNSSEC ticket after the dig/+cd
bisection.

## 6. rndc — driving BIND
**Purpose:** control channel to named (port 953, key-authenticated —
the container images pre-wire a local key).
| Command | Use |
|---|---|
| `rndc status` | is named up; zone count; is it *this* config |
| `rndc reload [zone]` | apply edits (zone reload only re-reads that zone file) |
| `rndc reconfig` | re-read named.conf, load NEW zones only — faster, doesn't reload changed zone files |
| `rndc flush` / `flushname N` / `flushtree N` | cache surgery (resolver role) |
| `rndc dumpdb -cache` | write cache to dump file for inspection |
| `rndc querylog on\|off` | toggle query logging live |
| `rndc retransfer zone` | force full transfer on a secondary NOW |
| `rndc refresh zone` | trigger SOA check on a secondary |
| `rndc freeze zone` / `thaw zone` | safe hand-edit window for dynamic zones |
| `rndc zonestatus zone` | serial, type, next refresh, dynamic? — first stop in replication issues |
**Bad output:** `rndc: connect failed: 127.0.0.1#953: connection refused` →
named down or controls/key mismatch — settle it with `named-checkconf` +
process check before touching DNS-level theories.

## 7. named-checkconf / named-checkzone — the pre-commit gate
`named-checkconf /etc/bind/named.conf` — silence = pass; else
`file:line: error` (missing `;`, unknown option, bad ACL ref).
`named-checkconf -z` additionally loads every zone = full estate lint.
`named-checkzone corp.example /etc/bind/db.corp.example` —
**Good:** `zone corp.example/IN: loaded serial 2026070701  OK`.
**Bad examples you'll deliberately produce on Day 18:**
`ignoring out-of-zone data`, `CNAME and other data`, `NS record without
address (glue)`, `no serial number`, `not at top of zone`.
**Law:** these two run BEFORE every reload, every time, forever. A senior
who reloads unchecked configs on a production resolver is not a senior.

## 8. tcpdump (and Wireshark reading)
**Purpose:** when DNS-level tools disagree with reality, the wire settles it.
**Capture recipes:**
```
tcpdump -ni any port 53                      # everything DNS
tcpdump -ni any 'udp port 53'                # queries/answers only
tcpdump -ni any 'tcp port 53'                # transfers/truncation retries
tcpdump -ni any 'port 53 and host 172.20.0.10'
tcpdump -ni any -w /tmp/dns.pcap port 53     # save for Wireshark
```
tcpdump prints DNS summaries natively:
`A? app1.corp.example.` (query) → `1/0/1 A 10.10.20.15 (73)` = answer/
authority/additional counts + rdata; `NXDomain 0/1/0` = negative with SOA;
`ServFail`; `[|domain]` = truncated print (raise `-s 0`).
**The five things to check first in any DNS capture:** (1) did the query
leave? (2) did anything come back? (3) rcode of what came back, (4) UDP or
TCP leg failing, (5) who is the *actual* server IP (vs who you think).
**Timeout bisection:** capture on client AND server simultaneously — query
absent at server = eaten toward them (firewall/route); present at server
with reply sent but absent at client = return path. This one technique
closes every "DNS works from subnet A not B" ticket.

## 9. PowerShell Resolve-DnsName — the Windows dig
| Task | Command |
|---|---|
| Basic | `Resolve-DnsName app1.corp.example` |
| Choose server | `-Server 172.20.0.53` |
| Skip client cache & hosts file | `-DnsOnly` (add `-NoHostsFile` to be explicit) |
| Type | `-Type MX` / `SOA` / `PTR` / `TXT` |
| Reverse | `Resolve-DnsName 10.10.20.15` (auto-PTR) |
| TCP | `-TcpOnly` |
| DNSSEC data | `-DnssecOk` |
**Good:** typed objects (Name/Type/TTL/IPAddress). **Bad:**
`... : DNS name does not exist` (NXDOMAIN) / `DNS server failure`
(SERVFAIL) / timeouts. **Trap:** WITHOUT `-Server`, results may come from
the local cache and suffix expansion — for diagnosis, `-Server` + `-DnsOnly`
always. Note there's no `aa`-flag display — for authority proof from
Windows, target the auth server explicitly and rely on TTL behavior, or use
dig in WSL for flag-level work.

## 10. Client cache tools
**Windows:** `ipconfig /displaydns` (dump incl. negative entries — look for
"Name does not exist" entries), `ipconfig /flushdns`,
`Get-DnsClientCache | ? Entry -like '*app1*'`, `Clear-DnsClientCache`,
`Get-DnsClientServerAddress`, `Get-DnsClientNrptPolicy`,
`Get-DnsClient | fl InterfaceAlias,ConnectionSpecificSuffix*`.
**Linux/systemd-resolved:** `resolvectl status` (per-link servers +
routing domains), `resolvectl query name` (which link/protocol answered),
`resolvectl statistics` (cache hits), `resolvectl flush-caches`,
`getent hosts name` (the app's-eye view). Non-resolved distros: nscd/sssd
caches exist — `systemctl restart nscd` equivalent; check what's actually
running before declaring "Linux has no client cache."

## 11. The interrogation ladder (pin above your desk)
For ANY "name X resolves wrong/not at all for client C":
```
1. WHAT exactly: Resolve-DnsName X -DnsOnly (on C)      → exact FQDN + rcode
2. CLIENT cache:  Get-DnsClientCache X / resolvectl      → stale here?
3. RESOLVER(S):   dig @each-resolver-node X              → per-node truth
4. AUTHORITATIVE: dig @auth X  (expect aa)               → zone truth
5. DELEGATION:    dig NS zone @parent +norecurse         → parent's pointers
6. TRANSPORT:     +tcp / +bufsize matrix / tcpdump       → if timeouts/large
7. DNSSEC:        +cd then delv                          → if SERVFAIL
```
The layer where the answer first goes wrong owns the incident. Everything in
this program is ultimately practice at running this ladder fast and reading
each rung honestly.
