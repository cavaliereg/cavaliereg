---
name: testing-tentata-vendita
description: Test the Tentata Vendita Italiana Flutter app end-to-end on Linux desktop. Use when verifying DDT, payments, sync, or settings changes.
---

# Testing — Tentata Vendita Italiana

## Prerequisites

- Flutter SDK on PATH (`flutter --version`)
- Linux desktop toolchain installed (clang, cmake, ninja-build, pkg-config, libgtk-3-dev)
- `wmctrl` for maximizing app window before recording

## Build & Launch

```bash
cd /home/ubuntu/repos/cavaliereg
flutter pub get
flutter analyze
flutter test
flutter build linux --debug
flutter run -d linux  # launches the desktop app
```

Maximize before recording:
```bash
wmctrl -r "tentata_vendita_italiana" -b add,maximized_vert,maximized_horz
```

## Mock Data (seeded in memory)

| Entity | Items |
|--------|-------|
| Products | 4: Latte UHT (p-001, €1.38, stock 120), Pasta semola (p-002, €0.92, stock 90), Olio EVO (p-003, €7.85, stock 36), Biscotti (p-004, €2.15, stock 64) |
| Customers | 3: Alimentari Rossi (c-001, balance €246.80), Market Verdi (c-002, balance €0), Minimarket Blu (c-003, balance €98.45) |
| Total stock | 310 (120+90+36+64) |

## Daily Cancellation Password

Formula: `SEDE-YYYYMMDD` (e.g. `SEDE-20260607` for June 7, 2026).  
Generated in `SalesAppState._dailyPasswordFor()` and hashed with SHA-256.  
Only the **last printed document** can be cancelled without password; all others require the daily password.

## Navigation

NavigationRail on the left with 8 destinations (top to bottom):
1. Home (Dashboard)
2. Catalogo
3. Giri (Visits)
4. Magazzino
5. DDT (Documents)
6. Cassa (Payments)
7. Sync
8. Impostazioni (Settings)

## Key Test Flows

### 1. DDT Conto Proprio vs Conto Terzi
- Navigate to DDT → "Nuovo DDT"
- **Conto proprio**: prices visible on document row (e.g. `6,90 €`)
- **Conto terzi**: NO price shown on document row
- This is the critical business distinction — always verify both

### 2. Password-Protected Cancellation
- Cancel the **last** document → should succeed immediately (no dialog)
- Cancel an **older** document → password dialog appears
- Wrong password → rejected with SnackBar error
- Correct daily password (`SEDE-YYYYMMDD`) → document cancelled

### 3. Payment Registration
- Navigate to Cassa → select customer, enter amount, select method
- Click "Registra e stampa ricevuta"
- Verify payment appears in right panel, receipt PDF path shown
- **Known issue (fixed):** Customer dropdown used to crash after payment because `copyWith` created a new instance. Fixed by adding `operator ==` / `hashCode` on `Customer.id`. If this regresses, the symptom is a red error screen after clicking "Registra".

### 4. Sync
- Navigate to Sync → verify items show "Da sincronizzare"
- Click "Sincronizza ora" → all items should change to "Sincronizzato"

### 5. Settings → Dashboard
- Change plate or agent zone in Impostazioni → "Salva impostazioni offline"
- Navigate to Home → subtitle should reflect the new values

## Devin Secrets Needed

None — this is a fully offline app with mock data. No API keys or login credentials required.

## Tips

- The app uses `DropdownButtonFormField` with `initialValue` — if equality breaks on model classes, dropdowns will crash. Always ensure model classes used as dropdown values have stable `==` / `hashCode`.
- PDF files are written to the system temp directory via `path_provider`. Check `/home/ubuntu/Documents/tentata_vendita_pdf/` for generated PDFs.
- The Zebra RW420 printer adapter is a stub — it logs to console but doesn't connect to real Bluetooth. The "Ultima stampa" section on Dashboard shows the stub message.
