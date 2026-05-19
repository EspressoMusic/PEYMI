class StoreAnnouncement {
  const StoreAnnouncement({
    required this.textHe,
    required this.textEn,
    required this.imagePath,
    required this.revision,
  });

  final String textHe;
  final String textEn;
  final String imagePath;
  final int revision;

  bool get hasContent =>
      textHe.trim().isNotEmpty || textEn.trim().isNotEmpty || imagePath.trim().isNotEmpty;

  String text(bool hebrew) => hebrew ? textHe : textEn;

  Map<String, dynamic> toJson() => {
        'textHe': textHe,
        'textEn': textEn,
        'imagePath': imagePath,
        'revision': revision,
      };

  factory StoreAnnouncement.fromJson(Map<String, dynamic> json) {
    return StoreAnnouncement(
      textHe: json['textHe'] as String? ?? '',
      textEn: json['textEn'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = StoreAnnouncement(textHe: '', textEn: '', imagePath: '', revision: 0);
}
