class Reciter {
  const Reciter({required this.id, required this.name});

  final int id;
  final String name;

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: (json['id'] as num).toInt(),
      name: json['reciter_name'] as String? ?? '',
    );
  }
}
