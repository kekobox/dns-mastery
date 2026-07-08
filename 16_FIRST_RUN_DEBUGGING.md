# SECTION 17 (ADDENDUM B) — FIRST-RUN DEBUGGING APPENDIX
### Read this BEFORE Day 2. It removes the evening the lab would otherwise eat.

**Erratum #1 (logged per Addendum C protocol):** file 06 says Docker
Desktop's WSL integration routes container IPs from WSL — that is often
FALSE. On Docker Desktop, containers live inside Docker's utility VM;
their 172.20.x addresses are generally NOT reachable from your WSL
distro or from Windows. Reachability depends on your setup. Establish
yours on Day 2 with the matrix below, then standardize on ONE access
pattern for all 132 days.

## 1. WHERE DOES YOUR DOCKER ACTUALLY RUN?

```
docker info | grep -iE "operating system|context|name"
```
- "Docker Desktop" → containers in the Desktop VM → assume container IPs
  unreachable from WSL/Windows; use Pattern A or B below. (Desktop 4.26+
  "mirrored networking" and host-networking options change this — test,
  don't trust.)
- Native dockerd inside your WSL distro (no Desktop) → container IPs ARE
  reachable from that distro → Pattern C works and is nicest.

## 2. THE REACHABILITY MATRIX (run once, record results in journal Day 2)

```
# from WSL:
ping -c1 172.20.0.2                       # container IP reachable?
dig @172.20.0.2 . NS +time=2 +tries=1     # DNS to container IP?
docker exec root1 dig @172.20.0.2 . NS    # always works (in-network)
# from Windows PowerShell:
Test-NetConnection 127.0.0.1 -Port 5353   # published port path
```

## 3. THE THREE ACCESS PATTERNS (pick one, standardize)

**Pattern A — client container (RECOMMENDED, works everywhere):**
add a toolbox container ON the dnslab network and do all client-side
work from inside it. This is also the most realistic: a "client host"
with its own resolver config.
```yaml
  client:
    image: nicolaka/netshoot        # dig, tcpdump, curl, everything
    container_name: client
    command: ["sleep","infinity"]
    networks: { dnslab: { ipv4_address: 172.20.0.200 } }
    dns: [172.20.0.53]              # its stub points at resolver1 — realism
```
Then alias it in WSL: `alias labdig='docker exec client dig'` and every
command in files 03–12 that says `dig @...` runs verbatim as
`labdig @...`. tcpdump captures also run here or in server containers.

**Pattern B — published ports (for Windows-host client labs):**
per service, distinct host ports: resolver1 `5353:53/udp` + `5353:53/tcp`,
auth1 `15310:53/udp+tcp`, auth1sec `15311`, auth2 `15320`, fwd1 `5363`.
Windows testing reality: **Resolve-DnsName has NO port parameter** — for
direct-server tests from Windows use nslookup interactive mode:
```
nslookup
> server 127.0.0.1
> set port=5353
> app1.corp.example
```
Resolve-DnsName is still fully usable for the Windows-CLIENT-behavior
labs (suffixes, Get-DnsClientCache, NRPT) — those test the OS stub, and
any name your normal setup resolves exercises them. If you want Windows'
stub itself to use the lab resolver, publish resolver1 on host port
53/udp+tcp and point a test interface at 127.0.0.1 — but check the port
first: `netstat -ano | findstr :53` (Docker Desktop, ICS, or the WSL
relay often squat on it; if taken, don't fight it — Pattern A covers
those drills from Linux and nslookup covers Windows spot-checks).

**Pattern C — native-WSL dockerd:** container IPs directly reachable
from WSL; files 03–12 commands work verbatim. Verify after every WSL
kernel/Docker update — this property is config-fragile.

## 4. GOTCHAS THAT WILL OTHERWISE COST YOU AN EVENING EACH

**CRLF line endings (the #1 zone-file killer on Windows).** Zone files
edited in Windows editors arrive with \r\n; named-checkzone throws
bewildering syntax errors on visually-perfect files. Rules: edit inside
WSL (vim/nano) or set VS Code to LF for the dnslab folder
(`"files.eol": "\n"`), and if a repo is involved: `.gitattributes` with
`* text eol=lf`. Diagnostic when a "perfect" file fails: `file db.corp.example`
(says CRLF) or `cat -A db.corp.example | head` (shows ^M). Fix:
`dos2unix` or `sed -i 's/\r$//' file`.

**WSL clock drift after Windows sleep.** WSL2's clock can lag minutes
after suspend → TSIG BADTIME (LAB 11) and DNSSEC validity chaos
(LAB 14) with nothing "wrong". Check: `date` in WSL vs Windows. Fix:
`sudo hwclock -s` or `wsl --shutdown` + restart. Treat as first suspect
whenever crypto-adjacent labs misbehave after the laptop slept —
and enjoy that this is EXACTLY the appliance/VM-snapshot failure class
from TM 4.4, happening to you for free.

**rndc inside the containers.** The ISC image usually ships a generated
/etc/bind/rndc.key and named picks it up → `docker exec resolver1 rndc
status` just works. If you get "connect failed / no key": generate and
wire it once:
```
docker exec -u 0 resolver1 rndc-confgen -a   # writes /etc/bind/rndc.key
# ensure named.conf has (or add):
# include "/etc/bind/rndc.key";
# controls { inet 127.0.0.1 port 953 allow {127.0.0.1;} keys {"rndc-key";}; };
docker restart resolver1
```
Note resolver1's mount is `:ro` in the base compose — if rndc-confgen
must write, temporarily drop `:ro` for that service or generate the key
on the WSL side into ./resolver1/ and restart.

**Read-only mounts vs runtime writes.** Working-dir writes (cache dump,
journals for ixfr-from-differences, inline-signing state) land in
/var/cache/bind INSIDE the container — fine even with `:ro` config
mounts. But auth1 needs its `/etc/bind` rw from Week 8 (journals beside
zone files if you keep defaults) — the base compose already mounts auth1
rw; if you tightened it, loosen it before LAB 10/12/14.

**"Port is already allocated" on compose up.** Another container or a
previous half-down stack holds the published port: `docker ps -a`,
`docker compose down`, retry. On Windows-side 53 conflicts, see
Pattern B note.

**Resolver works for lab zones but SERVFAILs real internet names.**
Correct and expected: resolver1's root is YOUR root; it knows only
example/internal/net/tld. Real-internet drills use your normal resolver
or `dig @9.9.9.9` — never "fix" resolver1 by forwarding it to the
internet, or half the delegation labs stop teaching (split universes on
purpose).

**Docker's embedded DNS (127.0.0.11) inside containers.** Containers'
own /etc/resolv.conf points at Docker's resolver; that's fine for the
client container (we override with `dns:`) but remember it exists when
a container-side `getent`/app lookup surprises you — T39 in your own
lab.

**`docker compose` vs `docker-compose`.** Use the plugin form
(`docker compose`); the standalone v1 binary mis-parses newer YAML
(the `name:` top-level key, anchors).

## 5. FIVE-MINUTE TRIAGE TABLE (Day 2/5 quick reference)

| Symptom | First check | Usual cause |
|---|---|---|
| container restarts in a loop | `docker logs <c>` | named.conf typo — run named-checkconf via `docker run --rm -v $PWD/auth1:/etc/bind internetsystemsconsortium/bind9:9.18 named-checkconf /etc/bind/named.conf` |
| zone "not loaded" in logs | named-checkzone the file | CRLF, missing trailing dot, no serial bump |
| dig from WSL times out to 172.20.x | §1–2 matrix | Docker Desktop reality → Pattern A |
| dig works from client container, not from Windows | expected | use Pattern B ports / nslookup set port |
| TSIG/DNSSEC labs fail after laptop slept | `date` skew | WSL clock — hwclock -s |
| rndc: connection refused | key/controls | §4 rndc recipe |
| +trace hangs at root | hints file / root1 up | `docker exec client dig @172.20.0.2 . NS` isolates it |

## 6. THE DAY-2 ACCEPTANCE TEST (replaces guesswork)

You are "unblocked" when all five pass, whichever pattern you chose:
1. `labdig @172.20.0.2 . NS` → aa, root NS.
2. `labdig @172.20.0.53 app1.corp.example` twice → answer, TTL drains.
3. `labdig @172.20.0.10 app1.corp.example` → aa, full TTL.
4. From Windows: one successful direct-server query (nslookup+port or
   published-53) OR a documented decision that Windows drills use the
   stub-behavior subset only.
5. `docker exec resolver1 rndc status` → server up.
Record which pattern you standardized on at the top of your journal —
every later "commands don't work" moment starts by rereading that line.
