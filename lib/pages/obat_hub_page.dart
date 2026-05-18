import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/widgets/domain_tab_navigation.dart';
import '../core/widgets/keep_alive_tab.dart';
import 'obat_keluar_page.dart';
import 'obat_masuk_page.dart';
import 'obat_page.dart';
import 'sinkronisasi_stok_page.dart';

class ObatHubPage extends StatefulWidget {
  const ObatHubPage({super.key});

  static const routeName = '/obat-hub';

  @override
  State<ObatHubPage> createState() => _ObatHubPageState();
}

class _ObatHubPageState extends State<ObatHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = cprimary(context);

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Data Obat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Sinkronisasi Stok',
            onPressed: () =>
                Navigator.pushNamed(context, SinkronisasiStokPage.routeName),
            icon: Icon(
              AppSymbols.refresh,
              color: conPrimary(context),
              size: 20,
            ),
          ),
        ],
        backgroundColor: primaryColor,
        foregroundColor: conPrimary(context),
        elevation: 0,
        bottom: DomainTabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Master Obat'),
            Tab(text: 'Obat Masuk'),
            Tab(text: 'Pengeluaran Stok'),
          ],
        ),
      ),
      body: SwipeableTabBarView(
        controller: _tabController,
        children: const [
          KeepAliveTab(child: ObatTabContent()),
          KeepAliveTab(child: ObatMasukPage()),
          KeepAliveTab(child: ObatKeluarPage()),
        ],
      ),
    );
  }
}
