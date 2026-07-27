import '../../features/leads/domain/entities/lead_enums.dart';

/// App-wide constants
class AppConstants {
  AppConstants._();

  // ─── App Info ──────────────────────────────────────────
  static const String appName = 'SalesHub';
  static const String appSubtitle = 'Prospecting Pro';
  static const String appTagline = 'High-Performance CRM';

  // ─── Pagination ────────────────────────────────────────
  static const int defaultPageSize = 25;
  static const List<int> pageSizeOptions = [10, 25, 50, 100];

  // ─── Roles ─────────────────────────────────────────────
  // Matches backend UserRole enum values (app/models/enums.py) exactly.
  static const String roleAdmin = 'admin';
  static const String roleSalesManager = 'sales_manager';
  static const String roleSalesRep = 'sales_rep';
  static const String roleDeliverySme = 'delivery_sme';

  // ─── Lead Sources ──────────────────────────────────────
  // Labels shown in dropdowns — sourced from leadSourceLabels (see
  // lead_enums.dart) so this list and the backend wire-value map never
  // drift apart.
  static final List<String> leadSources = leadSourceLabels.values.toList();

  // ─── Lead Statuses ─────────────────────────────────────
  static final List<String> leadStatuses = leadStatusLabels.values.toList();

  // ─── Deal Stages ───────────────────────────────────────
  static const List<String> dealStages = [
    'Received Requirements',
    'Qualified to Buy',
    'Evaluation',
    'Proposals',
    'Contracts',
    'Closed Won',
    'Closed Lost',
    'Cold Deals',
  ];

  // ─── Tiers ─────────────────────────────────────────────
  // Matches backend LeadTier exactly (set only at lead-conversion time).
  static final List<String> tiers = leadTierLabels.values.toList();

  // ─── Industries ────────────────────────────────────────
  static const List<String> industries = [
    'IT Services',
    'SaaS',
    'Design & Media',
    'E-commerce',
    'Data & Analytics',
    'FinTech',
    'HealthTech',
    'EdTech',
    'Manufacturing',
    'Consulting',
    'Real Estate',
    'Other',
  ];

  // ─── Pre-Sales Checklist Stages ────────────────────────
  static const List<String> checklistStages = [
    'Discovery Phase',
    'Solution Design',
    'Proposal Preparation',
    'Client Evaluation',
    'Contract Negotiation',
  ];

  // ─── Owning Teams ─────────────────────────────────────
  static const List<String> owningTeams = ['Sales', 'Delivery', 'Joint'];

  // ─── Task Priorities ───────────────────────────────────
  static const List<String> taskPriorities = ['High', 'Medium', 'Low'];

  // ─── Activity Types ────────────────────────────────────
  static const List<String> activityTypes = [
    'Call',
    'Email',
    'Meeting',
    'Note',
    'Stage Change',
    'Task Complete',
  ];

  // ─── Currency ──────────────────────────────────────────
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';
}
