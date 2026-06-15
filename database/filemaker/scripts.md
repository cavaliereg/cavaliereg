# FileMaker scripts

Add these scripts after creating the tables and relationships.

## New DDT Number

Purpose: generate the same document-number format used by the Flutter app.

Inputs:

- `kind`: one of `ddtContoProprio`, `ddtContoTerzi`, `movimentoMagazzino`.

Logic:

```text
Set Variable [ $prefix ;
  Case (
    $kind = "ddtContoProprio" ; "V" ;
    $kind = "ddtContoTerzi" ; "T" ;
    $kind = "movimentoMagazzino" ; "M" ;
    "D"
  )
]
Set Variable [ $sequence ; Right ( "00000" & ( Get ( TotalRecordCount ) + 1 ) ; 5 ) ]
Set Variable [ $number ; $prefix & "-" & Year ( Get ( CurrentDate ) ) & "-" & $sequence ]
Exit Script [ Text Result: $number ]
```

## Create DDT

Purpose: create a document header and related line records.

Inputs:

- `kind`, `customer_id`, and optional `movement_reason`.
- selected products with quantities.

Logic:

```text
Set Variable [ $kind_label ;
  Case (
    $kind = "ddtContoProprio" ; "DDT vendita conto proprio" ;
    $kind = "ddtContoTerzi" ; "DDT conto terzi" ;
    $kind = "movimentoMagazzino" ; "DDT movimentazione merci" ;
    "DDT"
  )
]
New Record/Request in sales_documents
Set Field [ sales_documents::document_id ; Get ( UUID ) ]
Set Field [ sales_documents::kind ; $kind ]
Set Field [ sales_documents::customer_id ; $customer_id ]
Set Field [ sales_documents::document_number ; Perform Script [ "New DDT Number" ] ]
Set Field [ sales_documents::created_at ; Get ( CurrentTimestamp ) ]
Set Field [ sales_documents::sync_status ; "daSincronizzare" ]
Set Field [ sales_documents::printed ; 1 ]
Set Field [ sales_documents::cancelled ; 0 ]
Set Field [ sales_documents::movement_reason ; $movement_reason ]

For each selected product:
  New Record/Request in document_lines
  Set Field [ document_lines::document_line_id ; Get ( UUID ) ]
  Set Field [ document_lines::document_id ; sales_documents::document_id ]
  Set Field [ document_lines::product_id ; products::product_id ]
  Set Field [ document_lines::quantity ; selected quantity ]
  Set Field [ document_lines::unit_price ; products::price ]
  Set Field [ document_lines::vat_rate ; products::vat_rate ]
  Set Field [ products::stock ; products::stock - quantity ]

Perform Script [ "Enqueue Sync Item" ; "Invio PDF " & $kind_label & " " & sales_documents::document_number ]
```

## Register Payment

Purpose: record payment, update customer balance, and queue sync.

Inputs:

- `customer_id`, `amount`, `method`, and optional `electronic_reference`.

```text
New Record/Request in payments
Set Field [ payments::payment_id ; Get ( UUID ) ]
Set Field [ payments::customer_id ; $customer_id ]
Set Field [ payments::amount ; $amount ]
Set Field [ payments::method ; $method ]
Set Field [ payments::electronic_reference ; $electronic_reference ]
Set Field [ payments::created_at ; Get ( CurrentTimestamp ) ]
Set Field [ payments::sync_status ; "daSincronizzare" ]
Set Field [ customers::balance ; customers::balance - payments::amount ]
Perform Script [ "Enqueue Sync Item" ; "Invio ricevuta pagamento" ]
```

## Enqueue Sync Item

Purpose: create offline sync tasks for headquarters.

```text
New Record/Request in sync_queue
Set Field [ sync_queue::sync_queue_id ; Get ( UUID ) ]
Set Field [ sync_queue::description ; Get ( ScriptParameter ) ]
Set Field [ sync_queue::created_at ; Get ( CurrentTimestamp ) ]
Set Field [ sync_queue::status ; "daSincronizzare" ]
```

## Mark Queue Synchronized

Purpose: mirror the demo app's `synchronize()` behavior.

```text
Go to Layout [ sync_queue ]
Enter Find Mode [ Pause: Off ]
Set Field [ sync_queue::status ; "daSincronizzare" ]
Perform Find
Replace Field Contents [ sync_queue::status ; "sincronizzato" ]

Go to Layout [ sales_documents ]
Enter Find Mode [ Pause: Off ]
Set Field [ sales_documents::sync_status ; "daSincronizzare" ]
Perform Find
Replace Field Contents [ sales_documents::sync_status ; "sincronizzato" ]

Go to Layout [ payments ]
Enter Find Mode [ Pause: Off ]
Set Field [ payments::sync_status ; "daSincronizzare" ]
Perform Find
Replace Field Contents [ payments::sync_status ; "sincronizzato" ]
```
