import 'package:flutter/material.dart';
import '../../app/theme/design_tokens.dart';

/// Terms & Conditions screen for Budget Buddy.
/// IMPORTANT: This is a draft for legal review only. It does NOT constitute
/// legal advice and does not guarantee compliance with any jurisdiction.
/// Consult a qualified lawyer before publishing.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          'Terms & Conditions',
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
              // Header
              _buildHeader(colors),
              const SizedBox(height: AppSpacing.xl),

              // Draft Notice
              _buildDraftNotice(colors),
              const SizedBox(height: AppSpacing.xl),

              _buildSection(colors, '1. Introduction and Acceptance of Terms',
                  'Welcome to Budget Buddy ("the Application," "we," "us," or "our"). By downloading, installing, or using the Application, you agree to be bound by these Terms & Conditions ("Terms"). If you do not agree, please do not use the Application.\n\nThese Terms govern your use of Budget Buddy, a personal finance tracking application designed to help users manage budgets, track expenses and income, plan loans, and monitor investments.'),

              _buildSection(colors, '2. Eligibility and Account Responsibilities',
                  'The Application is intended for users who are at least 18 years of age, or the age of majority in their jurisdiction, whichever is higher. By using the Application, you represent that you meet this requirement.\n\nYou are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must notify us immediately if you suspect any unauthorized use of your account.'),

              _buildSection(colors, '3. Account Security',
                  'You are responsible for keeping your password and account information secure. The Application uses Supabase authentication services to manage user accounts. You must not share your account credentials with others or allow unauthorized persons to access your account.\n\nWe implement reasonable technical security measures, but we cannot guarantee that unauthorized third parties will never be able to defeat those measures.'),

              _buildSection(colors, '4. App Features and Permitted Usage',
                  'Budget Buddy provides tools including:\n• Expense and income tracking\n• Budget management\n• Loan and EMI calculation\n• Investment portfolio tracking\n• AI-powered financial coaching\n• Savings goal planning\n\nYou may use the Application only for lawful personal finance management purposes. You must not use the Application for any commercial, fraudulent, or illegal purpose, or in any way that violates applicable laws or regulations.'),

              _buildSection(colors, '5. User Responsibilities and Accurate Data Entry',
                  'You are solely responsible for the accuracy, completeness, and integrity of all financial data you enter into the Application. Budget Buddy displays results based on the information you provide. Incorrect data entry will produce incorrect results.\n\nYou agree to:\n• Enter accurate and truthful financial information\n• Keep your financial data current\n• Not enter false or misleading data that could affect calculations\n• Verify all important calculations independently before relying on them for financial decisions'),

              _buildSection(colors, '6. Personal Finance Tracking Limitations',
                  'Budget Buddy is a personal finance tracking tool only. The Application:\n• Does not connect to your bank accounts automatically unless you explicitly configure such integration\n• Does not verify the accuracy of data you enter\n• Cannot guarantee that calculations reflect your actual financial position with any financial institution\n• May not account for all fees, charges, taxes, or other factors relevant to your specific situation\n\nAll balances, projections, and summaries displayed are based solely on data you enter manually.'),

              _buildSection(colors, '7. Investment Information Disclaimer',
                  'IMPORTANT: Budget Buddy is not a registered investment advisor, broker-dealer, or financial planner. Any investment-related information, calculations, or projections provided by the Application are for informational and illustrative purposes only.\n\nThe Application does not provide regulated investment advice. Investment tracking features are provided to help you organize your personal records. They do not constitute a recommendation to buy, sell, or hold any investment.\n\nPast performance data or projections shown are illustrative only and do not guarantee future results. All investments involve risk, including the possible loss of principal. Consult a qualified financial advisor before making any investment decisions.'),

              _buildSection(colors, '8. Loan and EMI Calculation Disclaimer',
                  'Loan and EMI calculations provided by the Application use standard amortization formulas for illustrative purposes only. These calculations:\n• Are based solely on the values you enter\n• May differ from calculations performed by your actual lender due to rounding conventions, processing fees, insurance, prepayment terms, or lender-specific methods\n• Do not constitute a loan offer, pre-approval, or binding agreement of any kind\n\nAlways consult your lender for official repayment schedules and outstanding balances.'),

              _buildSection(colors, '9. AI-Generated Information Disclaimer',
                  'Budget Buddy includes an AI-powered coaching feature. AI-generated responses:\n• Are generated by third-party AI services and are not reviewed by financial professionals\n• May contain errors, inaccuracies, or outdated information\n• Do not constitute professional financial, tax, legal, or investment advice\n• Should not be relied upon as a substitute for advice from a qualified professional\n\nYou assume full responsibility for any decisions made based on AI-generated content.'),

              _buildSection(colors, '10. Third-Party Services',
                  'The Application uses third-party services including:\n• Supabase (database and authentication services)\n• AI service providers for the coaching feature\n• Google Fonts and other open-source libraries\n\nYour use of the Application is also subject to the terms and privacy policies of these third-party providers. We are not responsible for the practices of third-party services.'),

              _buildSection(colors, '11. Data Availability and Service Interruptions',
                  'We do not guarantee that the Application will be available at all times. The Application may experience downtime due to maintenance, technical issues, or circumstances beyond our control. Data synchronization may be interrupted during network outages.\n\nLocal data stored on your device is subject to device storage limitations and may be lost if you uninstall the Application or if device storage is cleared.'),

              _buildSection(colors, '12. Limitation of Liability',
                  'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, [PLACEHOLDER: COMPANY NAME] AND ITS AFFILIATES, OFFICERS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APPLICATION.\n\nOur total liability to you for any claims arising from your use of the Application shall not exceed the amount you have paid (if any) to access the Application in the preceding twelve months.\n\nSome jurisdictions do not allow limitations on certain implied warranties or liability, so the above limitations may not fully apply to you.'),

              _buildSection(colors, '13. Changes to These Terms',
                  'We reserve the right to modify these Terms at any time. We will notify users of material changes through the Application or other reasonable means. Your continued use of the Application after changes are published constitutes your acceptance of the revised Terms.\n\nWe recommend reviewing these Terms periodically.'),

              _buildSection(colors, '14. Account Termination',
                  'You may delete your account at any time from the Profile section of the Application. Upon deletion, your account data will be removed from our servers subject to our data retention practices and applicable legal obligations.\n\nWe reserve the right to suspend or terminate accounts that violate these Terms, engage in fraudulent activity, or are inactive for an extended period, with reasonable prior notice where required by law.'),

              _buildSection(colors, '15. Governing Law',
                  'These Terms shall be governed by the laws of [PLACEHOLDER: JURISDICTION]. Any disputes arising from these Terms or your use of the Application shall be subject to the exclusive jurisdiction of the courts of [PLACEHOLDER: JURISDICTION].\n\nIf any provision of these Terms is found to be unenforceable, the remaining provisions will continue in full force and effect.'),

              _buildSection(colors, '16. Contact and Support',
                  'If you have questions about these Terms, please contact us at:\n\nEmail: [PLACEHOLDER: support@yourapp.com]\nAddress: [PLACEHOLDER: Company address]\n\nWe aim to respond to inquiries within a reasonable timeframe.'),

              // Privacy Policy Link
              const SizedBox(height: AppSpacing.xl),
              _buildLegalLink(context, colors, theme,
                  'Read our Privacy Policy',
                  Icons.privacy_tip_outlined, () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const _PrivacyPolicyPlaceholder(),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.xxl),

              // Last Updated
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
          child: Icon(Icons.gavel_rounded, color: colors.accentMint, size: 28),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Terms & Conditions',
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
              'DRAFT FOR LEGAL REVIEW: These Terms contain placeholder information ([PLACEHOLDER:...]) that must be replaced with actual business details before publication. This draft does not constitute legal advice and should be reviewed by a qualified lawyer.',
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

  Widget _buildLegalLink(BuildContext context, BudgetColors colors, ThemeData theme,
      String label, IconData icon, VoidCallback onTap) {
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
            Icon(icon, color: colors.accentMint, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
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

/// Placeholder used when navigating from T&C to Privacy Policy inline.
/// The actual Privacy Policy screen is registered separately.
class _PrivacyPolicyPlaceholder extends StatelessWidget {
  const _PrivacyPolicyPlaceholder();

  @override
  Widget build(BuildContext context) {
    // We navigate back so the router can open the real Privacy Policy screen.
    // This widget should never be shown in production; it's a fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
