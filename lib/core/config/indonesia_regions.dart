/// Data model representing an Indonesian province.
class ProvinceItem {
  const ProvinceItem({
    required this.id,
    required this.code,
    required this.name,
    required this.centerLat,
    required this.centerLng,
  });

  final String id;
  final String code;
  final String name;
  final double centerLat;
  final double centerLng;
}

/// Official list of 38 Indonesian Provinces with deterministic Supabase IDs.
class IndonesiaRegions {
  const IndonesiaRegions._();

  static const List<ProvinceItem> provinces = [
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000011',
      code: '11',
      name: 'Aceh',
      centerLat: 4.6951,
      centerLng: 96.7494,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000012',
      code: '12',
      name: 'Sumatera Utara',
      centerLat: 2.1154,
      centerLng: 99.1332,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000013',
      code: '13',
      name: 'Sumatera Barat',
      centerLat: -0.7399,
      centerLng: 100.5700,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000014',
      code: '14',
      name: 'Riau',
      centerLat: 0.5071,
      centerLng: 101.4478,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000015',
      code: '15',
      name: 'Jambi',
      centerLat: -1.6101,
      centerLng: 103.6131,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000016',
      code: '16',
      name: 'Sumatera Selatan',
      centerLat: -3.3194,
      centerLng: 104.7458,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000017',
      code: '17',
      name: 'Bengkulu',
      centerLat: -3.8004,
      centerLng: 102.2655,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000018',
      code: '18',
      name: 'Lampung',
      centerLat: -4.5586,
      centerLng: 105.2625,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000019',
      code: '19',
      name: 'Kepulauan Bangka Belitung',
      centerLat: -2.7411,
      centerLng: 106.1118,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000021',
      code: '21',
      name: 'Kepulauan Riau',
      centerLat: 3.9457,
      centerLng: 104.4534,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000031',
      code: '31',
      name: 'DKI Jakarta',
      centerLat: -6.2088,
      centerLng: 106.8456,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000032',
      code: '32',
      name: 'Jawa Barat',
      centerLat: -6.9175,
      centerLng: 107.6191,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000033',
      code: '33',
      name: 'Jawa Tengah',
      centerLat: -6.9932,
      centerLng: 110.4203,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000034',
      code: '34',
      name: 'DI Yogyakarta',
      centerLat: -7.7956,
      centerLng: 110.3695,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000035',
      code: '35',
      name: 'Jawa Timur',
      centerLat: -7.2575,
      centerLng: 112.7521,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000036',
      code: '36',
      name: 'Banten',
      centerLat: -6.4058,
      centerLng: 106.1065,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000051',
      code: '51',
      name: 'Bali',
      centerLat: -8.4095,
      centerLng: 115.1889,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000052',
      code: '52',
      name: 'Nusa Tenggara Barat',
      centerLat: -8.6529,
      centerLng: 117.3820,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000053',
      code: '53',
      name: 'Nusa Tenggara Timur',
      centerLat: -8.6574,
      centerLng: 121.2195,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000061',
      code: '61',
      name: 'Kalimantan Barat',
      centerLat: -0.2787,
      centerLng: 111.0969,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000062',
      code: '62',
      name: 'Kalimantan Tengah',
      centerLat: -1.6815,
      centerLng: 113.9213,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000063',
      code: '63',
      name: 'Kalimantan Selatan',
      centerLat: -3.0926,
      centerLng: 115.2838,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000064',
      code: '64',
      name: 'Kalimantan Timur',
      centerLat: 0.5387,
      centerLng: 116.4194,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000065',
      code: '65',
      name: 'Kalimantan Utara',
      centerLat: 3.0731,
      centerLng: 116.6321,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000071',
      code: '71',
      name: 'Sulawesi Utara',
      centerLat: 1.4748,
      centerLng: 124.8456,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000072',
      code: '72',
      name: 'Sulawesi Tengah',
      centerLat: -1.4300,
      centerLng: 121.4456,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000073',
      code: '73',
      name: 'Sulawesi Selatan',
      centerLat: -3.6687,
      centerLng: 119.9741,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000074',
      code: '74',
      name: 'Sulawesi Tenggara',
      centerLat: -4.1449,
      centerLng: 122.0792,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000075',
      code: '75',
      name: 'Gorontalo',
      centerLat: 0.6999,
      centerLng: 123.0600,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000076',
      code: '76',
      name: 'Sulawesi Barat',
      centerLat: -2.8441,
      centerLng: 119.2321,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000081',
      code: '81',
      name: 'Maluku',
      centerLat: -3.2385,
      centerLng: 128.1814,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000082',
      code: '82',
      name: 'Maluku Utara',
      centerLat: 1.5709,
      centerLng: 127.5397,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000091',
      code: '91',
      name: 'Papua',
      centerLat: -2.5337,
      centerLng: 140.7181,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000092',
      code: '92',
      name: 'Papua Barat',
      centerLat: -0.8615,
      centerLng: 134.0620,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000093',
      code: '93',
      name: 'Papua Selatan',
      centerLat: -7.4981,
      centerLng: 140.4011,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000094',
      code: '94',
      name: 'Papua Tengah',
      centerLat: -3.3639,
      centerLng: 135.5005,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000095',
      code: '95',
      name: 'Papua Pegunungan',
      centerLat: -4.0883,
      centerLng: 138.9442,
    ),
    ProvinceItem(
      id: 'b0000000-0000-0000-0000-000000000096',
      code: '96',
      name: 'Papua Barat Daya',
      centerLat: -0.8762,
      centerLng: 131.2562,
    ),
  ];

  static ProvinceItem? findById(String id) {
    try {
      return provinces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static ProvinceItem? findByCode(String code) {
    try {
      return provinces.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  static ProvinceItem? findByName(String name) {
    final lower = name.toLowerCase().trim();
    try {
      return provinces.firstWhere(
        (p) =>
            p.name.toLowerCase() == lower ||
            lower.contains(p.name.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }
}
