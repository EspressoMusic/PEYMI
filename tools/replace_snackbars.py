import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
files = [
    'lib/saas/widgets/store_mode_selector.dart',
    'lib/manager_action_pages.dart',
    'lib/saas/saas_flow.dart',
    'lib/saas/widgets/owner_payment_settings_panel.dart',
    'lib/saas/widgets/customer_payment_instructions.dart',
    'lib/saas/screens/app_creator_dashboard_screen.dart',
    'lib/widgets/customer_appointment_history_tab.dart',
    'lib/saas/screens/appointment_booking_screen.dart',
    'lib/saas/widgets/owner_appointment_panel.dart',
    'lib/saas/screens/public_appointment_screen.dart',
    'lib/saas/screens/phone_verification_screen.dart',
    'lib/saas/screens/super_admin_screen.dart',
    'lib/widgets/legal_document_screen.dart',
    'lib/saas/widgets/super_admin_gate.dart',
]

import_map = {
    'lib/saas/widgets/': '../../widgets/bakery_celebration.dart',
    'lib/saas/screens/': '../../widgets/bakery_celebration.dart',
    'lib/saas/': '../widgets/bakery_celebration.dart',
    'lib/manager_action_pages.dart': 'widgets/bakery_celebration.dart',
    'lib/widgets/': 'bakery_celebration.dart',
}

pat = re.compile(
    r'ScaffoldMessenger\.of\(([^)]+)\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\),?\s*\)\s*,?\s*\)\s*;',
    re.MULTILINE,
)

for rel in files:
    p = ROOT / rel
    if not p.exists():
        print('missing', rel)
        continue
    text = p.read_text(encoding='utf-8')
    new_text = pat.sub(
        r'unawaited(showBakeryNoticeBanner(\1, title: \2, isError: true));',
        text,
    )
    if new_text == text:
        continue
    if 'bakery_celebration.dart' not in new_text:
        imp = next(v for k, v in import_map.items() if rel.startswith(k) or rel.endswith(k.replace('lib/', '')))
        if "import 'dart:async';" not in new_text:
            new_text = new_text.replace(
                "import 'package:flutter/material.dart';",
                "import 'dart:async';\n\nimport 'package:flutter/material.dart';",
                1,
            )
        new_text = new_text.replace(
            "import 'package:flutter/material.dart';",
            f"import 'package:flutter/material.dart';\nimport '{imp}';",
            1,
        )
    p.write_text(new_text, encoding='utf-8')
    print('updated', rel)
