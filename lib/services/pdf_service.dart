import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models.dart';

class PdfService {
  PdfService({DateFormat? dateFormat, NumberFormat? moneyFormat})
    : _dateFormat = dateFormat ?? DateFormat('dd/MM/yyyy HH:mm'),
      _moneyFormat =
          moneyFormat ?? NumberFormat.currency(locale: 'it_IT', symbol: '€');

  final DateFormat _dateFormat;
  final NumberFormat _moneyFormat;

  Future<String> buildDocumentPdf({
    required SalesDocument document,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();
    final showPrices = document.kind.showsPrices;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header(settings, document.kind.label),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Documento: ${document.number}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(_dateFormat.format(document.createdAt)),
            ],
          ),
          pw.SizedBox(height: 12),
          _customerBox(document.customer),
          if (document.movementReason != null) ...[
            pw.SizedBox(height: 8),
            pw.Text('Causale: ${document.movementReason!.label}'),
          ],
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'Codice',
              'Prodotto',
              'Q.tà',
              if (showPrices) 'Prezzo',
              if (showPrices) 'Totale',
            ],
            data: document.lines
                .map(
                  (line) => [
                    line.product.code,
                    line.product.name,
                    line.quantity.toString(),
                    if (showPrices) _moneyFormat.format(line.product.price),
                    if (showPrices) _moneyFormat.format(line.total),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            border: pw.TableBorder.all(color: PdfColors.grey500),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              showPrices
                  ? 'Totale documento: ${_moneyFormat.format(document.total)}'
                  : 'Prezzi non esposti',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 24),
          _signatures(document, settings),
        ],
      ),
    );

    return _writePdf('documento_${document.number}.pdf', await pdf.save());
  }

  Future<String> buildPaymentReceiptPdf({
    required Payment payment,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(settings, 'Ricevuta incasso'),
            pw.SizedBox(height: 16),
            _customerBox(payment.customer),
            pw.SizedBox(height: 12),
            pw.Text('Data: ${_dateFormat.format(payment.createdAt)}'),
            pw.Text('Metodo: ${payment.method.label}'),
            if (payment.electronicReference?.isNotEmpty ?? false)
              pw.Text(
                'Riferimento elettronico: ${payment.electronicReference}',
              ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Importo incassato: ${_moneyFormat.format(payment.amount)}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    return _writePdf('ricevuta_${payment.id}.pdf', await pdf.save());
  }

  Future<String> buildStatementPdf({
    required Customer customer,
    required List<SalesDocument> documents,
    required List<Payment> payments,
    required AppSettings settings,
  }) async {
    final pdf = pw.Document();
    final customerDocuments = documents
        .where((document) => document.customer.id == customer.id)
        .toList();
    final customerPayments = payments
        .where((payment) => payment.customer.id == customer.id)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header(settings, 'Estratto conto cliente'),
          pw.SizedBox(height: 12),
          _customerBox(customer),
          pw.SizedBox(height: 16),
          pw.Text(
            'Documenti',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Numero', 'Data', 'Tipo', 'Totale'],
            data: customerDocuments
                .map(
                  (document) => [
                    document.number,
                    _dateFormat.format(document.createdAt),
                    document.kind.label,
                    document.kind.showsPrices
                        ? _moneyFormat.format(document.total)
                        : 'N/D',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Incassi',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TableHelper.fromTextArray(
            headers: const ['Data', 'Metodo', 'Importo'],
            data: customerPayments
                .map(
                  (payment) => [
                    _dateFormat.format(payment.createdAt),
                    payment.method.label,
                    _moneyFormat.format(payment.amount),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Saldo attuale: ${_moneyFormat.format(customer.balance)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    return _writePdf('estratto_conto_${customer.code}.pdf', await pdf.save());
  }

  pw.Widget _header(AppSettings settings, String title) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text('${settings.companyName} - P.IVA ${settings.companyVat}'),
      pw.Text(settings.companyAddress),
      pw.Text('Agente: ${settings.agentName} (${settings.agentCode})'),
      pw.Text(
        'Automezzo: ${settings.vehicle.plate} - ${settings.vehicle.travelingDepot}',
      ),
    ],
  );

  pw.Widget _customerBox(Customer customer) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey500),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          customer.businessName,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('${customer.address} - ${customer.city}'),
        pw.Text('P.IVA: ${customer.vatNumber} - Codice: ${customer.code}'),
      ],
    ),
  );

  pw.Widget _signatures(SalesDocument document, AppSettings settings) {
    final customerSignature = document.customerSignature;
    final agentSignature = settings.agentSignature;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            if (customerSignature != null)
              pw.Image(
                pw.MemoryImage(customerSignature),
                width: 140,
                height: 60,
                fit: pw.BoxFit.contain,
              )
            else
              pw.SizedBox(width: 140, height: 60),
            pw.Container(width: 160, height: 1, color: PdfColors.grey700),
            pw.Text('Firma cliente'),
          ],
        ),
        pw.Column(
          children: [
            if (agentSignature != null)
              pw.Image(
                pw.MemoryImage(agentSignature),
                width: 140,
                height: 60,
                fit: pw.BoxFit.contain,
              )
            else
              pw.SizedBox(width: 140, height: 60),
            pw.Container(width: 160, height: 1, color: PdfColors.grey700),
            pw.Text('Firma agente'),
          ],
        ),
      ],
    );
  }

  Future<String> _writePdf(String filename, List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final documentsDirectory = Directory(
      p.join(directory.path, 'tentata_vendita_pdf'),
    );
    if (!documentsDirectory.existsSync()) {
      documentsDirectory.createSync(recursive: true);
    }
    final file = File(p.join(documentsDirectory.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
