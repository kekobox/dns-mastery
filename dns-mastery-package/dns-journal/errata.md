# Errata Log

Format:
E### | date | file+section | claim as written | what's actually true | how I proved it | fixed in file? Y/N

E001 | 2026-07-07 | 06 §2 client-access note | "Docker Desktop's WSL integration routes container IPs from WSL" | often false — container IPs live in the Desktop VM; use the client-container or published-port patterns | Addendum B §1-3, verified by Day-2 matrix | Y (16 supersedes)
