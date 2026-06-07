class ZebraRw420Printer {
  const ZebraRw420Printer({
    required this.id,
    required this.name,
    required this.macAddress,
  });

  final String id;
  final String name;
  final String macAddress;
}

class PrintResult {
  const PrintResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class ZebraRw420PrintService {
  final List<ZebraRw420Printer> pairedPrinters = const [
    ZebraRw420Printer(
      id: 'rw420-demo',
      name: 'Zebra RW420 - automezzo',
      macAddress: '00:22:58:RW:420',
    ),
  ];

  Future<PrintResult> printPdf({
    required String pdfPath,
    required ZebraRw420Printer printer,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return PrintResult(
      success: true,
      message:
          'PDF inviato a ${printer.name}. Adapter pronto per canale nativo Bluetooth Zebra RW420.',
    );
  }
}
