# Privacy Policy

**Effective Date:** January 14, 2026  
**Last Updated:** January 14, 2026

## Introduction

Payables ("we", "our", or "the app") is a subscription and bill tracking application developed by **Jhay EL**. We are committed to protecting your privacy and ensuring transparency about how your data is handled.

**In short: We don't collect your data. Everything stays on your device.**

---

## Data Collection & Storage

### What We Store
- **Payment/subscription details** you enter (names, amounts, due dates, categories)
- **App preferences** (theme, currency, notification settings)
- **Custom icons and categories** you create

### Where We Store It
- **All data is stored locally on your device** using encrypted storage
- Data is protected using **AES-256-GCM encryption** via Android's EncryptedSharedPreferences
- We do **NOT** have access to your data

### What We Don't Collect
- ❌ Personal identification information
- ❌ Location data
- ❌ Contact information
- ❌ Usage analytics or behavior tracking
- ❌ Advertising identifiers

---

## Third-Party Services

Payables connects to the following external services:

| Service | Purpose | Data Sent |
|:--------|:--------|:----------|
| **BrandFetch API** | Fetch company logos | Domain names only (e.g., "netflix.com") |
| **FreeCurrencyAPI** | Currency exchange rates | Currency codes only (e.g., "USD", "EUR") |
| **Google Drive API** | Optional cloud backup | Your backup file (encrypted, user-initiated) |

**No personal financial data is transmitted to these services.**

---

## Google Drive Backup

If you choose to enable cloud backup:
- Backups are stored in your **personal Google Drive** app-specific folder
- Only you and this app can access the backup file
- You can delete backups at any time from within the app or Google Drive
- We cannot access your Google Drive or backup files

---

## Permissions Used

| Permission | Why We Need It |
|:-----------|:---------------|
| **Internet** | Currency exchange rates, logo fetching, Google Drive backup |
| **Notifications** | Payment reminder alerts |
| **Exact Alarm** | Precise scheduling of payment reminders |
| **Boot Completed** | Reschedule reminders after device restart |

---

## Your Rights (GDPR Aligned)

You have full control over your data:

- **Right to Access**: View all stored data within the app
- **Right to Erasure**: Delete individual items or wipe all data via Settings → Erase Data
- **Right to Portability**: Export your data using Backup feature (JSON, CSV, PDF)
- **Right to Restrict**: Pause notifications without deleting data

---

## Data Security

- **Encryption**: Sensitive preferences encrypted with AES-256-GCM
- **Local Storage**: Data stored only on your device
- **No Analytics**: We don't use tracking or analytics SDKs
- **No Ads**: No advertising networks or data brokers
- **Open Source**: [View our source code](https://github.com/Jhay-EL/Payables) to verify our practices

---

## Children's Privacy

Payables is not designed for or directed at children under 13. We do not knowingly collect information from children.

---

## Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated "Last Updated" date.

---

## Contact Us

If you have questions about this Privacy Policy:

- **Email:** [jl.temporary@outlook.it](mailto:jl.temporary@outlook.it)
- **GitHub:** [github.com/Jhay-EL/Payables](https://github.com/Jhay-EL/Payables)

---

## Open Source

Payables is open source under the MIT License. You can review, audit, and verify exactly how your data is handled by visiting our [GitHub repository](https://github.com/Jhay-EL/Payables).

---

*This privacy policy is designed to be transparent and human-readable. We believe you have the right to know exactly what happens with your data.*
