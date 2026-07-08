# SECTION 7 — LAB ENVIRONMENT
### Packet 2a — Docker/WSL BIND estate + all labs (LAB 0–14 + fault library)

The lab is a **miniature internet**: your own root server, your own TLD server,
enterprise authoritative servers, and a corporate recursive resolver. This is
deliberate — it makes `+trace`, referrals, glue, and delegation *real* instead
of theoretical, entirely offline and legal.

## 0. TOPOLOGY

```
Docker network dnslab: 172.20.0.0/16   (clients: WSL + Windows host)

  root1      172.20.0.2    authoritative for "."          (fake root)
  tld1       172.20.0.3    authoritative for example. / internal. / net.
  auth1      172.20.0.10   PRIMARY: corp.example, example.net, lab.internal,
                           20.10.10.in-addr.arpa, 50.168.192.in-addr.arpa
  auth1sec   172.20.0.11   SECONDARY of auth1            (added Week 8, LAB 10)
  auth2      172.20.0.20   authoritative: dev.corp.example (added Week 4, LAB 3)
  auth-ext   172.20.0.30   "external" authoritative       (added Week 6)
  resolver1  172.20.0.53   corporate recursive resolver (root hints → root1)
  fwd1       172.20.0.63   forwarding resolver            (added Week 6, LAB 7)
```
Record data uses fictional service space **10.10.0.0/16** and
**192.168.50.0/24** — these IPs never need to be reachable; DNS answers are
the product, not connectivity.

## 1. DIRECTORY LAYOUT (create in WSL, e.g. ~/dnslab)

```
dnslab/
  docker-compose.yml
  root1/named.conf   root1/db.root
  tld1/named.conf    tld1/db.example  tld1/db.internal  tld1/db.net
  auth1/named.conf   auth1/db.corp.example  auth1/db.example.net
                     auth1/db.lab.internal  auth1/db.10.10.20  auth1/db.192.168.50
  auth2/named.conf   auth2/db.dev.corp.example
  resolver1/named.conf  resolver1/db.root-hints
  # added later: auth1sec/ auth-ext/ fwd1/
```

## 2. DOCKER COMPOSE (base estate — LAB 0/1)

```yaml
# docker-compose.yml
name: dnslab
networks:
  dnslab:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

x-bind: &bind
  image: internetsystemsconsortium/bind9:9.18
  restart: unless-stopped
  command: ["-g", "-c", "/etc/bind/named.conf"]   # -g = foreground, log to stderr

services:
  root1:
    <<: *bind
    container_name: root1
    networks: { dnslab: { ipv4_address: 172.20.0.2 } }
    volumes: [ "./root1:/etc/bind:ro" ]
  tld1:
    <<: *bind
    container_name: tld1
    networks: { dnslab: { ipv4_address: 172.20.0.3 } }
    volumes: [ "./tld1:/etc/bind:ro" ]
  auth1:
    <<: *bind
    container_name: auth1
    networks: { dnslab: { ipv4_address: 172.20.0.10 } }
    volumes: [ "./auth1:/etc/bind" ]        # rw: dynamic updates later
  resolver1:
    <<: *bind
    container_name: resolver1
    networks: { dnslab: { ipv4_address: 172.20.0.53 } }
    volumes: [ "./resolver1:/etc/bind:ro" ]
    ports: [ "5353:53/udp", "5353:53/tcp" ]  # reach from Windows host: -Server 127.0.0.1 -Port… or use WSL IPs directly
```

**Client access:** from WSL, query container IPs directly (`dig @172.20.0.53 …`)
— Docker Desktop's WSL integration routes this. From Windows PowerShell, either
`Resolve-DnsName name -Server 127.0.0.1` after mapping port 53 (change `5353` to
`53` if nothing on the host uses 53), or query via WSL. If 172.20.x isn't
reachable from WSL in your setup, add published ports per container
(e.g. `15310:53` for auth1) and query `@127.0.0.1 -p 15310`. Document which
method works on your machine on Day 2 and use it consistently.

## 3. CONFIGS & ZONES (base estate)

### root1/named.conf
```
options {
  directory "/var/cache/bind";
  recursion no;
  allow-query { any; };
  listen-on { any; }; listen-on-v6 { none; };
  dnssec-validation no;
};
zone "." { type primary; file "/etc/bind/db.root"; };
```

### root1/db.root  — the fake root zone
```
$TTL 3600
.            IN SOA ns.root. admin.root. ( 2026070701 3600 900 604800 3600 )
.            IN NS  ns.root.
ns.root.     IN A   172.20.0.2

; TLD delegations + glue
example.     IN NS  ns.tld.
internal.    IN NS  ns.tld.
net.         IN NS  ns.tld.
ns.tld.      IN A   172.20.0.3
tld.         IN NS  ns.tld.        ; makes ns.tld. formally delegated too
```

### tld1/named.conf
```
options {
  directory "/var/cache/bind";
  recursion no; allow-query { any; };
  listen-on { any; }; listen-on-v6 { none; };
  dnssec-validation no;
};
zone "example"  { type primary; file "/etc/bind/db.example"; };
zone "internal" { type primary; file "/etc/bind/db.internal"; };
zone "net"      { type primary; file "/etc/bind/db.net"; };
zone "tld"      { type primary; file "/etc/bind/db.tld"; };
```

### tld1/db.example
```
$TTL 3600
@                 IN SOA ns.tld. admin.tld. ( 2026070701 3600 900 604800 3600 )
@                 IN NS  ns.tld.
; delegation of corp.example to the enterprise, WITH glue (in-bailiwick NS)
corp              IN NS  ns1.corp.example.
ns1.corp          IN A   172.20.0.10
```

### tld1/db.internal
```
$TTL 3600
@                 IN SOA ns.tld. admin.tld. ( 2026070701 3600 900 604800 3600 )
@                 IN NS  ns.tld.
lab               IN NS  ns1.lab.internal.
ns1.lab           IN A   172.20.0.10
```

### tld1/db.net
```
$TTL 3600
@                 IN SOA ns.tld. admin.tld. ( 2026070701 3600 900 604800 3600 )
@                 IN NS  ns.tld.
example           IN NS  ns1.example.net.
ns1.example       IN A   172.20.0.10
```

### tld1/db.tld
```
$TTL 3600
@       IN SOA ns.tld. admin.tld. ( 2026070701 3600 900 604800 3600 )
@       IN NS  ns.tld.
ns      IN A   172.20.0.3
```

### auth1/named.conf
```
options {
  directory "/var/cache/bind";
  recursion no;                 // pure authoritative — best practice
  allow-query { any; };
  allow-transfer { none; };     // opened properly in LAB 10/11
  listen-on { any; }; listen-on-v6 { none; };
  dnssec-validation no;
};
zone "corp.example"            { type primary; file "/etc/bind/db.corp.example"; };
zone "example.net"             { type primary; file "/etc/bind/db.example.net"; };
zone "lab.internal"            { type primary; file "/etc/bind/db.lab.internal"; };
zone "20.10.10.in-addr.arpa"   { type primary; file "/etc/bind/db.10.10.20"; };
zone "50.168.192.in-addr.arpa" { type primary; file "/etc/bind/db.192.168.50"; };
```

### auth1/db.corp.example  — the enterprise forward zone (grows during Weeks 3–4)
```
$TTL 300
$ORIGIN corp.example.
@        IN SOA ns1.corp.example. hostmaster.corp.example. (
             2026070701 ; serial  — INCREMENT ON EVERY CHANGE
             3600       ; refresh
             900        ; retry
             604800     ; expire
             900 )      ; minimum = NEGATIVE-CACHE TTL
@        IN NS   ns1.corp.example.
ns1      IN A    172.20.0.10

; --- core service records ---
app1     IN A    10.10.20.15
app2     IN A    10.10.20.16
db1      IN A    10.10.20.30
portal   IN A    10.10.40.10
www      IN CNAME portal.corp.example.

; --- mail set (added Day 16) ---
@        IN MX   10 mail.corp.example.
mail     IN A    10.10.20.25
@        IN TXT  "v=spf1 mx ip4:10.10.20.25 -all"
sel1._domainkey IN TXT ( "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A"
                          "MIIBCgKCAQEAlongfakekeymateriallongfakekeymaterial" )
_dmarc   IN TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@corp.example"

; --- service discovery + policy (added Day 17) ---
_ldap._tcp IN SRV 0 5 389 dc1.corp.example.
dc1      IN A    10.10.20.40
@        IN CAA  0 issue "letsencrypt.org"
*.apps   IN A    10.10.60.100

; --- delegation of dev.corp.example (added Day 21, LAB 3) ---
;dev     IN NS   ns1.dev.corp.example.
;ns1.dev IN A    172.20.0.20
```

### auth1/db.example.net
```
$TTL 3600
$ORIGIN example.net.
@    IN SOA ns1.example.net. hostmaster.example.net. ( 2026070701 3600 900 604800 3600 )
@    IN NS  ns1.example.net.
ns1  IN A   172.20.0.10
www  IN A   10.10.90.80
```

### auth1/db.lab.internal
```
$TTL 300
$ORIGIN lab.internal.
@     IN SOA ns1.lab.internal. hostmaster.lab.internal. ( 2026070701 3600 900 604800 900 )
@     IN NS  ns1.lab.internal.
ns1   IN A   172.20.0.10
srv1  IN A   192.168.50.10
srv2  IN A   192.168.50.11
```

### auth1/db.10.10.20  (reverse for 10.10.20.0/24 — LAB 4, Day 23)
```
$TTL 300
$ORIGIN 20.10.10.in-addr.arpa.
@    IN SOA ns1.corp.example. hostmaster.corp.example. ( 2026070701 3600 900 604800 900 )
@    IN NS  ns1.corp.example.
15   IN PTR app1.corp.example.
16   IN PTR app2.corp.example.
25   IN PTR mail.corp.example.
30   IN PTR db1.corp.example.
40   IN PTR dc1.corp.example.
```

### auth1/db.192.168.50  (LAB 4)
```
$TTL 300
$ORIGIN 50.168.192.in-addr.arpa.
@    IN SOA ns1.lab.internal. hostmaster.lab.internal. ( 2026070701 3600 900 604800 900 )
@    IN NS  ns1.lab.internal.
10   IN PTR srv1.lab.internal.
11   IN PTR srv2.lab.internal.
```

### resolver1/named.conf
```
options {
  directory "/var/cache/bind";
  recursion yes;
  allow-recursion { 172.20.0.0/16; 127.0.0.1; 10.0.0.0/8; 192.168.0.0/16; };
  allow-query     { any; };
  listen-on { any; }; listen-on-v6 { none; };
  dnssec-validation no;      // switched on in Week 15
};
zone "." { type hint; file "/etc/bind/db.root-hints"; };
```

### resolver1/db.root-hints
```
.          3600000 IN NS ns.root.
ns.root.   3600000 IN A  172.20.0.2
```

**Note on 10.in-addr.arpa / 192.168 reverse via recursion:** resolver1 walks
root→net/…, but reverse zones for RFC1918 aren't delegated in your fake root.
On Day 23 you add to tld1 a fake `arpa.` chain OR (simpler, and the enterprise-
realistic pattern) add **static-stub/forward zones** on resolver1:
```
zone "20.10.10.in-addr.arpa"   { type static-stub; server-addresses { 172.20.0.10; }; };
zone "50.168.192.in-addr.arpa" { type static-stub; server-addresses { 172.20.0.10; }; };
```
This mirrors real enterprises: internal reverse space is routed to internal
auth servers explicitly, never via the public tree. Explain that in your Day 23
journal — it's a senior talking point.

---

## LAB 0 (Day 2) — Smoke test
**Goal:** Docker network up, one BIND answers.
**Do:** create layout §1 with only root1 files; `docker compose up -d root1`;
`dig @172.20.0.2 . NS +norecurse`.
**Expected:** `status: NOERROR`, `flags: qr aa`, ANSWER `. NS ns.root.`
**Troubleshoot Q:** why is `aa` set? *(A: root1 is authoritative for ".".)*
Why no `ra`? *(A: recursion no — correct for authoritative.)*
**Cleanup:** none — this stays up for 132 days.

## LAB 1 (Day 5) — Core estate
**Goal:** full cold-cache recursion through YOUR root.
**Do:** deploy all §2 services. Validate configs first:
`docker exec auth1 named-checkconf /etc/bind/named.conf`
`docker exec auth1 named-checkzone corp.example /etc/bind/db.corp.example`
Then: `dig @172.20.0.53 app1.corp.example` (twice), `dig @172.20.0.10 app1.corp.example`,
`dig @172.20.0.53 app1.corp.example +trace`.
**Expected:** resolver answer: `qr rd ra`, no `aa`, TTL 300 then decrementing on
the second query. Auth answer: `qr aa`, TTL always 300. `+trace` shows
`. NS ns.root.` → `corp.example NS ns1.corp.example` referrals.
**Troubleshoot Qs:** (1) resolver returns SERVFAIL — first check?
*(A: can resolver reach root1: `dig @172.20.0.2 . NS` from inside resolver1
container: `docker exec resolver1 dig @172.20.0.2 . NS`; then hints file
content.)* (2) `+trace` works but plain query fails — meaning?
*(A: dig itself can iterate; resolver1's recursion/ACL/hints are the problem.)*
**Cleanup:** none.

## LAB 2 (Day 7) — Truncation & EDNS
**Goal:** see TC=1 and the TCP retry live.
**Do:** add to db.corp.example a fat record set:
`bigtxt IN TXT "AAAA…(~250 chars)"` × 8 lines (same name, 8 strings/records);
bump serial; `docker exec auth1 rndc reload corp.example` (or restart).
Then: `dig @172.20.0.10 bigtxt.corp.example TXT +noedns +ignore` (see TC, no
retry), `+noedns` (watch dig retry TCP), `+bufsize=512`, default (EDNS 1232),
`+tcp`. Capture: `docker exec resolver1 tcpdump -ni any port 53 -c 40` during
a resolver query.
**Expected:** `+noedns +ignore` → `flags: … tc`; default EDNS → fits (or TC
depending on size — record which); `+tcp` always complete.
**Qs:** why did classic DNS truncate at 512? what does EDNS advertise and who
advertises it? *(A: 512-byte UDP limit pre-EDNS; the CLIENT advertises its
buffer size in the OPT record.)*
**Cleanup:** keep bigtxt — reused in LAB 9.

## LAB 3 (Day 21) — Delegation with glue
**Goal:** working parent→child delegation.
**Do:** add auth2 service to compose (copy auth1 block, IP .20, dir auth2/).
auth2/named.conf: authoritative-only, zone `dev.corp.example` →
db.dev.corp.example:
```
$TTL 300
$ORIGIN dev.corp.example.
@     IN SOA ns1.dev.corp.example. hostmaster.corp.example. ( 2026070701 3600 900 604800 900 )
@     IN NS  ns1.dev.corp.example.
ns1   IN A   172.20.0.20
build IN A   10.10.70.5
```
Uncomment the two delegation lines in db.corp.example, bump serial, reload auth1.
Test: `dig @172.20.0.53 build.dev.corp.example`, then
`dig @172.20.0.10 build.dev.corp.example +norecurse` (parent gives REFERRAL:
empty answer, AUTHORITY = NS dev…, ADDITIONAL = glue).
**Expected:** resolver resolves; parent shows referral not answer.
**Qs:** why must `ns1.dev A 172.20.0.20` exist in the PARENT zone? *(A: glue —
in-bailiwick NS; without it, circular dependency.)* Is the glue authoritative
data of corp.example? *(A: no — glue is non-authoritative hint data below the
zone cut; the child's own ns1 A record is the authoritative one.)*
**Cleanup:** none.

## LAB 3b (Day 22) — Lame delegation, 3 breaks
Arm each, flush resolver (`docker exec resolver1 rndc flush`), diagnose from
symptoms before peeking:
1. **NS→dead server:** change glue to 172.20.0.99, serial++, reload.
   *Symptom: timeout→SERVFAIL at resolver. Proof: `dig @172.20.0.99` no route;
   parent referral shows the bad glue.*
2. **NS→server without zone:** point delegation glue at 172.20.0.10 but name
   ns1.dev (auth1 doesn't host dev zone). *Symptom: REFUSED/SERVFAIL; proof:
   `dig @172.20.0.10 build.dev.corp.example +norecurse` → REFUSED (not
   authoritative, recursion off).* This is the classic lame delegation.
3. **Missing glue:** delete `ns1.dev IN A` from parent, keep NS line.
   *Symptom: SERVFAIL; proof: parent referral has empty ADDITIONAL; resolver
   cannot learn ns1.dev's address.* (named-checkzone will also warn.)
**Restore** the correct delegation after each. Save the three symptom captures.

## LAB 4 (Day 23) — Reverse zones
**Goal:** PTRs resolving; a mismatch detected.
**Do:** zones already in auth1 config; add the static-stub blocks to resolver1
(§3 note), restart resolver1. Test `dig @172.20.0.53 -x 10.10.20.15`.
Arm mismatch: change `16 IN PTR app2…` to `16 IN PTR old-db.corp.example.`,
serial++, reload. Detect: compare `dig -x 10.10.20.16` vs
`dig old-db.corp.example A` (NXDOMAIN → orphan PTR).
**Expected:** `-x` returns PTR names; mismatch produces forward/reverse
disagreement you can articulate (baseline C2).
**Q:** why doesn't BIND stop you creating an orphan PTR? *(A: forward and
reverse are independent zones; nothing in the protocol links them — only
process/IPAM does.)*
**Cleanup:** restore correct PTR.

## LAB 5 (Day 29) — Negative caching measured
**Goal:** measure NXDOMAIN persistence exactly.
**Do:** `dig @172.20.0.53 ghost.corp.example` (NXDOMAIN — note SOA TTL in
AUTHORITY = 900). Immediately add `ghost IN A 10.10.20.99`, serial++, reload
auth1. Loop: `watch -n10 dig @172.20.0.53 ghost.corp.example +noall +answer +comments`.
Time until NOERROR. Repeat after lowering SOA minimum (and SOA TTL) to 60.
Targeted purge instead of waiting: `docker exec resolver1 rndc flushname ghost.corp.example`.
**Expected:** persistence ≈ min(SOA minimum, SOA record TTL) from the moment
the negative answer was cached.
**Qs:** why does auth answer correctly immediately while resolver doesn't?
Which SOA field(s) governed the wait? *(A: negative entry lives in resolver
cache; min of SOA TTL and MINIMUM per RFC 2308.)*
**Cleanup:** remove ghost, restore SOA values, serial++.

## LAB 6 (Day 30) — Stale cache / change propagation
**Goal:** the C1 timeline reproduced with timestamps.
**Do:** ensure app2=10.10.20.16 cached at resolver AND in Windows cache
(query from PowerShell). Change app2 → 10.10.30.16 at auth1, serial++, reload.
Record a table: T+0 auth answer / resolver answer / `Get-DnsClientCache app2*`;
repeat each minute until all three agree. Then re-arm and instead fix fast:
`rndc flushname app2.corp.example` + `Clear-DnsClientCache`.
**Variants for Day 32 drill:** stale only at client (flush resolver, not client);
stale only at resolver; stale at a *forwarder* (after LAB 7 exists).
**Q:** why did the resolver serve old data with TTL 180 while auth already
answered new? *(A: TTL contract — cache is honoring the old RRset until expiry;
this is correct behavior, not a fault.)*
**Cleanup:** decide final IP, make all layers consistent.

## LAB 7 (Day 35) + 7b (Day 36) — Forwarding
**Do:** add fwd1 (IP .63): named.conf options as resolver1 but:
```
recursion yes;
forwarders { 172.20.0.53; };
forward only;
```
No hint zone needed (forward only). Enable query logging on BOTH
(`rndc querylog on`, watch `docker logs -f`). Query fwd1 from WSL; trace the
two-hop path in both logs; query again — observe fwd1 answering from ITS cache
(resolver1 log silent).
**7b conditional:** on fwd1 add
`zone "dev.corp.example" { type forward; forward only; forwarders { 172.20.0.20; }; };`
Prove dev queries bypass resolver1 (its log stays silent) — but note auth2 has
`recursion no`, so plain-forwarding to a pure auth server works only for names
it's authoritative for; discuss why `type static-stub` is the cleaner tool here
and test it too.
**Failure drills (Day 37):** stop resolver1 → fwd1 SERVFAIL (forward only) —
compare with `forward first` (needs hints to fall back — add and observe);
wrong ACL on resolver1 (`allow-recursion` excluding .63) → fwd1 gets REFUSED
upstream → surfaces as SERVFAIL to client; network drop (pause container:
`docker pause resolver1`) → timeout then SERVFAIL. Capture all three
signatures.
**Cleanup:** unpause, restore ACLs.

## LAB 8 (Day 39) + 8b (Day 40) — Split-horizon views
**Goal:** one server, two truths.
**Do:** create auth-ext (IP .30) OR (view method, the lesson target) convert
auth1 config to views:
```
acl internal-nets { 172.20.0.0/16; 10.0.0.0/8; };
view "internal" {
  match-clients { internal-nets; };
  zone "corp.example" { type primary; file "/etc/bind/db.corp.example"; };
  /* + other internal zones */
};
view "external" {
  match-clients { any; };
  zone "corp.example" { type primary; file "/etc/bind/db.corp.example.ext"; };
};
```
db.corp.example.ext: minimal public zone — portal → 203.0.113.40, MX, SPF only.
Test from an "external" client: run a throwaway container on a second docker
network (or `dig` from a container whose IP you exclude from internal-nets by
narrowing the ACL to specific IPs).
**Expected:** portal answers 10.10.40.10 internally, 203.0.113.40 externally.
**8b — the leak:** narrow internal ACL so your test client falls through to
external view. Symptom: internal client suddenly gets 203.0.113.40. Diagnose
cold: prove which view answered (add a marker TXT `whichview IN TXT "internal"`
/ `"external"` in each zone file — a real production trick).
**Qs:** what decides view selection? *(A: first view whose match-clients
matches the SOURCE address — order matters.)* Name two real-world leak causes.
*(A: new subnet/NAT not in ACL; client using an external resolver/DoH.)*
**Cleanup:** keep views — they're now permanent estate.

## LAB 9 (Day 42) — EDNS/fragmentation matrix
Reuse bigtxt (grow it to ~3 KB total). Matrix: query auth over UDP with
bufsize 512 / 1232 / 4096 and `+tcp`; record answer size (`MSG SIZE rcvd`),
TC bit, retries. Discuss: >1232 relies on IP fragmentation → often dropped in
real networks → timeout, which is why 1232 + TCP-fallback is the modern stance.
**Proof:** the matrix table.

## LAB 10 (Days 50–51) — Secondary, NOTIFY, serials, IXFR
**Do:** add auth1sec (IP .11), named.conf zone:
`zone "corp.example" { type secondary; primaries { 172.20.0.10; }; file "/var/cache/bind/db.corp.example.sec"; };`
On auth1: `allow-transfer { 172.20.0.11; };` (+ `also-notify` not needed —
NOTIFY goes to NS records; since ns1 is the only NS, add
`ns2 IN A 172.20.0.11` + `@ IN NS ns2.corp.example.` so NOTIFY flows and the
estate is honest). Serial++, reload, watch auth1sec logs:
`zone corp.example/IN: transferred serial …`.
**Break 1 — forgotten serial:** edit a record, DON'T bump serial, reload.
NOTIFY fires, secondary checks SOA, sees same serial, transfers nothing →
secondaries serve old data. Prove with `dig @.11 SOA` vs `@.10 SOA`. Fix:
serial++.
**Break 2 — serial went backwards:** set serial 2026070102 → then "correct" it
to 2025… (lower). Secondary ignores lower serials. Recovery technique
(documented, execute the concept): add 2^31 (wrap serial forward), transfer,
then set the desired value — or pragmatic lab fix `rndc retransfer` (full AXFR
regardless). Journal both methods; the 2^31 trick is a senior interview
classic.
**10b IXFR:** with the secondary healthy, make one small change (serial++),
tcpdump on .11 port 53: observe TCP IXFR carrying only the delta. Then
delete auth1's journal (`docker exec auth1 rm /etc/bind/db.corp.example.jnl`
— only exists for dynamic zones; for static-file primaries IXFR is served
from differences only if `ixfr-from-differences yes;` is set — SET IT in
auth1 options, observe .jnl appear) and watch fallback to AXFR after the
journal is gone.
**Qs:** who initiates the transfer? *(A: the SECONDARY, after NOTIFY or
refresh timer; NOTIFY is just a hint.)* Why TCP? *(A: transfers are always
TCP.)*

## LAB 11 (Day 52) — TSIG
**Do:** `docker exec auth1 tsig-keygen xfer-key` → paste output `key {}` block
into BOTH auth1 and auth1sec configs. auth1:
`allow-transfer { key xfer-key; };` auth1sec zone: `primaries { 172.20.0.10 key xfer-key; };`
Reload both; force `rndc retransfer corp.example` on .11 → success in logs.
Prove enforcement: `dig @172.20.0.10 corp.example AXFR` (unsigned) → now
`Transfer failed` / REFUSED.
**Break A — wrong secret:** corrupt one char of secret on secondary →
auth1 log: `request has invalid signature … tsig verify failure (BADSIG)`.
**Break B — clock skew:** (simulate by reading) TSIG allows ±300 s; log
signature: `BADTIME`. Note: containers share host clock, so document rather
than reproduce; know the log string.
**Q:** what does TSIG protect and NOT protect? *(A: authenticates/integrity-
protects the transaction between two parties with a shared secret; it is NOT
encryption and NOT DNSSEC — data is still cleartext and unsigned for the
world.)*

## LAB 12 (Day 56) — Dynamic updates
**Do:** on auth1 zone corp.example: `allow-update { key xfer-key; };` (reuse
key). From WSL:
```
nsupdate -y hmac-sha256:xfer-key:<secret>
> server 172.20.0.10
> zone corp.example
> update add dyn1.corp.example. 300 A 10.10.20.77
> send
```
Verify; note serial auto-incremented and `.jnl` file present.
**The hand-edit trap:** edit db.corp.example directly while dynamic, reload →
BIND refuses/complains (journal out of sync). Proper procedure:
`rndc freeze corp.example` → edit + serial++ → `rndc thaw corp.example`.
Do it wrong once, read the exact error, then do it right.
**Q:** how does this relate to AD? *(A: AD clients/DCs do secure dynamic
updates (GSS-TSIG) at massive scale — why AD zones must never be hand-edited
and why scavenging exists for stale dynamic records.)*
**Cleanup:** delete dyn1 via nsupdate.

## LAB 13 (Day 58) — RPZ / sinkhole
**Do:** on resolver1:
```
options { … response-policy { zone "rpz.lab"; }; };
zone "rpz.lab" { type primary; file "/etc/bind/db.rpz"; };
```
db.rpz:
```
$TTL 300
@ IN SOA ns1.lab.internal. hostmaster.lab.internal. (1 3600 900 604800 300)
@ IN NS  ns1.lab.internal.
bad.example.net   IN CNAME .                      ; NXDOMAIN action
;bad.example.net  IN A     192.168.50.250         ; sinkhole action (swap later)
```
Test: `dig @172.20.0.53 bad.example.net` → NXDOMAIN even though auth1 would
answer (create `bad IN A 10.10.90.66` in example.net first so you can prove
the override). Swap to sinkhole form (serial++), retest → 192.168.50.250.
Check resolver logs: `rpz QNAME rewrite`.
**Qs:** where does RPZ act — auth or resolver? *(A: resolver — it rewrites
answers for ITS clients only.)* How do users bypass it? *(A: other resolvers,
DoH — policy must block those paths too.)*
**Cleanup:** keep RPZ zone, empty of rules.

## LAB 14 (Day 99) + 14b (Day 100) — DNSSEC sign, validate, break
**Do (sign):** auth1, zone lab.internal:
`zone "lab.internal" { type primary; file "…"; dnssec-policy default; inline-signing yes; };`
Reload; wait ~1 min; `dig @172.20.0.10 lab.internal DNSKEY +dnssec` shows keys
+ RRSIGs. Extract trust anchor: `dig @172.20.0.10 lab.internal DNSKEY | grep 257`.
On resolver1: `dnssec-validation yes;` plus
`trust-anchors { "lab.internal" static-key 257 3 13 "<pubkey>"; };`
(lab shortcut: real chains go via DS at parent — you'll ALSO do it properly:
generate DS `dnssec-dsfromkey`, add DS record to tld1 db.internal under `lab`,
serial++, and use the root/TLD chain… but root/TLD are unsigned in this lab, so
the static trust anchor is the working method; understanding WHY is Day 99's
explain task).
Validate: `docker exec resolver1 delv @127.0.0.1 srv1.lab.internal A +root=lab.internal -a /etc/bind/trust.keys`
or simpler: `dig @172.20.0.53 srv1.lab.internal +dnssec` → **`ad` flag** present.
**14b breaks:**
1. **Expired/withheld signatures:** stop re-signing by switching the zone back
   to plain (`dnssec-policy` removed) while resolver still trusts the anchor →
   answers now unsigned under a trust anchor → SERVFAIL. Prove: `+cd` returns
   the answer; without `+cd`, SERVFAIL. (This models expired RRSIG operationally.)
2. **Wrong trust anchor (stale DS analog):** corrupt one char of the anchor
   key on resolver1 → SERVFAIL; delv reports broken trust/`no valid signature`.
Diagnose each using the C8 method; capture evidence.
**Cleanup:** restore working signed state — it stays for Weeks 15–19.

---

## FAULT LIBRARY (arming instructions — Day 60 gauntlet, capstones)
Write each fault on a card; when a day says "armed fault", pick blind (or have
Vanessa pick a number 1–10) and inject before diagnosing:
1. Typo in named.conf (missing `;`) → named won't start. *(named-checkconf finds it.)*
2. Zone file NS name without A/glue → checkzone warning, resolution issues.
3. allow-query ACL excludes your client → REFUSED.
4. Serial not incremented after change → secondaries stale.
5. allow-transfer reverted to none → secondary expiry countdown; `retransfer` fails.
6. TSIG secret corrupted → BADSIG in logs.
7. Wrong glue IP in parent delegation → child SERVFAIL after flush.
8. resolver1 hints file wrong IP → all recursion SERVFAIL.
9. SOA minimum raised to 86400 before a "record add" exercise → negative-cache pain.
10. View ACL narrowed → split-horizon leak.
Grade each solve: correct layer named ≤5 min, proof command shown, fix + verify.

## FIREWALL SIMULATION (Day 81 technique)
Inside a container: `docker exec -u 0 auth1 apt-get update && apt-get install -y iptables`
then e.g. `iptables -A INPUT -p tcp --dport 53 -j DROP` (UDP-only path → LAB 9
symptoms become "firewall tickets"). Remove with `-D`. Alternative without
iptables: `docker pause <svc>` = total drop (timeout signature) vs stopping
named = RST/refused signature — know the difference in captures.
