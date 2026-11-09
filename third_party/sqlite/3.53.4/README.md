# SQLite 3.53.4 amalgamation

Source: <https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip>

The archive was verified against SQLite's published SHA3-256 before extracting
these files:

```text
628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e
```

`pubspec.yaml` configures `package:sqlite3` to compile `sqlite3.c` with its
documented source hook, avoiding a runtime download of a prebuilt binary.
