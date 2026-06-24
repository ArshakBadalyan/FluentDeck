import 'package:speakstack/models/flashcard_note_model.dart';

/// Built-in note types mirrored from the Strapi API (offline fallback).
List<NoteTypeModel> builtinNoteTypes() => const [
  NoteTypeModel(
    id: 'basic',
    name: 'Basic',
    fields: [
      NoteTypeFieldModel(name: 'Front', required: true),
      NoteTypeFieldModel(name: 'Back', required: true),
    ],
    cardTemplateNames: ['Card 1'],
  ),
  NoteTypeModel(
    id: 'basic_reversed',
    name: 'Basic (and reversed card)',
    fields: [
      NoteTypeFieldModel(name: 'Front', required: true),
      NoteTypeFieldModel(name: 'Back', required: true),
    ],
    cardTemplateNames: ['Card 1', 'Card 2'],
  ),
  NoteTypeModel(
    id: 'basic_optional_reversed',
    name: 'Basic (optional reversed card)',
    fields: [
      NoteTypeFieldModel(name: 'Front', required: true),
      NoteTypeFieldModel(name: 'Back', required: true),
    ],
    cardTemplateNames: ['Card 1', 'Card 2'],
  ),
  NoteTypeModel(
    id: 'basic_type_answer',
    name: 'Basic (type in the answer)',
    fields: [
      NoteTypeFieldModel(name: 'Front', required: true),
      NoteTypeFieldModel(name: 'Back', required: true),
    ],
    cardTemplateNames: ['Card 1'],
  ),
  NoteTypeModel(
    id: 'cloze',
    name: 'Cloze',
    fields: [
      NoteTypeFieldModel(name: 'Text', required: true),
      NoteTypeFieldModel(name: 'Back'),
    ],
    cardTemplateNames: ['Cloze'],
  ),
  NoteTypeModel(
    id: 'image_occlusion',
    name: 'Image Occlusion',
    fields: [
      NoteTypeFieldModel(name: 'Image', required: true),
      NoteTypeFieldModel(name: 'Occlusion', required: true),
      NoteTypeFieldModel(name: 'Header'),
    ],
    cardTemplateNames: ['IO Card'],
    available: false,
  ),
];
