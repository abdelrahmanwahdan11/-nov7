import 'package:brewbliss_market/data/models/item.dart';
import 'package:brewbliss_market/data/models/offer.dart';

final seedItems = [
  Item(
    id: 'it_coffee_mug_01',
    name: 'Vanilla Cloud Mug',
    brand: 'Brew Bliss',
    images: const [
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0',
      'https://images.unsplash.com/photo-1498804103079-a6351b050096',
    ],
    model3d: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    price: 3.60,
    attrs: const {
      'Volume': '350ml',
      'Material': 'Ceramic',
    },
    description: 'Hand-drawn style mug. Limited edition.',
    category: 'Mugs',
    condition: 'Like new',
    allowOffers: true,
    ownerId: null,
    createdAt: DateTime.now(),
  ),
];

final seedOffers = <Offer>[];
