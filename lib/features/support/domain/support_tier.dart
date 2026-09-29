import 'package:equatable/equatable.dart';

/// Represents a voluntary contribution tier for supporting NoteFlow development.
///
/// Each tier maps to a corresponding one-time consumable in-app product in
/// the Google Play Console, allowing supporters to buy coffees on demand.
class SupportTier extends Equatable {
  /// Unique identifier for this tier (e.g. 'coffee_espresso').
  final String id;

  /// Human-readable title displayed on the tier selection card.
  final String name;

  /// Localized price string shown on the UI (e.g. '$2.99', '€2.99', '₹250').
  final String priceDisplay;

  /// Raw numeric price amount.
  final double priceAmount;

  /// Characteristic emoji icon representing the tier.
  final String emoji;

  /// Brief description highlighting what this contribution fuels.
  final String description;

  /// Whether this tier is flagged with a "POPULAR" badge in the UI.
  final bool isPopular;

  /// The Product ID matching the one-time product in Google Play Console.
  final String googlePlayProductId;

  const SupportTier({
    required this.id,
    required this.name,
    required this.priceDisplay,
    required this.priceAmount,
    required this.emoji,
    required this.description,
    this.isPopular = false,
    required this.googlePlayProductId,
  });

  /// Default predefined support tiers available in NoteFlow.
  static const List<SupportTier> defaultTiers = [
    SupportTier(
      id: 'coffee_espresso',
      name: 'Quick Espresso',
      priceDisplay: '\$2.99',
      priceAmount: 2.99,
      emoji: '☕',
      description: 'Fuel 30 mins of focused coding & bug fixes.',
      googlePlayProductId: 'noteflow_tip_espresso',
    ),
    SupportTier(
      id: 'coffee_croissant',
      name: 'Coffee & Croissant',
      priceDisplay: '\$4.99',
      priceAmount: 4.99,
      emoji: '🥐',
      description: 'Most popular! Fuels an afternoon of feature work.',
      isPopular: true,
      googlePlayProductId: 'noteflow_tip_croissant',
    ),
    SupportTier(
      id: 'coffee_lunch',
      name: 'Developer Lunch',
      priceDisplay: '\$9.99',
      priceAmount: 9.99,
      emoji: '🍱',
      description: 'Helps keep NoteFlow 100% offline & subscription-free.',
      googlePlayProductId: 'noteflow_tip_lunch',
    ),
    SupportTier(
      id: 'coffee_patron',
      name: 'NoteFlow Patron',
      priceDisplay: '\$24.99',
      priceAmount: 24.99,
      emoji: '🚀',
      description: 'Ultimate backer! Listed in app credits & roadmap updates.',
      googlePlayProductId: 'noteflow_tip_patron',
    ),
  ];

  @override
  List<Object?> get props => [
        id,
        name,
        priceDisplay,
        priceAmount,
        emoji,
        description,
        isPopular,
        googlePlayProductId,
      ];
}
