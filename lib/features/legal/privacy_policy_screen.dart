import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';
import 'terms_conditions_screen.dart';

/// Privacy Policy screen for Budget Buddy.
/// IMPORTANT: This is a draft for legal review only. It does NOT constitute
/// legal advice and does not guarantee compliance with any jurisdiction.
/// Consult a qualified lawyer before publishing.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.surfaceBorder),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colors),
              const SizedBox(height: AppSpacing.xl),

              _buildDraftNotice(colors),
              const SizedBox(height: AppSpacing.xl),

              _buildSection(colors, '1. Introduction',
                  'Budget Buddy ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains what information we collect when you use the Budget Buddy application ("the Application"), how we use it, how it is stored, and your rights regarding your personal data.\n\nThis policy applies to data processed when you use our Application on your mobile device. By using the Application, you agree to the practices described in this Privacy Policy.'),

              _buildSection(colors, '2. Information We Collect',
                  'We collect the following categories of information:\n\na) Account and Profile Information\nWhen you create an account, we collect your email address and any display name you provide. Supabase Authentication manages your credentials.\n\nb) Transactions, Budgets, Loans, and Savings Goals\nYou voluntarily enter financial transactions (income and expenses), budget allocations, loan details (principal, interest rate, tenure, repayments), and savings goal data. This data is stored to power the core features of the Application.\n\nc) Investment Portfolio Information\nYou may manually enter investment records including investment name, type, amount invested, current value, and valuation updates. The Application does not retrieve live market prices automatically.\n\nd) AI Coach Inputs and Responses\nText messages you send to the AI Coach feature are processed by a third-party AI service provider. Both your input and the AI-generated response may be stored to maintain conversation history within the Application.\n\ne) Device and Diagnostic Information\nThe Application may collect basic diagnostic information to support crash reporting and stability improvements. This may include your device model, operating system version, and Application version. We do not collect precise location data.'),

              _buildSection(colors, '3. How We Use Your Information',
                  'We use the information you provide to:\n• Display your financial data within the Application\n• Calculate budgets, EMIs, investment returns, and other financial summaries\n• Sync your data across devices when you are signed in\n• Process AI coaching queries through our AI service provider\n• Send notifications if you enable them (e.g., budget alerts, EMI reminders)\n• Improve the reliability and performance of the Application\n• Comply with applicable legal obligations\n\nWe do not sell your personal data to third parties for marketing or advertising purposes.'),

              _buildSection(colors, '4. How Your Data Is Stored',
                  'Budget Buddy uses a combination of local device storage and cloud storage:\n\na) Local Storage (Hive)\nFinancial records are stored locally on your device using Hive, a Flutter-compatible local database. Local data persists between app sessions and is available offline.\n\nb) Cloud Storage (Supabase)\nWhen you are signed in with an account, your data is synchronized to Supabase cloud infrastructure. Supabase stores your data in managed PostgreSQL databases with Row-Level Security (RLS) policies that ensure each user can only access their own data.'),

              _buildSection(colors, '5. Third-Party Service Providers',
                  'a) Supabase\nSupabase provides the database, authentication, and backend API infrastructure for the Application. Your financial data and account information are stored in Supabase-managed infrastructure. For information on Supabase data practices, refer to the Supabase Privacy Policy at https://supabase.com/privacy.\n\nb) AI Service Providers\nThe AI Coach feature transmits your messages to a third-party AI provider for processing. We do not control how the AI provider uses data submitted to its API. You should not submit sensitive personal or financial information that you would not want shared with an AI processing service.\n\nc) Google Fonts and Open-Source Libraries\nThe Application uses Google Fonts for typography. Font loading may contact Google servers. Other open-source libraries are bundled within the Application and do not transmit data independently.'),

              _buildSection(colors, '6. Data Sharing and Disclosure',
                  'We do not sell, rent, or trade your personal data. We may share your information only in the following limited circumstances:\n• With Supabase and our AI service provider as described above to deliver Application functionality\n• If required by applicable law, court order, or governmental authority\n• To protect the rights, property, or safety of [PLACEHOLDER: COMPANY NAME], our users, or the public\n• In connection with a merger, acquisition, or sale of all or substantially all of our assets, with prior notice to affected users\n\nWe do not share your financial data with banks, insurers, advertising networks, or data brokers.'),

              _buildSection(colors, '7. Data Retention',
                  'We retain your account and financial data for as long as your account is active. If you delete your account, we will delete or anonymize your personal data within a reasonable period, subject to:\n• Legal or regulatory obligations requiring data retention for a specified period\n• Backup and archival processes that may retain data briefly after deletion requests are processed\n\nLocally stored data on your device is not automatically deleted when you delete your account. You must also uninstall the Application or clear Application storage to remove local data.'),

              _buildSection(colors, '8. Account Deletion and Data Deletion Requests',
                  'You can delete your account from the Application\'s Profile section at any time. Account deletion will:\n• Remove your account from Supabase authentication\n• Delete your cloud-synced financial records\n• Not automatically remove locally cached data from your device\n\nTo request complete deletion of your data or to ask questions about stored data, contact us at:\nEmail: [PLACEHOLDER: support@yourapp.com]\n\nWe will process deletion requests within [PLACEHOLDER: e.g., 30 days] of receiving them.'),

              _buildSection(colors, '9. Your Privacy Rights',
                  'Depending on your jurisdiction, you may have the following rights regarding your personal data:\n• Right to access the personal data we hold about you\n• Right to correct inaccurate data\n• Right to request deletion of your data\n• Right to data portability\n• Right to withdraw consent for data processing\n• Right to lodge a complaint with a data protection authority\n\nTo exercise these rights, contact us at [PLACEHOLDER: support@yourapp.com]. We will respond to requests within the timeframes required by applicable law.'),

              _buildSection(colors, '10. Data Security Measures',
                  'We implement reasonable technical and organizational security measures to protect your information, including:\n• Row-Level Security (RLS) on Supabase database tables to enforce user data isolation\n• HTTPS encryption for data transmitted between the Application and Supabase\n• Authentication tokens managed by Supabase to prevent unauthorized access\n\nHowever, no method of electronic transmission or storage is 100% secure. We cannot guarantee absolute security of your data.'),

              _buildSection(colors, '11. Children\'s Privacy',
                  'Budget Buddy is not intended for use by individuals under the age of 18. We do not knowingly collect personal information from children under 18. If you believe a child has provided us with personal information, please contact us at [PLACEHOLDER: support@yourapp.com] and we will take steps to delete such information.'),

              _buildSection(colors, '12. Changes to This Privacy Policy',
                  'We may update this Privacy Policy from time to time. When we make material changes, we will notify you through the Application or by other means. Your continued use of the Application after changes are published constitutes your acceptance of the revised Privacy Policy.\n\nWe encourage you to review this Privacy Policy periodically.'),

              _buildSection(colors, '13. Contact Information',
                  'If you have questions or concerns about this Privacy Policy or our data practices, please contact us:\n\nEmail: [PLACEHOLDER: support@yourapp.com]\nAddress: [PLACEHOLDER: Company address]\n\n[PLACEHOLDER: COMPANY NAME] is the data controller responsible for your personal data processed through the Budget Buddy Application.'),

              // Terms link
              const SizedBox(height: AppSpacing.xl),
              _buildLegalLink(context, colors, () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const TermsConditionsScreen(),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.xxl),

              Center(
                child: Text(
                  'Last updated: October 2026',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BudgetColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.accentMint.withAlpha(26),
            borderRadius: AppRadius.lgAll,
          ),
          child: Icon(Icons.privacy_tip_outlined, color: colors.accentMint, size: 28),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Privacy Policy',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Budget Buddy Personal Finance Application',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDraftNotice(BudgetColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: Colors.amber.withAlpha(128)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'DRAFT FOR LEGAL REVIEW: This policy contains placeholder information ([PLACEHOLDER:...]) that must be replaced with actual business and service details before publication. This does not constitute legal advice.',
              style: TextStyle(
                color: Colors.amber.shade300,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BudgetColors colors, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.accentMint,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(BuildContext context, BudgetColors colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: colors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.gavel_rounded, color: colors.accentMint, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Read our Terms & Conditions',
                style: TextStyle(
                  color: colors.accentMint,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
