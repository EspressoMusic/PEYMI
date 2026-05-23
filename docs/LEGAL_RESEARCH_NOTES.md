# Legal research notes — Peymiz pilot

> **Disclaimer:** This is a pilot-ready legal/privacy structure and not legal advice. Before full public launch or paid launch, the documents should be reviewed by a qualified lawyer.

## Sources reviewed (official / primary)

| Source | URL | What we used |
|--------|-----|----------------|
| **ICO (UK)** — How to write a privacy notice | https://ico.org.uk/for-organisations/advice-for-small-organisations/privacy-notices-and-cookies/how-to-write-a-privacy-notice-and-what-goes-in-it | Contact details, categories of data, purposes, sharing, retention, plain language, individual rights and complaints |
| **ICO** — What privacy information to provide | https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/individual-rights/the-right-to-be-informed/what-privacy-information-should-we-provide | Transparency checklist for privacy notice content |
| **FTC** — Protecting Personal Information: A Guide for Business | https://business.ftc.gov/business-guidance/resources/protecting-personal-information-guide-business | Take stock, scale down, lock it, pitch it, plan ahead — reflected in security section |
| **FTC** — Data Security | https://www.ftc.gov/business-guidance/privacy-security/data-security | Reasonable safeguards language (no over-claim) |
| **California OAG / CCPA** | https://oag.ca.gov/privacy/ccpa | Privacy policy categories, purposes, third parties; no “sale” claim |
| **CPPA** — General notices (PDF) | https://cppa.ca.gov/pdf/general_notices.pdf | Notice-at-collection concepts (summarized in research; full notice-at-collection UI deferred) |
| **Israel — Privacy Protection Authority** | https://www.gov.il/en/departments/the_privacy_protection_authority/govil-landing-page | Duty to inform on collection/purpose/sharing; informed consent standards |
| **Supabase** — Security & privacy docs | https://supabase.com/docs/guides/platform/shared-responsibility-model | Processor role, client uses anon key + RLS, secrets server-side |

We did **not** claim full GDPR, UK GDPR, CCPA, or Israeli law compliance in the published drafts.

## Requirements mapped to implementation

| Requirement area | Relevant guidance | Implemented |
|------------------|-------------------|-------------|
| Privacy Policy content | ICO, CCPA policy elements | `docs/privacy-policy.html`, `assets/legal/privacy_policy_en.txt` |
| Terms of Use | General contract + pilot disclaimers | `docs/terms-of-use.html`, `assets/legal/terms_of_use_en.txt` |
| Data collection disclosure | ICO, Israel PPA duty to inform | Sections 3–5 in Privacy Policy |
| Access / correction / deletion | GDPR/ICO rights; CCPA consumer rights (described generically) | Section 11 + contact email |
| Data security | FTC, Supabase shared responsibility | Section 9 Privacy Policy |
| Third-party processors | ICO recipients; CCPA categories | Section 8 (Supabase, SMS, Stripe when enabled) |
| International users | ICO transfers; general disclosure | Section 12 |
| Pilot / beta disclaimer | Best practice (not a statute) | Banner in both documents + app viewer |
| No sale of personal data | CCPA “sale/share” transparency | Explicit statement in Privacy Policy |
| Owner acceptance before business | Israel informed consent; general practice | Checkbox on Create Store + `legal_acceptances` table |
| Versioning | Change management | `pilot-v1` in DB and documents |
| In-app access | ICO “easily accessible” | Links on Sign up, Create Store, Settings |
| Public web access | CCPA “posted” policy | Footer links on `docs/index.html` |

## What still needs lawyer review before full launch

- [ ] Confirm **controller / processor** roles (Peymiz vs each business for customer data)
- [ ] **Lawful bases** under GDPR (contract, legitimate interests, consent) per processing activity
- [ ] **Data Processing Agreement** with Supabase and SMS/payment vendors
- [ ] **International transfers** mechanism (SCCs, UK IDTA, etc.)
- [ ] **CCPA/CPRA** notice at collection, “Do Not Sell or Share,” retention periods per category
- [ ] **Israeli** registration/database requirements if applicable to operator
- [ ] **Children’s** data and age thresholds per market
- [ ] **Governing law, venue, dispute resolution** in Terms
- [ ] **Paid plan** billing, refunds, chargebacks, tax
- [ ] **Breach notification** playbook and timelines
- [ ] **Cookie / analytics** notice if tracking added to web landing
- [ ] Hebrew (and other locale) translations of legal text
- [ ] Whether business owners need a **separate** privacy notice to *their* customers

## Repository artifacts

| File | Purpose |
|------|---------|
| `docs/privacy-policy.html` | GitHub Pages / public web |
| `docs/terms-of-use.html` | GitHub Pages / public web |
| `assets/legal/*.txt` | In-app full-text viewer |
| `lib/core/legal_versions.dart` | Version constants |
| `supabase/migrations/20260520130000_legal_acceptances.sql` | Acceptance storage |

## Applying the database migration

Run in Supabase SQL Editor or:

```powershell
.\tools\apply_supabase_sql.ps1 -File supabase\migrations\20260520130000_legal_acceptances.sql
```
