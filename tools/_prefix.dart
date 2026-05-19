      home: const RoleSelectionPage(),
    );
  }
}

const String _managerPassword = '1234';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  Future<void> _openManagerLogin(BuildContext context) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var authFailed = false;

    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('כניסת מנהל', textAlign: TextAlign.right),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'הזן סיסמת מנהל',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'סיסמה',
                      border: const OutlineInputBorder(),
                      errorText: authFailed ? 'סיסמה שגויה' : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'נא להזין סיסמה';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (formKey.currentState?.validate() ?? false) {
                        Navigator.pop(dialogContext, passwordController.text == _managerPassword);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('ביטול'),
              ),
              FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final ok = passwordController.text == _managerPassword;
                  if (!ok) {
                    authFailed = true;
                    formKey.currentState!.validate();
                    (dialogContext as Element).markNeedsBuild();
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('כניסה'),
              ),
            ],
          ),
        );
      },
    );

    passwordController.dispose();
    if (!context.mounted || approved != true) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ManagerHomePage()),
    );
  }

  void _openCustomerStore(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BakeryHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade100, Colors.brown.shade50],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.bakery_dining, size: 72, color: Colors.brown.shade700),
                  const SizedBox(height: 16),
                  const Text(
                    'מאפיית הבית',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ברוכים הבאים! מי אתם?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.brown.shade600),
                  ),
                  const Spacer(),
                  _RoleChoiceCard(
                    title: 'לקוח',
                    subtitle: 'הזמנה מהחנות, מבצעים והיסטוריה',
                    icon: Icons.storefront,
                    color: const Color(0xFF4E342E),
                    onTap: () => _openCustomerStore(context),
                  ),
                  const SizedBox(height: 14),
                  _RoleChoiceCard(
                    title: 'מנהל',
                    subtitle: 'ניהול הזמנות ומעקב אחרי החנות',
                    icon: Icons.admin_panel_settings,
                    color: const Color(0xFF6D4C41),
                    onTap: () => _openManagerLogin(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EC),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.brown.shade500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_new, color: Colors.brown.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class ManagerHomePage extends StatelessWidget {
  const ManagerHomePage({super.key});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const pendingOrders = [
      {'id': '#1104', 'customer': 'דנה כ.', 'total': '54₪', 'status': 'ממתין לאישור'},
      {'id': '#1103', 'customer': 'יוסי ל.', 'total': '89₪', 'status': 'בהכנה'},
      {'id': '#1102', 'customer': 'מיכל ר.', 'total': '35₪', 'status': 'מוכן לאיסוף'},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פאנל מנהל'),
          backgroundColor: Colors.brown.shade300,
          actions: [
            IconButton(
              tooltip: 'יציאה',
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.brown.shade100, Colors.orange.shade50],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text(
                'סקירה יומית',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ManagerStatCard(
                      label: 'הזמנות היום',
                      value: '18',
                      icon: Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ManagerStatCard(
                      label: 'בטיפול',
                      value: '5',
                      icon: Icons.pending_actions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ManagerStatCard(
                      label: 'הכנסות היום',
                      value: '1,240₪',
                      icon: Icons.payments,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ManagerStatCard(
                      label: 'דילים פעילים',
                      value: '3',
                      icon: Icons.local_offer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'הזמנות פעילות',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
              ),
              const SizedBox(height: 8),
              ...pendingOrders.map((order) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFE3CF),
                      child: Icon(Icons.shopping_bag, color: Color(0xFF4E342E)),
                    ),
                    title: Text(
                      '${order['id']} • ${order['customer']}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(order['status']!),
                    trailing: Text(
                      order['total']!,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerStatCard extends StatelessWidget {
  const _ManagerStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4E342E)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.brown.shade500)),
        ],
      ),
    );
  }
}

class BakeryHomePage extends StatefulWidget {