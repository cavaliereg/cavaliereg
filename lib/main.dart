import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import 'domain/models.dart';
import 'state/sales_app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SalesAppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tentata Vendita',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF146C43)),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  final _screens = const [
    DashboardScreen(),
    CatalogScreen(),
    VisitsScreen(),
    WarehouseScreen(),
    DocumentsScreen(),
    PaymentsScreen(),
    SyncScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Catalogo'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.route_outlined),
                label: Text('Giri'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined),
                label: Text('Magazzino'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                label: Text('DDT'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payments_outlined),
                label: Text('Cassa'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sync_outlined),
                label: Text('Sync'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('Impostazioni'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    final settings = state.settings;
    return PageScaffold(
      title: 'Tentata vendita italiana',
      subtitle:
          '${settings.agentName} • ${settings.vehicle.plate} • ${settings.vehicle.travelingDepot}',
      actions: [
        FilledButton.icon(
          onPressed: state.syncing ? null : state.synchronize,
          icon: const Icon(Icons.cloud_sync),
          label: Text(state.syncing ? 'Sincronizzo...' : 'Sincronizza sede'),
        ),
      ],
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              MetricCard(
                label: 'Prodotti a bordo',
                value: '${state.totalTravelingStock}',
                icon: Icons.inventory,
              ),
              MetricCard(
                label: 'Documenti emessi',
                value: '${state.documents.length}',
                icon: Icons.receipt_long,
              ),
              MetricCard(
                label: 'PDF da inviare',
                value: '${state.pendingSyncCount}',
                icon: Icons.picture_as_pdf,
              ),
              MetricCard(
                label: 'Cassa contanti',
                value: moneyFormat.format(state.cashBalance),
                icon: Icons.payments,
              ),
              MetricCard(
                label: 'Pagamenti elettronici',
                value: moneyFormat.format(state.electronicBalance),
                icon: Icons.credit_card,
              ),
            ],
          ),
          const SizedBox(height: 24),
          InfoPanel(
            title: 'Vincoli operativi attivi',
            children: const [
              Text(
                '• Catalogo prodotti e clienti sono solo consultabili: arrivano dalla sede.',
              ),
              Text(
                '• I DDT conto terzi vengono stampati senza prezzi visibili.',
              ),
              Text(
                '• Ogni documento genera un PDF e finisce nella coda di sincronizzazione.',
              ),
              Text(
                '• Annullare documenti diversi dall’ultimo stampato richiede password giornaliera sede.',
              ),
              Text(
                '• Stampa predisposta per Zebra RW420 Bluetooth tramite adapter dedicato.',
              ),
            ],
          ),
          if (state.lastPrintMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Ultima stampa'),
                subtitle: Text(state.lastPrintMessage!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<SalesAppState>().products;
    return PageScaffold(
      title: 'Catalogo prodotti',
      subtitle:
          'Prodotti sincronizzati dalla sede, senza inserimento o cancellazione locale.',
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 210,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(
                          product.imageSeed,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product.description),
                  const Spacer(),
                  Text(
                    'Codice ${product.code} • IVA ${product.vatRate.toStringAsFixed(0)}%',
                  ),
                  Text(
                    '${moneyFormat.format(product.price)} • Disponibili ${product.stock}',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<SalesAppState>().customers;
    return PageScaffold(
      title: 'Giri visita',
      subtitle: 'Clienti assegnati dalla sede al giro dell’agente di zona.',
      child: ListView.separated(
        itemCount: customers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.storefront)),
              title: Text(customer.businessName),
              subtitle: Text(
                '${customer.address}, ${customer.city}\n${customer.visitRound}',
              ),
              trailing: Text(moneyFormat.format(customer.balance)),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class WarehouseScreen extends StatelessWidget {
  const WarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    return PageScaffold(
      title: 'Magazzino viaggiante',
      subtitle:
          '${state.settings.vehicle.travelingDepot} • targa ${state.settings.vehicle.plate}',
      actions: [
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const NewDocumentDialog(
              initialKind: DocumentKind.movimentoMagazzino,
            ),
          ),
          icon: const Icon(Icons.swap_horiz),
          label: const Text('DDT movimentazione'),
        ),
      ],
      child: ListView(
        children: state.products
            .map(
              (product) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(product.imageSeed)),
                  title: Text(product.name),
                  subtitle: Text(product.code),
                  trailing: Text(
                    '${product.stock} pezzi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    return PageScaffold(
      title: 'Documenti DDT',
      subtitle:
          'Vendita conto proprio, conto terzi senza prezzi e movimentazioni merci.',
      actions: [
        FilledButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const NewDocumentDialog(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nuovo DDT'),
        ),
      ],
      child: state.documents.isEmpty
          ? const EmptyState(
              message: 'Nessun documento emesso in questa sessione offline.',
            )
          : ListView.separated(
              itemCount: state.documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final document = state.documents[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      document.cancelled ? Icons.block : Icons.receipt_long,
                    ),
                    title: Text('${document.number} • ${document.kind.label}'),
                    subtitle: Text(
                      '${document.customer.businessName}\n'
                      '${dateFormat.format(document.createdAt)} • ${document.syncStatus.label}'
                      '${document.pdfPath == null ? '' : '\nPDF: ${document.pdfPath}'}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (document.kind.showsPrices)
                          Text(moneyFormat.format(document.total)),
                        OutlinedButton(
                          onPressed: document.cancelled
                              ? null
                              : () => _cancelDocument(context, state, document),
                          child: Text(
                            document.cancelled ? 'Annullato' : 'Annulla',
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _cancelDocument(
    BuildContext context,
    SalesAppState state,
    SalesDocument document,
  ) async {
    String? password;
    if (!state.canCancelWithoutPassword(document)) {
      password = await showDialog<String>(
        context: context,
        builder: (_) => const PasswordDialog(),
      );
      if (password == null) {
        return;
      }
    }
    try {
      await state.cancelDocument(document, password: password);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Documento ${document.number} annullato e accodato per sync.',
          ),
        ),
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }
}

class NewDocumentDialog extends StatefulWidget {
  const NewDocumentDialog({super.key, this.initialKind});

  final DocumentKind? initialKind;

  @override
  State<NewDocumentDialog> createState() => _NewDocumentDialogState();
}

class _NewDocumentDialogState extends State<NewDocumentDialog> {
  late DocumentKind _kind = widget.initialKind ?? DocumentKind.ddtContoProprio;
  MovementReason _movementReason = MovementReason.resoScaduto;
  Customer? _customer;
  final Map<String, int> _quantities = {};
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _saving = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    _customer ??= state.customers.firstOrNull;
    return AlertDialog(
      title: const Text('Nuovo documento'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<DocumentKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Tipo documento'),
                items: DocumentKind.values
                    .map(
                      (kind) => DropdownMenuItem(
                        value: kind,
                        child: Text(kind.label),
                      ),
                    )
                    .toList(),
                onChanged: widget.initialKind == null
                    ? (value) => setState(() => _kind = value ?? _kind)
                    : null,
              ),
              if (_kind == DocumentKind.movimentoMagazzino) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<MovementReason>(
                  initialValue: _movementReason,
                  decoration: const InputDecoration(
                    labelText: 'Causale movimentazione',
                  ),
                  items: MovementReason.values
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _movementReason = value ?? _movementReason,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<Customer>(
                initialValue: _customer,
                decoration: const InputDecoration(labelText: 'Cliente'),
                items: state.customers
                    .map(
                      (customer) => DropdownMenuItem(
                        value: customer,
                        child: Text(customer.businessName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _customer = value),
              ),
              const SizedBox(height: 16),
              Text(
                'Righe prodotto',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...state.products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.code} - ${product.name} (${product.stock} disp.)',
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Q.tà'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _quantities[product.id] =
                              int.tryParse(value) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Firma cliente',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                height: 130,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: _signatureController.clear,
                icon: const Icon(Icons.clear),
                label: const Text('Cancella firma'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Chiudi'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => _save(context, state),
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(_saving ? 'Emissione...' : 'Emetti, PDF e stampa'),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, SalesAppState state) async {
    final customer = _customer;
    if (customer == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final signature = await _signatureController.toPngBytes();
      final quantities = {
        for (final product in state.products)
          product: _quantities[product.id] ?? 0,
      };
      final document = await state.issueDocument(
        kind: _kind,
        customer: customer,
        quantities: quantities,
        movementReason: _kind == DocumentKind.movimentoMagazzino
            ? _movementReason
            : null,
        customerSignature: signature,
      );
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${document.number} generato con PDF e accodato per sync.',
          ),
        ),
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  Customer? _customer;
  PaymentMethod _method = PaymentMethod.contanti;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    _customer ??= state.customers.firstOrNull;
    return PageScaffold(
      title: 'Cassa e pagamenti',
      subtitle: 'Incassi contanti/elettronici, ricevute PDF ed estratti conto.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Customer>(
                      initialValue: _customer,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: state.customers
                          .map(
                            (customer) => DropdownMenuItem(
                              value: customer,
                              child: Text(customer.businessName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _customer = value),
                    ),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Importo'),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: _method,
                      decoration: const InputDecoration(labelText: 'Metodo'),
                      items: PaymentMethod.values
                          .map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _method = value ?? _method),
                    ),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Riferimento pagamento elettronico',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _registerPayment(context, state),
                            icon: const Icon(Icons.receipt),
                            label: const Text('Registra e stampa ricevuta'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _buildStatement(context, state),
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Estratto conto'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: ListView(
              children: state.payments
                  .map(
                    (payment) => Card(
                      child: ListTile(
                        leading: Icon(
                          payment.method == PaymentMethod.contanti
                              ? Icons.payments
                              : Icons.credit_card,
                        ),
                        title: Text(
                          '${payment.customer.businessName} • ${moneyFormat.format(payment.amount)}',
                        ),
                        subtitle: Text(
                          '${payment.method.label} • ${dateFormat.format(payment.createdAt)}\n'
                          '${payment.receiptPdfPath ?? 'PDF in generazione'}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _registerPayment(
    BuildContext context,
    SalesAppState state,
  ) async {
    final customer = _customer;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (customer == null || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente o importo non valido.')),
      );
      return;
    }
    try {
      await state.registerPayment(
        customer: customer,
        amount: amount,
        method: _method,
        electronicReference: _referenceController.text,
      );
      _amountController.clear();
      _referenceController.clear();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incasso registrato, ricevuta PDF accodata per sync.'),
        ),
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _buildStatement(
    BuildContext context,
    SalesAppState state,
  ) async {
    final customer = _customer;
    if (customer == null) {
      return;
    }
    final path = await state.buildStatement(customer);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Estratto conto generato: $path')));
  }
}

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    return PageScaffold(
      title: 'Sincronizzazione sede',
      subtitle:
          'Upload PDF, documenti, incassi, annullamenti e password giornaliera.',
      actions: [
        FilledButton.icon(
          onPressed: state.syncing ? null : state.synchronize,
          icon: const Icon(Icons.sync),
          label: Text(state.syncing ? 'Sincronizzo...' : 'Sincronizza ora'),
        ),
      ],
      child: state.syncQueue.isEmpty
          ? const EmptyState(
              message:
                  'Nessun elemento in coda. L’app resta operativa offline.',
            )
          : ListView.separated(
              itemCount: state.syncQueue.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = state.syncQueue[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.status == SyncStatus.sincronizzato
                          ? Icons.cloud_done
                          : Icons.cloud_upload,
                    ),
                    title: Text(item.description),
                    subtitle: Text(
                      '${dateFormat.format(item.createdAt)}\n${item.pdfPath ?? 'Record senza PDF'}',
                    ),
                    trailing: Chip(label: Text(item.status.label)),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _agentName = TextEditingController();
  final _agentCode = TextEditingController();
  final _companyName = TextEditingController();
  final _companyVat = TextEditingController();
  final _companyAddress = TextEditingController();
  final _plate = TextEditingController();
  final _zoneAgent = TextEditingController();
  final _travelingDepot = TextEditingController();
  final SignatureController _agentSignatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _initialized = false;

  @override
  void dispose() {
    _agentName.dispose();
    _agentCode.dispose();
    _companyName.dispose();
    _companyVat.dispose();
    _companyAddress.dispose();
    _plate.dispose();
    _zoneAgent.dispose();
    _travelingDepot.dispose();
    _agentSignatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SalesAppState>();
    final settings = state.settings;
    if (!_initialized) {
      _agentName.text = settings.agentName;
      _agentCode.text = settings.agentCode;
      _companyName.text = settings.companyName;
      _companyVat.text = settings.companyVat;
      _companyAddress.text = settings.companyAddress;
      _plate.text = settings.vehicle.plate;
      _zoneAgent.text = settings.vehicle.zoneAgent;
      _travelingDepot.text = settings.vehicle.travelingDepot;
      _initialized = true;
    }
    return PageScaffold(
      title: 'Impostazioni',
      subtitle:
          'Dati generali agente, azienda cedente, automezzo e firma grafica agente.',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _agentName,
                  decoration: const InputDecoration(labelText: 'Agente'),
                ),
              ),
              SizedBox(
                width: 160,
                child: TextField(
                  controller: _agentCode,
                  decoration: const InputDecoration(labelText: 'Codice agente'),
                ),
              ),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _companyName,
                  decoration: const InputDecoration(
                    labelText: 'Azienda cedente',
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _companyVat,
                  decoration: const InputDecoration(labelText: 'P.IVA azienda'),
                ),
              ),
              SizedBox(
                width: 480,
                child: TextField(
                  controller: _companyAddress,
                  decoration: const InputDecoration(
                    labelText: 'Indirizzo azienda',
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _plate,
                  decoration: const InputDecoration(
                    labelText: 'Targa automezzo',
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  controller: _zoneAgent,
                  decoration: const InputDecoration(
                    labelText: 'Agente di zona',
                  ),
                ),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _travelingDepot,
                  decoration: const InputDecoration(
                    labelText: 'Deposito viaggiante',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Firma grafica agente',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Signature(
              controller: _agentSignatureController,
              backgroundColor: Colors.white,
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _agentSignatureController.clear,
                icon: const Icon(Icons.clear),
                label: const Text('Cancella firma'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _save(context, state),
                icon: const Icon(Icons.save),
                label: const Text('Salva impostazioni offline'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const InfoPanel(
            title: 'Password giornaliera annullamenti',
            children: [
              Text(
                'La password arriva dalla sede durante la sincronizzazione giornaliera.',
              ),
              Text(
                'L’ultimo documento stampato è annullabile senza password; tutti gli altri richiedono sblocco.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, SalesAppState state) async {
    final signature = await _agentSignatureController.toPngBytes();
    state.updateSettings(
      agentName: _agentName.text,
      agentCode: _agentCode.text,
      companyName: _companyName.text,
      companyVat: _companyVat.text,
      companyAddress: _companyAddress.text,
      plate: _plate.text,
      zoneAgent: _zoneAgent.text,
      travelingDepot: _travelingDepot.text,
      agentSignature: signature,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impostazioni salvate e accodate per sincronizzazione.'),
      ),
    );
  }
}

class PasswordDialog extends StatefulWidget {
  const PasswordDialog({super.key});

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sblocco annullamento'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Password giornaliera sede',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Sblocca'),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 64),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

final moneyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
