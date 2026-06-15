# FileMaker relationships

Create these table occurrences and relationships in FileMaker Pro.

## Core relationships

```text
customers::customer_id = sales_documents::customer_id
sales_documents::document_id = document_lines::document_id
products::product_id = document_lines::product_id
customers::customer_id = payments::customer_id
vehicle_settings::vehicle_id = app_settings::vehicle_id
```

## Lookup relationships

```text
document_kinds::kind_code = sales_documents::kind
movement_reasons::reason_code = sales_documents::movement_reason
payment_methods::method_code = payments::method
sync_statuses::status_code = sales_documents::sync_status
sync_statuses::status_code = payments::sync_status
sync_statuses::status_code = sync_queue::status
```

## Recommended portals

- `customers` layout:
  - portal to `sales_documents`;
  - portal to `payments`.
- `sales_documents` layout:
  - portal to `document_lines`;
  - related customer card from `customers`;
  - related DDT kind and movement reason labels.
- `products` layout:
  - portal to `document_lines` for product movement history.
- `sync_queue` layout:
  - filtered view where `status = "daSincronizzare"`.
