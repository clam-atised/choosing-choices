import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:choices/data/seed_data_loader.dart';
import 'package:choices/models/choice_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('loads Trip To Malaysia seed with 3 items and 13 cards', () async {
    final jsonString = await rootBundle.loadString(SeedDataLoader.assetPath);
    final seedData = SeedDataLoader.parseJsonString(jsonString);

    expect(seedData.folders.length, 1);
    expect(seedData.folders.first.name, 'Trip To Malaysia');
    expect(seedData.folders.first.items.length, 3);
    expect(seedData.cards.length, 13);
  });

  test('seed categories include typed detailDefinitions', () async {
    final jsonString = await rootBundle.loadString(SeedDataLoader.assetPath);
    final seedData = SeedDataLoader.parseJsonString(jsonString);
    final folder = seedData.folders.first;

    final places = folder.items.firstWhere((item) => item.id == 'places_to_visit');
    expect(
      places.detailDefinitions.map((d) => '${d.label}:${d.type.name}').toList(),
      [
        'Location:text',
        'Accessible by train:yesNo',
        'Description:text',
      ],
    );

    final restaurants = folder.items.firstWhere(
      (item) => item.id == 'restaurant_recommendations',
    );
    expect(
      restaurants.detailDefinitions
          .map((d) => '${d.label}:${d.type.name}')
          .toList(),
      [
        'Type of Cuisine:text',
        'Location:text',
      ],
    );

    final activities =
        folder.items.firstWhere((item) => item.id == 'activities');
    expect(
      activities.detailDefinitions
          .map((d) => '${d.label}:${d.type.name}')
          .toList(),
      ['Charge:text'],
    );
  });

  test('place card maps detail fields correctly', () async {
    final jsonString = await rootBundle.loadString(SeedDataLoader.assetPath);
    final seedData = SeedDataLoader.parseJsonString(jsonString);

    final placeCard = seedData.cards.firstWhere((card) => card.id == 'place_1');
    expect(placeCard.title, 'Petronas Twin Towers');
    expect(
      placeCard.details.any(
        (detail) =>
            detail.label == 'Location' &&
            detail.textValue == 'Kuala Lumpur, Malaysia',
      ),
      isTrue,
    );
    expect(
      placeCard.details.any(
        (detail) =>
            detail.label == 'Accessible by train' &&
            detail.type == DetailFieldType.yesNo &&
            detail.yesNoValue == true,
      ),
      isTrue,
    );
    expect(placeCard.imagePath, 'assets/seed/images/places/petronas.jpg');
  });

  test('restaurant card maps cuisine and location', () async {
    final jsonString = await rootBundle.loadString(SeedDataLoader.assetPath);
    final seedData = SeedDataLoader.parseJsonString(jsonString);

    final restaurantCard =
        seedData.cards.firstWhere((card) => card.id == 'restaurant_1');
    expect(restaurantCard.title, 'Jalan Alor Night Market');
    expect(
      restaurantCard.details.any(
        (detail) =>
            detail.label == 'Type of Cuisine' &&
            detail.textValue == 'Malaysian street food',
      ),
      isTrue,
    );
  });

  test('activity card maps charge field', () async {
    final jsonString = await rootBundle.loadString(SeedDataLoader.assetPath);
    final seedData = SeedDataLoader.parseJsonString(jsonString);

    final activityCard =
        seedData.cards.firstWhere((card) => card.id == 'activity_1');
    expect(
      activityCard.details.any(
        (detail) =>
            detail.label == 'Charge' &&
            detail.textValue!.contains('Free'),
      ),
      isTrue,
    );
  });
}
