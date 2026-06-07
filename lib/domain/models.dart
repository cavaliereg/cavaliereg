import 'dart:typed_data';

enum DocumentKind { ddtContoProprio, ddtContoTerzi, movimentoMagazzino }

enum MovementReason {
  resoScaduto,
  resoTecnico,
  trasferimentoDepositiViaggianti,
}

enum PaymentMethod { contanti, carta, bancomat, bonifico, altroElettronico }

enum SyncStatus { sincronizzato, daSincronizzare, errore }

extension DocumentKindLabel on DocumentKind {
  String get label => switch (this) {
    DocumentKind.ddtContoProprio => 'DDT vendita conto proprio',
    DocumentKind.ddtContoTerzi => 'DDT conto terzi',
    DocumentKind.movimentoMagazzino => 'DDT movimentazione merci',
  };

  bool get showsPrices => this == DocumentKind.ddtContoProprio;
}

extension MovementReasonLabel on MovementReason {
  String get label => switch (this) {
    MovementReason.resoScaduto => 'Reso scaduto',
    MovementReason.resoTecnico => 'Reso tecnico',
    MovementReason.trasferimentoDepositiViaggianti =>
      'Trasferimento tra depositi viaggianti',
  };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.contanti => 'Contanti',
    PaymentMethod.carta => 'Carta',
    PaymentMethod.bancomat => 'Bancomat',
    PaymentMethod.bonifico => 'Bonifico',
    PaymentMethod.altroElettronico => 'Altro elettronico',
  };
}

extension SyncStatusLabel on SyncStatus {
  String get label => switch (this) {
    SyncStatus.sincronizzato => 'Sincronizzato',
    SyncStatus.daSincronizzare => 'Da sincronizzare',
    SyncStatus.errore => 'Errore sync',
  };
}

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.price,
    required this.vatRate,
    required this.stock,
    required this.imageSeed,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final double price;
  final double vatRate;
  final int stock;
  final String imageSeed;

  Product copyWith({int? stock}) => Product(
    id: id,
    code: code,
    name: name,
    description: description,
    price: price,
    vatRate: vatRate,
    stock: stock ?? this.stock,
    imageSeed: imageSeed,
  );
}

class Customer {
  const Customer({
    required this.id,
    required this.code,
    required this.businessName,
    required this.address,
    required this.city,
    required this.vatNumber,
    required this.visitRound,
    required this.balance,
  });

  final String id;
  final String code;
  final String businessName;
  final String address;
  final String city;
  final String vatNumber;
  final String visitRound;
  final double balance;

  Customer copyWith({double? balance}) => Customer(
    id: id,
    code: code,
    businessName: businessName,
    address: address,
    city: city,
    vatNumber: vatNumber,
    visitRound: visitRound,
    balance: balance ?? this.balance,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Customer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class VehicleSettings {
  const VehicleSettings({
    required this.plate,
    required this.zoneAgent,
    required this.travelingDepot,
  });

  final String plate;
  final String zoneAgent;
  final String travelingDepot;

  VehicleSettings copyWith({
    String? plate,
    String? zoneAgent,
    String? travelingDepot,
  }) => VehicleSettings(
    plate: plate ?? this.plate,
    zoneAgent: zoneAgent ?? this.zoneAgent,
    travelingDepot: travelingDepot ?? this.travelingDepot,
  );
}

class AppSettings {
  const AppSettings({
    required this.agentName,
    required this.agentCode,
    required this.companyName,
    required this.companyVat,
    required this.companyAddress,
    required this.vehicle,
    required this.dailyPasswordHash,
    this.agentSignature,
  });

  final String agentName;
  final String agentCode;
  final String companyName;
  final String companyVat;
  final String companyAddress;
  final VehicleSettings vehicle;
  final String dailyPasswordHash;
  final Uint8List? agentSignature;

  AppSettings copyWith({
    String? agentName,
    String? agentCode,
    String? companyName,
    String? companyVat,
    String? companyAddress,
    VehicleSettings? vehicle,
    String? dailyPasswordHash,
    Uint8List? agentSignature,
  }) => AppSettings(
    agentName: agentName ?? this.agentName,
    agentCode: agentCode ?? this.agentCode,
    companyName: companyName ?? this.companyName,
    companyVat: companyVat ?? this.companyVat,
    companyAddress: companyAddress ?? this.companyAddress,
    vehicle: vehicle ?? this.vehicle,
    dailyPasswordHash: dailyPasswordHash ?? this.dailyPasswordHash,
    agentSignature: agentSignature ?? this.agentSignature,
  );
}

class DocumentLine {
  const DocumentLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get total => product.price * quantity;
}

class SalesDocument {
  const SalesDocument({
    required this.id,
    required this.number,
    required this.kind,
    required this.customer,
    required this.lines,
    required this.createdAt,
    required this.syncStatus,
    required this.printed,
    required this.cancelled,
    this.movementReason,
    this.customerSignature,
    this.pdfPath,
  });

  final String id;
  final String number;
  final DocumentKind kind;
  final Customer customer;
  final List<DocumentLine> lines;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final bool printed;
  final bool cancelled;
  final MovementReason? movementReason;
  final Uint8List? customerSignature;
  final String? pdfPath;

  double get total => lines.fold<double>(0, (sum, line) => sum + line.total);

  int get totalPieces => lines.fold<int>(0, (sum, line) => sum + line.quantity);

  SalesDocument copyWith({
    SyncStatus? syncStatus,
    bool? printed,
    bool? cancelled,
    Uint8List? customerSignature,
    String? pdfPath,
  }) => SalesDocument(
    id: id,
    number: number,
    kind: kind,
    customer: customer,
    lines: lines,
    createdAt: createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    printed: printed ?? this.printed,
    cancelled: cancelled ?? this.cancelled,
    movementReason: movementReason,
    customerSignature: customerSignature ?? this.customerSignature,
    pdfPath: pdfPath ?? this.pdfPath,
  );
}

class Payment {
  const Payment({
    required this.id,
    required this.customer,
    required this.amount,
    required this.method,
    required this.createdAt,
    required this.syncStatus,
    this.electronicReference,
    this.receiptPdfPath,
  });

  final String id;
  final Customer customer;
  final double amount;
  final PaymentMethod method;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final String? electronicReference;
  final String? receiptPdfPath;

  Payment copyWith({SyncStatus? syncStatus, String? receiptPdfPath}) => Payment(
    id: id,
    customer: customer,
    amount: amount,
    method: method,
    createdAt: createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    electronicReference: electronicReference,
    receiptPdfPath: receiptPdfPath ?? this.receiptPdfPath,
  );
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.pdfPath,
    required this.status,
  });

  final String id;
  final String description;
  final DateTime createdAt;
  final String? pdfPath;
  final SyncStatus status;

  SyncQueueItem copyWith({SyncStatus? status}) => SyncQueueItem(
    id: id,
    description: description,
    createdAt: createdAt,
    pdfPath: pdfPath,
    status: status ?? this.status,
  );
}
