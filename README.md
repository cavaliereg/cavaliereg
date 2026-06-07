# Tentata Vendita Italiana

Applicazione Flutter offline-first per tentata vendita italiana con catalogo prodotti,
magazzino viaggiante, giri visita, emissione DDT, pagamenti, estratti conto, PDF
e adapter di stampa per Zebra RW420 Bluetooth.

## Funzionalità incluse

- Catalogo prodotti con immagine/anteprima e giacenza a bordo.
- Anagrafica clienti e giri visita sincronizzati dalla sede, senza creazione o cancellazione locale.
- Magazzino viaggiante associato a targa automezzo, agente di zona e deposito viaggiante.
- Emissione DDT vendita conto proprio con prezzi visibili.
- Emissione DDT conto terzi senza prezzi visibili.
- DDT di movimentazione merci con causali:
  - reso scaduto;
  - reso tecnico;
  - trasferimento tra depositi viaggianti.
- Raccolta firma cliente sui documenti emessi.
- Impostazioni agente, azienda cedente, automezzo e firma grafica agente.
- Cassa pagamenti, pagamenti elettronici, ricevute di incasso ed estratti conto.
- Generazione PDF per documenti, ricevute ed estratti conto.
- Coda di sincronizzazione offline per invio sede di documenti, pagamenti, annullamenti e PDF.
- Blocco con password giornaliera sede per annullare documenti diversi dall’ultimo stampato.
- Adapter applicativo per stampa PDF su Zebra RW420 Bluetooth.

## Comandi sviluppo

```bash
flutter pub get
flutter analyze
flutter test
flutter build linux --debug
```

## Note architetturali

L’app è strutturata con modelli dominio in `lib/domain`, stato applicativo offline
in `lib/state`, generazione PDF in `lib/services/pdf_service.dart` e adapter Zebra
in `lib/services/print_service.dart`.

Lo stato è progettato per lavorare offline: ogni documento/pagamento produce un PDF
e un elemento in coda di sincronizzazione. La sincronizzazione demo marca gli elementi
come inviati e aggiorna la password giornaliera che abilita gli annullamenti protetti.

La stampa Zebra RW420 è isolata dietro `ZebraRw420PrintService` per collegare in modo
incrementale il canale nativo Bluetooth Android/iOS o un plugin dedicato senza cambiare
le schermate operative.
