import 'package:riovox/widgets/professor.dart';

/// Who teaches in the chat: Rio (the professor otter) or one of six people,
/// each tied to an OpenAI TTS voice. Picking a person also picks their voice;
/// Rio speaks in whichever voice is chosen for him.
class TutorPersona {
  const TutorPersona._({
    required this.id,
    required this.name,
    required this.blurb,
    required this.image,
    this.voice,
  });

  final String id;
  final String name;
  final String blurb;

  /// Portrait (people) or face (Rio), with a transparent background.
  final String image;

  /// The person's TTS voice; null for Rio, who uses the chosen voice.
  final String? voice;

  bool get isRio => voice == null;

  static final rio = TutorPersona._(
    id: 'rio',
    name: 'Rio',
    blurb: 'Your otter professor',
    image: ProfessorFace.happy.asset,
  );

  static const people = [
    TutorPersona._(id: 'maya', name: 'Maya', blurb: 'Bright and upbeat', image: 'assets/tutors/avatars/maya.webp', voice: 'nova'),
    TutorPersona._(id: 'daniel', name: 'Daniel', blurb: 'Calm, deep voice', image: 'assets/tutors/avatars/daniel.webp', voice: 'onyx'),
    TutorPersona._(id: 'sam', name: 'Sam', blurb: 'Clear and neutral', image: 'assets/tutors/avatars/sam.webp', voice: 'alloy'),
    TutorPersona._(id: 'leo', name: 'Leo', blurb: 'Relaxed and friendly', image: 'assets/tutors/avatars/leo.webp', voice: 'echo'),
    TutorPersona._(id: 'oliver', name: 'Oliver', blurb: 'Warm storyteller', image: 'assets/tutors/avatars/oliver.webp', voice: 'fable'),
    TutorPersona._(id: 'lena', name: 'Lena', blurb: 'Soft and gentle', image: 'assets/tutors/avatars/lena.webp', voice: 'shimmer'),
  ];

  static List<TutorPersona> get all => [rio, ...people];

  static TutorPersona byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => rio);

  /// The person who speaks with [voice], if any.
  static TutorPersona? personForVoice(String voice) {
    for (final p in people) {
      if (p.voice == voice) return p;
    }
    return null;
  }
}
