# FileMaker Pro database package

This folder defines a FileMaker Pro database for the Tentata Vendita app data model.

The current Devin environment is Linux and does not include FileMaker Pro, so it cannot generate a native `.fmp12` file directly. Use these files in FileMaker Pro on macOS or Windows to create the database:

1. Open FileMaker Pro.
2. Create a new file named `TentataVendita.fmp12`.
3. Create the tables and fields listed in `schema.csv`.
4. Create relationships from `relationships.md`.
5. Import starter records from `seed/` using the order in `import_order.txt`.
6. Add the operational scripts from `scripts.md`.

## Database scope

The schema covers:

- catalogo prodotti;
- anagrafica clienti;
- impostazioni agente, azienda, automezzo e deposito viaggiante;
- DDT vendita conto proprio;
- DDT conto terzi;
- DDT movimentazione merci;
- righe documento;
- pagamenti e ricevute;
- coda di sincronizzazione offline;
- tabelle lookup per stati, metodi e causali.

## FileMaker conventions

- Primary keys use `Get ( UUID )` auto-enter text fields.
- Foreign keys are text fields ending in `_id`.
- Container fields are included for firma cliente, firma agente, and PDF/receipt attachments.
- Calculations mirror the Flutter model where useful, but stored totals can also be populated by scripts for auditability.
- Boolean values use FileMaker number fields with `1` for true and `0` for false.

## Mobile app alignment

The seed data mirrors the demo data in `lib/state/sales_app_state.dart`:

- agent: Giancarlo Cavaliere;
- vehicle plate: GC123TV;
- traveling depot: Deposito viaggiante 01;
- four starter products;
- three starter customers.
