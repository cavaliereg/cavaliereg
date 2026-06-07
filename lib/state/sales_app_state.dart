import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../services/pdf_service.dart';
import '../services/print_service.dart';

class SalesAppState extends ChangeNotifier {
  SalesAppState({
    PdfService? pdfService,
    ZebraRw420PrintService? printService,
    Uuid? uuid,
  }) : _pdfService = pdfService ?? PdfService(),
       _printService = printService ?? ZebraRw420PrintService(),
       _uuid = uuid ?? const Uuid() {
    _seed();
  }

  final PdfService _pdfService;
  final ZebraRw420PrintService _printService;
  final Uuid _uuid;

  final List<Product> _products = [];
  final List<Customer> _customers = [];
  final List<SalesDocument> _documents = [];
  final List<Payment> _payments = [];
  final List<SyncQueueItem> _syncQueue = [];

  late AppSettings _settings;
  bool _syncing = false;
  String? _lastPrintMessage;

  List<Product> get products => List.unmodifiable(_products);
  List<Customer> get customers => List.unmodifiable(_customers);
  List<SalesDocument> get documents => List.unmodifiable(_documents);
  List<Payment> get payments => List.unmodifiable(_payments);
  List<SyncQueueItem> get syncQueue => List.unmodifiable(_syncQueue);
  AppSettings get settings => _settings;
  bool get syncing => _syncing;
  String? get lastPrintMessage => _lastPrintMessage;

  int get pendingSyncCount => _syncQueue
      .where((item) => item.status == SyncStatus.daSincronizzare)
      .length;

  int get totalTravelingStock =>
      _products.fold<int>(0, (sum, product) => sum + product.stock);

  double get cashBalance => _payments
      .where((payment) => payment.method == PaymentMethod.contanti)
      .fold<double>(0, (sum, payment) => sum + payment.amount);

  double get electronicBalance => _payments
      .where((payment) => payment.method != PaymentMethod.contanti)
      .fold<double>(0, (sum, payment) => sum + payment.amount);

  SalesDocument? get lastPrintedDocument {
    final printed = _documents.where((document) => document.printed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return printed.isEmpty ? null : printed.first;
  }

  Future<SalesDocument> issueDocument({
    required DocumentKind kind,
    required Customer customer,
    required Map<Product, int> quantities,
    MovementReason? movementReason,
    Uint8List? customerSignature,
  }) async {
    final selectedLines = quantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => DocumentLine(product: entry.key, quantity: entry.value))
        .toList();
    if (selectedLines.isEmpty) {
      throw ArgumentError('Selezionare almeno una riga prodotto.');
    }
    if (kind == DocumentKind.movimentoMagazzino && movementReason == null) {
      throw ArgumentError('Indicare la causale di movimentazione.');
    }

    final number = _nextDocumentNumber(kind);
    final document = SalesDocument(
      id: _uuid.v4(),
      number: number,
      kind: kind,
      customer: customer,
      lines: selectedLines,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.daSincronizzare,
      printed: true,
      cancelled: false,
      movementReason: movementReason,
      customerSignature: customerSignature,
    );

    final pdfPath = await _pdfService.buildDocumentPdf(
      document: document,
      settings: _settings,
    );
    final printable = document.copyWith(pdfPath: pdfPath);
    _documents.insert(0, printable);
    _decreaseStock(selectedLines);
    if (kind == DocumentKind.ddtContoProprio) {
      _increaseCustomerBalance(customer, document.total);
    }
    _enqueue('Invio PDF ${printable.kind.label} ${printable.number}', pdfPath);
    await printDocument(printable);
    notifyListeners();
    return printable;
  }

  Future<void> printDocument(SalesDocument document) async {
    final pdfPath = document.pdfPath;
    if (pdfPath == null) {
      _lastPrintMessage = 'PDF non ancora generato per ${document.number}.';
      notifyListeners();
      return;
    }
    final printer = _printService.pairedPrinters.first;
    final result = await _printService.printPdf(
      pdfPath: pdfPath,
      printer: printer,
    );
    _lastPrintMessage = result.message;
    notifyListeners();
  }

  bool canCancelWithoutPassword(SalesDocument document) =>
      lastPrintedDocument?.id == document.id;

  Future<void> cancelDocument(
    SalesDocument document, {
    String? password,
  }) async {
    if (!canCancelWithoutPassword(document) &&
        !_matchesDailyPassword(password ?? '')) {
      throw ArgumentError(
        'Password giornaliera richiesta per annullare questo documento.',
      );
    }
    final index = _documents.indexWhere((item) => item.id == document.id);
    if (index == -1) {
      return;
    }
    _documents[index] = document.copyWith(
      cancelled: true,
      syncStatus: SyncStatus.daSincronizzare,
    );
    _enqueue('Annullamento documento ${document.number}', document.pdfPath);
    notifyListeners();
  }

  Future<Payment> registerPayment({
    required Customer customer,
    required double amount,
    required PaymentMethod method,
    String? electronicReference,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Inserire un importo positivo.');
    }
    final payment = Payment(
      id: _uuid.v4(),
      customer: customer,
      amount: amount,
      method: method,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.daSincronizzare,
      electronicReference: electronicReference,
    );
    final pdfPath = await _pdfService.buildPaymentReceiptPdf(
      payment: payment,
      settings: _settings,
    );
    final saved = payment.copyWith(receiptPdfPath: pdfPath);
    _payments.insert(0, saved);
    _increaseCustomerBalance(customer, -amount);
    _enqueue('Ricevuta incasso ${customer.businessName}', pdfPath);
    notifyListeners();
    return saved;
  }

  Future<String> buildStatement(Customer customer) async {
    final pdfPath = await _pdfService.buildStatementPdf(
      customer: customer,
      documents: _documents,
      payments: _payments,
      settings: _settings,
    );
    _enqueue('Estratto conto ${customer.businessName}', pdfPath);
    notifyListeners();
    return pdfPath;
  }

  Future<void> synchronize() async {
    _syncing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 1));
    for (var index = 0; index < _syncQueue.length; index += 1) {
      _syncQueue[index] = _syncQueue[index].copyWith(
        status: SyncStatus.sincronizzato,
      );
    }
    for (var index = 0; index < _documents.length; index += 1) {
      _documents[index] = _documents[index].copyWith(
        syncStatus: SyncStatus.sincronizzato,
      );
    }
    for (var index = 0; index < _payments.length; index += 1) {
      _payments[index] = _payments[index].copyWith(
        syncStatus: SyncStatus.sincronizzato,
      );
    }
    _settings = _settings.copyWith(
      dailyPasswordHash: _hashPassword(_dailyPasswordFor(DateTime.now())),
    );
    _syncing = false;
    notifyListeners();
  }

  void updateSettings({
    String? agentName,
    String? agentCode,
    String? companyName,
    String? companyVat,
    String? companyAddress,
    String? plate,
    String? zoneAgent,
    String? travelingDepot,
    Uint8List? agentSignature,
  }) {
    _settings = _settings.copyWith(
      agentName: agentName,
      agentCode: agentCode,
      companyName: companyName,
      companyVat: companyVat,
      companyAddress: companyAddress,
      vehicle: _settings.vehicle.copyWith(
        plate: plate,
        zoneAgent: zoneAgent,
        travelingDepot: travelingDepot,
      ),
      agentSignature: agentSignature,
    );
    _enqueue('Aggiornamento impostazioni agente/automezzo', null);
    notifyListeners();
  }

  void _seed() {
    _settings = AppSettings(
      agentName: 'Giancarlo Cavaliere',
      agentCode: 'AG-001',
      companyName: 'Azienda Cedente Demo S.r.l.',
      companyVat: 'IT00000000000',
      companyAddress: 'Via della Distribuzione 1, 00100 Roma',
      vehicle: const VehicleSettings(
        plate: 'GC123TV',
        zoneAgent: 'Zona Sud',
        travelingDepot: 'Deposito viaggiante 01',
      ),
      dailyPasswordHash: _hashPassword(_dailyPasswordFor(DateTime.now())),
    );
    _products.addAll(const [
      Product(
        id: 'p-001',
        code: 'LAT-001',
        name: 'Latte UHT intero',
        description: 'Cartone 1L - prodotto fresco a lunga conservazione',
        price: 1.38,
        vatRate: 4,
        stock: 120,
        imageSeed: '🥛',
      ),
      Product(
        id: 'p-002',
        code: 'PAS-250',
        name: 'Pasta semola 500g',
        description: 'Formato penne rigate',
        price: 0.92,
        vatRate: 4,
        stock: 90,
        imageSeed: '🍝',
      ),
      Product(
        id: 'p-003',
        code: 'OLI-075',
        name: 'Olio EVO 0,75L',
        description: 'Bottiglia vetro, extra vergine',
        price: 7.85,
        vatRate: 4,
        stock: 36,
        imageSeed: '🫒',
      ),
      Product(
        id: 'p-004',
        code: 'BIS-300',
        name: 'Biscotti frollini',
        description: 'Confezione 300g',
        price: 2.15,
        vatRate: 10,
        stock: 64,
        imageSeed: '🍪',
      ),
    ]);
    _customers.addAll(const [
      Customer(
        id: 'c-001',
        code: 'CL-1001',
        businessName: 'Alimentari Rossi',
        address: 'Via Roma 12',
        city: 'Salerno',
        vatNumber: 'IT01234567890',
        visitRound: 'Lunedì - Giro costiera',
        balance: 246.8,
      ),
      Customer(
        id: 'c-002',
        code: 'CL-1002',
        businessName: 'Market Verdi',
        address: 'Corso Italia 55',
        city: 'Avellino',
        vatNumber: 'IT09876543210',
        visitRound: 'Mercoledì - Giro interno',
        balance: 0,
      ),
      Customer(
        id: 'c-003',
        code: 'CL-1003',
        businessName: 'Minimarket Blu',
        address: 'Piazza Garibaldi 4',
        city: 'Napoli',
        vatNumber: 'IT02468135791',
        visitRound: 'Venerdì - Giro Napoli',
        balance: 98.45,
      ),
    ]);
  }

  void _decreaseStock(List<DocumentLine> lines) {
    for (final line in lines) {
      final index = _products.indexWhere(
        (product) => product.id == line.product.id,
      );
      if (index >= 0) {
        final stock = (_products[index].stock - line.quantity).clamp(0, 999999);
        _products[index] = _products[index].copyWith(stock: stock);
      }
    }
  }

  void _increaseCustomerBalance(Customer customer, double amount) {
    final index = _customers.indexWhere((item) => item.id == customer.id);
    if (index >= 0) {
      _customers[index] = _customers[index].copyWith(
        balance: _customers[index].balance + amount,
      );
    }
  }

  void _enqueue(String description, String? pdfPath) {
    _syncQueue.insert(
      0,
      SyncQueueItem(
        id: _uuid.v4(),
        description: description,
        createdAt: DateTime.now(),
        pdfPath: pdfPath,
        status: SyncStatus.daSincronizzare,
      ),
    );
  }

  String _nextDocumentNumber(DocumentKind kind) {
    final prefix = switch (kind) {
      DocumentKind.ddtContoProprio => 'V',
      DocumentKind.ddtContoTerzi => 'T',
      DocumentKind.movimentoMagazzino => 'M',
    };
    return '$prefix-${DateTime.now().year}-${(_documents.length + 1).toString().padLeft(5, '0')}';
  }

  bool _matchesDailyPassword(String password) =>
      _hashPassword(password) == _settings.dailyPasswordHash;

  static String _dailyPasswordFor(DateTime date) =>
      'SEDE-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  static String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}
