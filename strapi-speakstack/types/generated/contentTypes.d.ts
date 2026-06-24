import type { Attribute, Schema } from '@strapi/strapi';

export interface AdminApiToken extends Schema.CollectionType {
  collectionName: 'strapi_api_tokens';
  info: {
    description: '';
    displayName: 'Api Token';
    name: 'Api Token';
    pluralName: 'api-tokens';
    singularName: 'api-token';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    accessKey: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'admin::api-token',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    description: Attribute.String &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }> &
      Attribute.DefaultTo<''>;
    expiresAt: Attribute.DateTime;
    lastUsedAt: Attribute.DateTime;
    lifespan: Attribute.BigInteger;
    name: Attribute.String &
      Attribute.Required &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    permissions: Attribute.Relation<
      'admin::api-token',
      'oneToMany',
      'admin::api-token-permission'
    >;
    type: Attribute.Enumeration<['read-only', 'full-access', 'custom']> &
      Attribute.Required &
      Attribute.DefaultTo<'read-only'>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'admin::api-token',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface AdminApiTokenPermission extends Schema.CollectionType {
  collectionName: 'strapi_api_token_permissions';
  info: {
    description: '';
    displayName: 'API Token Permission';
    name: 'API Token Permission';
    pluralName: 'api-token-permissions';
    singularName: 'api-token-permission';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    action: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'admin::api-token-permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    token: Attribute.Relation<
      'admin::api-token-permission',
      'manyToOne',
      'admin::api-token'
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'admin::api-token-permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface AdminPermission extends Schema.CollectionType {
  collectionName: 'admin_permissions';
  info: {
    description: '';
    displayName: 'Permission';
    name: 'Permission';
    pluralName: 'permissions';
    singularName: 'permission';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    action: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    actionParameters: Attribute.JSON & Attribute.DefaultTo<{}>;
    conditions: Attribute.JSON & Attribute.DefaultTo<[]>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'admin::permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    properties: Attribute.JSON & Attribute.DefaultTo<{}>;
    role: Attribute.Relation<'admin::permission', 'manyToOne', 'admin::role'>;
    subject: Attribute.String &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'admin::permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface AdminRole extends Schema.CollectionType {
  collectionName: 'admin_roles';
  info: {
    description: '';
    displayName: 'Role';
    name: 'Role';
    pluralName: 'roles';
    singularName: 'role';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    code: Attribute.String &
      Attribute.Required &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<'admin::role', 'oneToOne', 'admin::user'> &
      Attribute.Private;
    description: Attribute.String;
    name: Attribute.String &
      Attribute.Required &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    permissions: Attribute.Relation<
      'admin::role',
      'oneToMany',
      'admin::permission'
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<'admin::role', 'oneToOne', 'admin::user'> &
      Attribute.Private;
    users: Attribute.Relation<'admin::role', 'manyToMany', 'admin::user'>;
  };
}

export interface AdminTransferToken extends Schema.CollectionType {
  collectionName: 'strapi_transfer_tokens';
  info: {
    description: '';
    displayName: 'Transfer Token';
    name: 'Transfer Token';
    pluralName: 'transfer-tokens';
    singularName: 'transfer-token';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    accessKey: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'admin::transfer-token',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    description: Attribute.String &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }> &
      Attribute.DefaultTo<''>;
    expiresAt: Attribute.DateTime;
    lastUsedAt: Attribute.DateTime;
    lifespan: Attribute.BigInteger;
    name: Attribute.String &
      Attribute.Required &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    permissions: Attribute.Relation<
      'admin::transfer-token',
      'oneToMany',
      'admin::transfer-token-permission'
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'admin::transfer-token',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface AdminTransferTokenPermission extends Schema.CollectionType {
  collectionName: 'strapi_transfer_token_permissions';
  info: {
    description: '';
    displayName: 'Transfer Token Permission';
    name: 'Transfer Token Permission';
    pluralName: 'transfer-token-permissions';
    singularName: 'transfer-token-permission';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    action: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'admin::transfer-token-permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    token: Attribute.Relation<
      'admin::transfer-token-permission',
      'manyToOne',
      'admin::transfer-token'
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'admin::transfer-token-permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface AdminUser extends Schema.CollectionType {
  collectionName: 'admin_users';
  info: {
    description: '';
    displayName: 'User';
    name: 'User';
    pluralName: 'users';
    singularName: 'user';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    blocked: Attribute.Boolean & Attribute.Private & Attribute.DefaultTo<false>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<'admin::user', 'oneToOne', 'admin::user'> &
      Attribute.Private;
    email: Attribute.Email &
      Attribute.Required &
      Attribute.Private &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    firstname: Attribute.String &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    isActive: Attribute.Boolean &
      Attribute.Private &
      Attribute.DefaultTo<false>;
    lastname: Attribute.String &
      Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    password: Attribute.Password &
      Attribute.Private &
      Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    preferedLanguage: Attribute.String;
    registrationToken: Attribute.String & Attribute.Private;
    resetPasswordToken: Attribute.String & Attribute.Private;
    roles: Attribute.Relation<'admin::user', 'manyToMany', 'admin::role'> &
      Attribute.Private;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<'admin::user', 'oneToOne', 'admin::user'> &
      Attribute.Private;
    username: Attribute.String;
  };
}

export interface ApiAiAiConfig extends Schema.SingleType {
  collectionName: 'ai_configs';
  info: {
    description: 'Placeholder single type so the AI API module loads; proxy routes live in custom.js';
    displayName: 'AI Config';
    pluralName: 'ai-configs';
    singularName: 'ai-config';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::ai.ai-config',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    notes: Attribute.Text & Attribute.Private;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::ai.ai-config',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiAppFeatureConfigAppFeatureConfig extends Schema.SingleType {
  collectionName: 'app_feature_configs';
  info: {
    description: 'Free vs premium limits for vocabulary, decks, and placement tests.';
    displayName: 'App Feature Config';
    pluralName: 'app-feature-configs';
    singularName: 'app-feature-config';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    advancedLevelsRequiringPremium: Attribute.JSON &
      Attribute.DefaultTo<['B2', 'C1', 'C2']>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::app-feature-config.app-feature-config',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    freeDailyConversationTurns: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<10>;
    freeMaxDecks: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<1>;
    freeMaxNewCardsPerDay: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<10>;
    freeMaxSavedWords: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<20>;
    freePlacementRetakesPerMonth: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<1>;
    freePreviewWordsPerAdvancedList: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<10>;
    publishedAt: Attribute.DateTime;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::app-feature-config.app-feature-config',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiCardReviewLogCardReviewLog extends Schema.CollectionType {
  collectionName: 'card_review_logs';
  info: {
    description: 'Per-answer review event for statistics (Phase 4E).';
    displayName: 'Card Review Log';
    pluralName: 'card-review-logs';
    singularName: 'card-review-log';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::card-review-log.card-review-log',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    deck: Attribute.Relation<
      'api::card-review-log.card-review-log',
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    durationMs: Attribute.Integer & Attribute.DefaultTo<0>;
    flashcard: Attribute.Relation<
      'api::card-review-log.card-review-log',
      'manyToOne',
      'api::flashcard.flashcard'
    >;
    intervalAfter: Attribute.Float & Attribute.DefaultTo<0>;
    intervalBefore: Attribute.Float & Attribute.DefaultTo<0>;
    rating: Attribute.Enumeration<['again', 'hard', 'good', 'easy']> &
      Attribute.Required;
    reviewedAt: Attribute.DateTime & Attribute.Required;
    stateAfter: Attribute.String;
    stateBefore: Attribute.String;
    undoSnapshot: Attribute.JSON;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::card-review-log.card-review-log',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::card-review-log.card-review-log',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiCardReviewStateCardReviewState
  extends Schema.CollectionType {
  collectionName: 'card_review_states';
  info: {
    description: 'SM-2 spaced repetition state per flashcard.';
    displayName: 'Card Review State';
    pluralName: 'card-review-states';
    singularName: 'card-review-state';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    buriedUntil: Attribute.DateTime;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::card-review-state.card-review-state',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    dueAt: Attribute.DateTime;
    easeFactor: Attribute.Float & Attribute.DefaultTo<2.5>;
    firstStudiedAt: Attribute.DateTime;
    flashcard: Attribute.Relation<
      'api::card-review-state.card-review-state',
      'oneToOne',
      'api::flashcard.flashcard'
    >;
    intervalDays: Attribute.Float & Attribute.DefaultTo<0>;
    lapses: Attribute.Integer & Attribute.DefaultTo<0>;
    lastReviewedAt: Attribute.DateTime;
    learningStep: Attribute.Integer & Attribute.DefaultTo<0>;
    repetitions: Attribute.Integer & Attribute.DefaultTo<0>;
    state: Attribute.Enumeration<['new', 'learning', 'review', 'relearning']> &
      Attribute.Required &
      Attribute.DefaultTo<'new'>;
    suspended: Attribute.Boolean & Attribute.DefaultTo<false>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::card-review-state.card-review-state',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::card-review-state.card-review-state',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiConversationPromptConversationPrompt
  extends Schema.CollectionType {
  collectionName: 'conversation_prompts';
  info: {
    description: 'Role-play scenarios for speaking practice';
    displayName: 'Conversation Prompt';
    pluralName: 'conversation-prompts';
    singularName: 'conversation-prompt';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    category: Attribute.Enumeration<
      [
        'daily_life',
        'career',
        'travel',
        'relationships',
        'language_testing',
        'custom'
      ]
    > &
      Attribute.DefaultTo<'daily_life'>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::conversation-prompt.conversation-prompt',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    difficultyLevel: Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    > &
      Attribute.Required;
    iconKey: Attribute.String;
    order: Attribute.Integer & Attribute.DefaultTo<0>;
    publishedAt: Attribute.DateTime;
    scenario: Attribute.Text & Attribute.Required;
    suggestedVocabulary: Attribute.JSON;
    title: Attribute.String & Attribute.Required;
    tutorRole: Attribute.String;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::conversation-prompt.conversation-prompt',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    userRole: Attribute.String;
  };
}

export interface ApiCustomFlashcardNoteTypeCustomFlashcardNoteType
  extends Schema.CollectionType {
  collectionName: 'custom_flashcard_note_types';
  info: {
    description: 'User-defined Anki-style note templates (Phase 5C).';
    displayName: 'Custom Flashcard Note Type';
    pluralName: 'custom-flashcard-note-types';
    singularName: 'custom-flashcard-note-type';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    cardTemplates: Attribute.JSON & Attribute.DefaultTo<[]>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::custom-flashcard-note-type.custom-flashcard-note-type',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    css: Attribute.Text;
    fields: Attribute.JSON & Attribute.DefaultTo<[]>;
    name: Attribute.String & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::custom-flashcard-note-type.custom-flashcard-note-type',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::custom-flashcard-note-type.custom-flashcard-note-type',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiExerciseExercise extends Schema.CollectionType {
  collectionName: 'exercises';
  info: {
    description: '';
    displayName: 'Exercise';
    pluralName: 'exercises';
    singularName: 'exercise';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    aiFeedbackEnabled: Attribute.Boolean & Attribute.DefaultTo<false>;
    correctAnswer: Attribute.Text;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::exercise.exercise',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    lesson: Attribute.Relation<
      'api::exercise.exercise',
      'manyToOne',
      'api::lesson.lesson'
    >;
    options: Attribute.JSON;
    prompt: Attribute.Text & Attribute.Required;
    publishedAt: Attribute.DateTime;
    type: Attribute.Enumeration<
      ['multipleChoice', 'fillBlank', 'speakingPrompt', 'conversation']
    > &
      Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::exercise.exercise',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiFlashcardDeckFlashcardDeck extends Schema.CollectionType {
  collectionName: 'flashcard_decks';
  info: {
    description: 'User flashcard decks including default Saved words and From speaking.';
    displayName: 'Flashcard Deck';
    pluralName: 'flashcard-decks';
    singularName: 'flashcard-deck';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::flashcard-deck.flashcard-deck',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    deckOptions: Attribute.JSON;
    deckSlug: Attribute.String & Attribute.Required;
    description: Attribute.Text;
    filterQuery: Attribute.JSON;
    flashcards: Attribute.Relation<
      'api::flashcard-deck.flashcard-deck',
      'oneToMany',
      'api::flashcard.flashcard'
    >;
    isDefault: Attribute.Boolean & Attribute.DefaultTo<false>;
    isFiltered: Attribute.Boolean & Attribute.DefaultTo<false>;
    name: Attribute.String & Attribute.Required;
    parentDeck: Attribute.Relation<
      'api::flashcard-deck.flashcard-deck',
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::flashcard-deck.flashcard-deck',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::flashcard-deck.flashcard-deck',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiFlashcardNoteFlashcardNote extends Schema.CollectionType {
  collectionName: 'flashcard_notes';
  info: {
    description: 'Anki-style note \u2014 one note generates one or more flashcards.';
    displayName: 'Flashcard Note';
    pluralName: 'flashcard-notes';
    singularName: 'flashcard-note';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::flashcard-note.flashcard-note',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    createReverse: Attribute.Boolean & Attribute.DefaultTo<false>;
    deck: Attribute.Relation<
      'api::flashcard-note.flashcard-note',
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    fields: Attribute.JSON & Attribute.DefaultTo<{}>;
    flashcards: Attribute.Relation<
      'api::flashcard-note.flashcard-note',
      'oneToMany',
      'api::flashcard.flashcard'
    >;
    marked: Attribute.Boolean & Attribute.DefaultTo<false>;
    mediaUrl: Attribute.String;
    noteType: Attribute.Enumeration<
      [
        'basic',
        'basic_reversed',
        'basic_optional_reversed',
        'basic_type_answer',
        'cloze',
        'image_occlusion'
      ]
    > &
      Attribute.Required &
      Attribute.DefaultTo<'basic'>;
    tags: Attribute.JSON & Attribute.DefaultTo<[]>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::flashcard-note.flashcard-note',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::flashcard-note.flashcard-note',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    userNote: Attribute.Relation<
      'api::flashcard-note.flashcard-note',
      'manyToOne',
      'api::user-note.user-note'
    >;
  };
}

export interface ApiFlashcardFlashcard extends Schema.CollectionType {
  collectionName: 'flashcards';
  info: {
    description: 'Generated study card from a flashcard note (Anki card template).';
    displayName: 'Flashcard';
    pluralName: 'flashcards';
    singularName: 'flashcard';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    back: Attribute.Text & Attribute.Required;
    cardType: Attribute.Enumeration<
      ['basic', 'cloze', 'reversed', 'type_answer', 'image_occlusion']
    > &
      Attribute.Required &
      Attribute.DefaultTo<'basic'>;
    clozeIndex: Attribute.Integer;
    clozeText: Attribute.Text;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::flashcard.flashcard',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    deck: Attribute.Relation<
      'api::flashcard.flashcard',
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    flag: Attribute.Integer &
      Attribute.SetMinMax<
        {
          max: 7;
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    flashcardNote: Attribute.Relation<
      'api::flashcard.flashcard',
      'manyToOne',
      'api::flashcard-note.flashcard-note'
    >;
    front: Attribute.Text & Attribute.Required;
    mediaUrl: Attribute.String;
    occlusionData: Attribute.JSON;
    reviewState: Attribute.Relation<
      'api::flashcard.flashcard',
      'oneToOne',
      'api::card-review-state.card-review-state'
    >;
    tags: Attribute.JSON & Attribute.DefaultTo<[]>;
    templateName: Attribute.String & Attribute.DefaultTo<'Card 1'>;
    templateOrdinal: Attribute.Integer & Attribute.DefaultTo<0>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::flashcard.flashcard',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::flashcard.flashcard',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    userNote: Attribute.Relation<
      'api::flashcard.flashcard',
      'manyToOne',
      'api::user-note.user-note'
    >;
  };
}

export interface ApiLessonLesson extends Schema.CollectionType {
  collectionName: 'lessons';
  info: {
    description: '';
    displayName: 'Lesson';
    pluralName: 'lessons';
    singularName: 'lesson';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::lesson.lesson',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    description: Attribute.RichText;
    exercises: Attribute.Relation<
      'api::lesson.lesson',
      'oneToMany',
      'api::exercise.exercise'
    >;
    level: Attribute.Enumeration<['A1', 'A2', 'B1', 'B2', 'C1', 'C2']> &
      Attribute.Required;
    order: Attribute.Integer & Attribute.DefaultTo<0>;
    publishedAt: Attribute.DateTime;
    skillType: Attribute.Enumeration<
      ['speaking', 'grammar', 'vocabulary', 'listening']
    > &
      Attribute.Required;
    title: Attribute.String & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::lesson.lesson',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiMobileAppPolicyMobileAppPolicy extends Schema.SingleType {
  collectionName: 'mobile_app_policies';
  info: {
    description: 'Minimum app build numbers and soft-update campaign (native mobile clients only).';
    displayName: 'Mobile app policy';
    pluralName: 'mobile-app-policies';
    singularName: 'mobile-app-policy';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    androidStoreUrl: Attribute.String;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::mobile-app-policy.mobile-app-policy',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    forceMinimumAndroidBuild: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    forceMinimumIosBuild: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    iosStoreUrl: Attribute.String;
    publishedAt: Attribute.DateTime;
    softCampaignId: Attribute.String & Attribute.DefaultTo<''>;
    softMessage: Attribute.Text;
    softSuggestBelowAndroidBuild: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    softSuggestBelowIosBuild: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::mobile-app-policy.mobile-app-policy',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiNotificationNotification extends Schema.CollectionType {
  collectionName: 'notifications';
  info: {
    description: '';
    displayName: 'Notification';
    pluralName: 'notifications';
    singularName: 'notification';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::notification.notification',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    metadata: Attribute.JSON;
    publishedAt: Attribute.DateTime;
    read: Attribute.Boolean & Attribute.DefaultTo<false>;
    text: Attribute.String;
    title: Attribute.String;
    type: Attribute.Enumeration<
      ['congrats', 'unfinished_goal', 'assignment', 'class_membership']
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::notification.notification',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    users_permissions_user: Attribute.Relation<
      'api::notification.notification',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiPlacementTestResultPlacementTestResult
  extends Schema.CollectionType {
  collectionName: 'placement_test_results';
  info: {
    description: 'Vocabulary placement test history and suggested CEFR level.';
    displayName: 'Placement Test Result';
    pluralName: 'placement-test-results';
    singularName: 'placement-test-result';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    answersSummary: Attribute.JSON & Attribute.DefaultTo<{}>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::placement-test-result.placement-test-result',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    levelBucket: Attribute.Enumeration<
      ['beginner', 'intermediate', 'advanced']
    > &
      Attribute.Required;
    score: Attribute.Decimal & Attribute.Required;
    suggestedLevel: Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    > &
      Attribute.Required;
    takenAt: Attribute.DateTime & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::placement-test-result.placement-test-result',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::placement-test-result.placement-test-result',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiSpeakingGameSpeakingGame extends Schema.CollectionType {
  collectionName: 'speaking_games';
  info: {
    description: 'AI-powered speaking games';
    displayName: 'Speaking Game';
    pluralName: 'speaking-games';
    singularName: 'speaking-game';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::speaking-game.speaking-game',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    description: Attribute.Text;
    iconKey: Attribute.String;
    openingMessage: Attribute.Text;
    order: Attribute.Integer & Attribute.DefaultTo<0>;
    publishedAt: Attribute.DateTime;
    slug: Attribute.UID<'api::speaking-game.speaking-game', 'title'> &
      Attribute.Required;
    systemPrompt: Attribute.Text & Attribute.Required;
    title: Attribute.String & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::speaking-game.speaking-game',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiSpeakingSessionSpeakingSession
  extends Schema.CollectionType {
  collectionName: 'speaking_sessions';
  info: {
    description: 'Completed speaking practice sessions with AI scores';
    displayName: 'Speaking Session';
    pluralName: 'speaking-sessions';
    singularName: 'speaking-session';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    completedAt: Attribute.DateTime & Attribute.Required;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::speaking-session.speaking-session',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    durationMinutes: Attribute.Integer & Attribute.DefaultTo<1>;
    feedback: Attribute.Text;
    mode: Attribute.Enumeration<
      ['chat', 'role_play', 'topic', 'game', 'lesson']
    > &
      Attribute.Required;
    referenceKey: Attribute.String;
    score: Attribute.Integer &
      Attribute.Required &
      Attribute.SetMinMax<
        {
          max: 10;
          min: 0;
        },
        number
      >;
    summary: Attribute.String;
    title: Attribute.String & Attribute.Required;
    turnCount: Attribute.Integer & Attribute.DefaultTo<0>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::speaking-session.speaking-session',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::speaking-session.speaking-session',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiSpeakingTopicSpeakingTopic extends Schema.CollectionType {
  collectionName: 'speaking_topics';
  info: {
    description: 'Topic-based conversation starters grouped by proficiency';
    displayName: 'Speaking Topic';
    pluralName: 'speaking-topics';
    singularName: 'speaking-topic';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::speaking-topic.speaking-topic',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    iconKey: Attribute.String;
    levelGroup: Attribute.Enumeration<['intermediate', 'advanced', 'expert']> &
      Attribute.Required;
    order: Attribute.Integer & Attribute.DefaultTo<0>;
    publishedAt: Attribute.DateTime;
    starterPrompt: Attribute.Text & Attribute.Required;
    suggestedVocabulary: Attribute.JSON;
    title: Attribute.String & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::speaking-topic.speaking-topic',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiStudyHallStudyHall extends Schema.SingleType {
  collectionName: 'study_hall_configs';
  info: {
    description: 'Placeholder type for Study Hall custom routes';
    displayName: 'Study Hall';
    pluralName: 'study-halls';
    singularName: 'study-hall';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::study-hall.study-hall',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::study-hall.study-hall',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface ApiUserNoteUserNote extends Schema.CollectionType {
  collectionName: 'user_notes';
  info: {
    description: 'Personal vocabulary notes linked to catalog entries or conversation.';
    displayName: 'User Note';
    pluralName: 'user-notes';
    singularName: 'user-note';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::user-note.user-note',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    definition: Attribute.Text;
    exampleSentence: Attribute.Text;
    flashcards: Attribute.Relation<
      'api::user-note.user-note',
      'oneToMany',
      'api::flashcard.flashcard'
    >;
    source: Attribute.Enumeration<['catalog', 'speaking', 'manual']> &
      Attribute.Required &
      Attribute.DefaultTo<'manual'>;
    tags: Attribute.JSON & Attribute.DefaultTo<[]>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::user-note.user-note',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::user-note.user-note',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    vocabularyEntry: Attribute.Relation<
      'api::user-note.user-note',
      'manyToOne',
      'api::vocabulary-entry.vocabulary-entry'
    >;
    word: Attribute.String & Attribute.Required;
  };
}

export interface ApiUserProgressUserProgress extends Schema.CollectionType {
  collectionName: 'user_progresses';
  info: {
    description: '';
    displayName: 'User Progress';
    pluralName: 'user-progresses';
    singularName: 'user-progress';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    completedExercises: Attribute.JSON & Attribute.DefaultTo<[]>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::user-progress.user-progress',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    currentLevel: Attribute.Enumeration<['A1', 'A2', 'B1', 'B2', 'C1', 'C2']> &
      Attribute.DefaultTo<'B1'>;
    flashcardReviewStreakDays: Attribute.Integer & Attribute.DefaultTo<0>;
    lastFlashcardReviewAt: Attribute.DateTime;
    lastPracticeAt: Attribute.DateTime;
    perfectSentencesCount: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    spokenWordBank: Attribute.JSON & Attribute.DefaultTo<[]>;
    streakDays: Attribute.Integer & Attribute.DefaultTo<0>;
    totalSpeakingMinutes: Attribute.Integer & Attribute.DefaultTo<0>;
    uniqueWordsUsed: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::user-progress.user-progress',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::user-progress.user-progress',
      'oneToOne',
      'plugin::users-permissions.user'
    >;
    weakAreas: Attribute.JSON & Attribute.DefaultTo<[]>;
  };
}

export interface ApiUserVocabularyProgressUserVocabularyProgress
  extends Schema.CollectionType {
  collectionName: 'user_vocabulary_progresses';
  info: {
    description: 'Tracks words a user saved from the catalog.';
    displayName: 'User Vocabulary Progress';
    pluralName: 'user-vocabulary-progresses';
    singularName: 'user-vocabulary-progress';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::user-vocabulary-progress.user-vocabulary-progress',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    savedAt: Attribute.DateTime;
    status: Attribute.Enumeration<['new', 'learning', 'known']> &
      Attribute.Required &
      Attribute.DefaultTo<'new'>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::user-vocabulary-progress.user-vocabulary-progress',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user: Attribute.Relation<
      'api::user-vocabulary-progress.user-vocabulary-progress',
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    vocabularyEntry: Attribute.Relation<
      'api::user-vocabulary-progress.user-vocabulary-progress',
      'manyToOne',
      'api::vocabulary-entry.vocabulary-entry'
    >;
  };
}

export interface ApiVocabularyEntryVocabularyEntry
  extends Schema.CollectionType {
  collectionName: 'vocabulary_entries';
  info: {
    description: 'Atomic vocabulary sense catalog (CEFR-tagged, frequency-ordered).';
    displayName: 'Vocabulary Entry';
    pluralName: 'vocabulary-entries';
    singularName: 'vocabulary-entry';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    audioUrl: Attribute.String;
    cefrLevel: Attribute.Enumeration<['A1', 'A2', 'B1', 'B2', 'C1', 'C2']>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'api::vocabulary-entry.vocabulary-entry',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    definition: Attribute.Text & Attribute.Required;
    entryType: Attribute.Enumeration<
      ['word', 'phrase', 'idiom', 'expression']
    > &
      Attribute.Required &
      Attribute.DefaultTo<'word'>;
    examples: Attribute.JSON;
    exampleSentence: Attribute.Text;
    externalId: Attribute.String & Attribute.Unique;
    frequencyBucket: Attribute.String;
    frequencyRank: Attribute.Integer & Attribute.DefaultTo<0>;
    ipa: Attribute.String;
    lemma: Attribute.String;
    partOfSpeech: Attribute.String;
    publishedAt: Attribute.DateTime;
    sensePriority: Attribute.Enumeration<['core', 'extend', 'rare']>;
    source: Attribute.String & Attribute.DefaultTo<'import'>;
    topic: Attribute.String;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'api::vocabulary-entry.vocabulary-entry',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    userProgress: Attribute.Relation<
      'api::vocabulary-entry.vocabulary-entry',
      'oneToMany',
      'api::user-vocabulary-progress.user-vocabulary-progress'
    >;
    word: Attribute.String & Attribute.Required;
  };
}

export interface PluginContentReleasesRelease extends Schema.CollectionType {
  collectionName: 'strapi_releases';
  info: {
    displayName: 'Release';
    pluralName: 'releases';
    singularName: 'release';
  };
  options: {
    draftAndPublish: false;
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    actions: Attribute.Relation<
      'plugin::content-releases.release',
      'oneToMany',
      'plugin::content-releases.release-action'
    >;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::content-releases.release',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    name: Attribute.String & Attribute.Required;
    releasedAt: Attribute.DateTime;
    scheduledAt: Attribute.DateTime;
    status: Attribute.Enumeration<
      ['ready', 'blocked', 'failed', 'done', 'empty']
    > &
      Attribute.Required;
    timezone: Attribute.String;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::content-releases.release',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface PluginContentReleasesReleaseAction
  extends Schema.CollectionType {
  collectionName: 'strapi_release_actions';
  info: {
    displayName: 'Release Action';
    pluralName: 'release-actions';
    singularName: 'release-action';
  };
  options: {
    draftAndPublish: false;
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    contentType: Attribute.String & Attribute.Required;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::content-releases.release-action',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    entry: Attribute.Relation<
      'plugin::content-releases.release-action',
      'morphToOne'
    >;
    isEntryValid: Attribute.Boolean;
    locale: Attribute.String;
    release: Attribute.Relation<
      'plugin::content-releases.release-action',
      'manyToOne',
      'plugin::content-releases.release'
    >;
    type: Attribute.Enumeration<['publish', 'unpublish']> & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::content-releases.release-action',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface PluginI18NLocale extends Schema.CollectionType {
  collectionName: 'i18n_locale';
  info: {
    collectionName: 'locales';
    description: '';
    displayName: 'Locale';
    pluralName: 'locales';
    singularName: 'locale';
  };
  options: {
    draftAndPublish: false;
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    code: Attribute.String & Attribute.Unique;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::i18n.locale',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    name: Attribute.String &
      Attribute.SetMinMax<
        {
          max: 50;
          min: 1;
        },
        number
      >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::i18n.locale',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface PluginUploadFile extends Schema.CollectionType {
  collectionName: 'files';
  info: {
    description: '';
    displayName: 'File';
    pluralName: 'files';
    singularName: 'file';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    alternativeText: Attribute.String;
    caption: Attribute.String;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::upload.file',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    ext: Attribute.String;
    folder: Attribute.Relation<
      'plugin::upload.file',
      'manyToOne',
      'plugin::upload.folder'
    > &
      Attribute.Private;
    folderPath: Attribute.String &
      Attribute.Required &
      Attribute.Private &
      Attribute.SetMinMax<
        {
          min: 1;
        },
        number
      >;
    formats: Attribute.JSON;
    hash: Attribute.String & Attribute.Required;
    height: Attribute.Integer;
    mime: Attribute.String & Attribute.Required;
    name: Attribute.String & Attribute.Required;
    previewUrl: Attribute.String;
    provider: Attribute.String & Attribute.Required;
    provider_metadata: Attribute.JSON;
    related: Attribute.Relation<'plugin::upload.file', 'morphToMany'>;
    size: Attribute.Decimal & Attribute.Required;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::upload.file',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    url: Attribute.String & Attribute.Required;
    width: Attribute.Integer;
  };
}

export interface PluginUploadFolder extends Schema.CollectionType {
  collectionName: 'upload_folders';
  info: {
    displayName: 'Folder';
    pluralName: 'folders';
    singularName: 'folder';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    children: Attribute.Relation<
      'plugin::upload.folder',
      'oneToMany',
      'plugin::upload.folder'
    >;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::upload.folder',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    files: Attribute.Relation<
      'plugin::upload.folder',
      'oneToMany',
      'plugin::upload.file'
    >;
    name: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMax<
        {
          min: 1;
        },
        number
      >;
    parent: Attribute.Relation<
      'plugin::upload.folder',
      'manyToOne',
      'plugin::upload.folder'
    >;
    path: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMax<
        {
          min: 1;
        },
        number
      >;
    pathId: Attribute.Integer & Attribute.Required & Attribute.Unique;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::upload.folder',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface PluginUsersPermissionsPermission
  extends Schema.CollectionType {
  collectionName: 'up_permissions';
  info: {
    description: '';
    displayName: 'Permission';
    name: 'permission';
    pluralName: 'permissions';
    singularName: 'permission';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    action: Attribute.String & Attribute.Required;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::users-permissions.permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    role: Attribute.Relation<
      'plugin::users-permissions.permission',
      'manyToOne',
      'plugin::users-permissions.role'
    >;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::users-permissions.permission',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
  };
}

export interface PluginUsersPermissionsRole extends Schema.CollectionType {
  collectionName: 'up_roles';
  info: {
    description: '';
    displayName: 'Role';
    name: 'role';
    pluralName: 'roles';
    singularName: 'role';
  };
  pluginOptions: {
    'content-manager': {
      visible: false;
    };
    'content-type-builder': {
      visible: false;
    };
  };
  attributes: {
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::users-permissions.role',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    description: Attribute.String;
    name: Attribute.String &
      Attribute.Required &
      Attribute.SetMinMaxLength<{
        minLength: 3;
      }>;
    permissions: Attribute.Relation<
      'plugin::users-permissions.role',
      'oneToMany',
      'plugin::users-permissions.permission'
    >;
    type: Attribute.String & Attribute.Unique;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::users-permissions.role',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    users: Attribute.Relation<
      'plugin::users-permissions.role',
      'oneToMany',
      'plugin::users-permissions.user'
    >;
  };
}

export interface PluginUsersPermissionsUser extends Schema.CollectionType {
  collectionName: 'up_users';
  info: {
    description: '';
    displayName: 'User';
    name: 'user';
    pluralName: 'users';
    singularName: 'user';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    ai_turns_count: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    ai_turns_date: Attribute.String;
    app_opened_datetime: Attribute.DateTime;
    auto_conversation: Attribute.Boolean & Attribute.DefaultTo<false>;
    auto_create_flashcards: Attribute.Boolean & Attribute.DefaultTo<true>;
    auto_play_voice: Attribute.Boolean & Attribute.DefaultTo<true>;
    auto_save_corrections: Attribute.Boolean & Attribute.DefaultTo<true>;
    auto_start_recording: Attribute.Boolean & Attribute.DefaultTo<false>;
    blocked: Attribute.Boolean & Attribute.DefaultTo<false>;
    confirm_transcript: Attribute.Boolean & Attribute.DefaultTo<true>;
    confirmationToken: Attribute.String & Attribute.Private;
    confirmed: Attribute.Boolean & Attribute.DefaultTo<false>;
    correct_sentence_goal: Attribute.Integer &
      Attribute.SetMinMax<
        {
          max: 100;
          min: 1;
        },
        number
      > &
      Attribute.DefaultTo<10>;
    createdAt: Attribute.DateTime;
    createdBy: Attribute.Relation<
      'plugin::users-permissions.user',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    daily_reminder_enabled: Attribute.Boolean & Attribute.DefaultTo<false>;
    daily_reminder_time: Attribute.String & Attribute.DefaultTo<'09:00'>;
    email: Attribute.Email &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    english_level: Attribute.Enumeration<['A1', 'A2', 'B1', 'B2', 'C1', 'C2']>;
    hide_screen_explanation: Attribute.Boolean & Attribute.DefaultTo<false>;
    is_admin: Attribute.Boolean &
      Attribute.Required &
      Attribute.DefaultTo<false>;
    music: Attribute.Boolean & Attribute.Required & Attribute.DefaultTo<true>;
    name: Attribute.String;
    notifications: Attribute.Relation<
      'plugin::users-permissions.user',
      'oneToMany',
      'api::notification.notification'
    >;
    password: Attribute.Password &
      Attribute.Private &
      Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    practice_language: Attribute.Enumeration<
      ['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ru', 'hi']
    > &
      Attribute.DefaultTo<'en'>;
    provider: Attribute.String;
    push_subscribed: Attribute.Boolean & Attribute.DefaultTo<false>;
    resetPasswordToken: Attribute.String & Attribute.Private;
    response_language: Attribute.Enumeration<
      ['en', 'es', 'fr', 'de', 'it', 'hi', 'pt', 'zh', 'ja', 'ru']
    > &
      Attribute.DefaultTo<'en'>;
    role: Attribute.Relation<
      'plugin::users-permissions.user',
      'manyToOne',
      'plugin::users-permissions.role'
    >;
    show_translations: Attribute.Boolean & Attribute.DefaultTo<false>;
    sound: Attribute.Boolean & Attribute.DefaultTo<true>;
    speaking_auto_notes_count: Attribute.Integer &
      Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<0>;
    special: Attribute.Boolean & Attribute.DefaultTo<false>;
    surname: Attribute.String;
    translation_language: Attribute.Enumeration<
      ['none', 'en', 'es', 'fr', 'de', 'it', 'hi', 'pt', 'zh', 'ja', 'ru']
    > &
      Attribute.DefaultTo<'none'>;
    tutor_memory: Attribute.JSON & Attribute.DefaultTo<[]>;
    type_messages_enabled: Attribute.Boolean & Attribute.DefaultTo<false>;
    updatedAt: Attribute.DateTime;
    updatedBy: Attribute.Relation<
      'plugin::users-permissions.user',
      'oneToOne',
      'admin::user'
    > &
      Attribute.Private;
    user_progress: Attribute.Relation<
      'plugin::users-permissions.user',
      'oneToOne',
      'api::user-progress.user-progress'
    >;
    user_timezone: Attribute.String;
    username: Attribute.String &
      Attribute.Unique &
      Attribute.SetMinMaxLength<{
        minLength: 3;
      }>;
    volume_music: Attribute.Integer &
      Attribute.Required &
      Attribute.SetMinMax<
        {
          max: 100;
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<50>;
    volume_sound: Attribute.Integer &
      Attribute.Required &
      Attribute.SetMinMax<
        {
          max: 100;
          min: 0;
        },
        number
      > &
      Attribute.DefaultTo<50>;
  };
}

declare module '@strapi/types' {
  export module Shared {
    export interface ContentTypes {
      'admin::api-token': AdminApiToken;
      'admin::api-token-permission': AdminApiTokenPermission;
      'admin::permission': AdminPermission;
      'admin::role': AdminRole;
      'admin::transfer-token': AdminTransferToken;
      'admin::transfer-token-permission': AdminTransferTokenPermission;
      'admin::user': AdminUser;
      'api::ai.ai-config': ApiAiAiConfig;
      'api::app-feature-config.app-feature-config': ApiAppFeatureConfigAppFeatureConfig;
      'api::card-review-log.card-review-log': ApiCardReviewLogCardReviewLog;
      'api::card-review-state.card-review-state': ApiCardReviewStateCardReviewState;
      'api::conversation-prompt.conversation-prompt': ApiConversationPromptConversationPrompt;
      'api::custom-flashcard-note-type.custom-flashcard-note-type': ApiCustomFlashcardNoteTypeCustomFlashcardNoteType;
      'api::exercise.exercise': ApiExerciseExercise;
      'api::flashcard-deck.flashcard-deck': ApiFlashcardDeckFlashcardDeck;
      'api::flashcard-note.flashcard-note': ApiFlashcardNoteFlashcardNote;
      'api::flashcard.flashcard': ApiFlashcardFlashcard;
      'api::lesson.lesson': ApiLessonLesson;
      'api::mobile-app-policy.mobile-app-policy': ApiMobileAppPolicyMobileAppPolicy;
      'api::notification.notification': ApiNotificationNotification;
      'api::placement-test-result.placement-test-result': ApiPlacementTestResultPlacementTestResult;
      'api::speaking-game.speaking-game': ApiSpeakingGameSpeakingGame;
      'api::speaking-session.speaking-session': ApiSpeakingSessionSpeakingSession;
      'api::speaking-topic.speaking-topic': ApiSpeakingTopicSpeakingTopic;
      'api::study-hall.study-hall': ApiStudyHallStudyHall;
      'api::user-note.user-note': ApiUserNoteUserNote;
      'api::user-progress.user-progress': ApiUserProgressUserProgress;
      'api::user-vocabulary-progress.user-vocabulary-progress': ApiUserVocabularyProgressUserVocabularyProgress;
      'api::vocabulary-entry.vocabulary-entry': ApiVocabularyEntryVocabularyEntry;
      'plugin::content-releases.release': PluginContentReleasesRelease;
      'plugin::content-releases.release-action': PluginContentReleasesReleaseAction;
      'plugin::i18n.locale': PluginI18NLocale;
      'plugin::upload.file': PluginUploadFile;
      'plugin::upload.folder': PluginUploadFolder;
      'plugin::users-permissions.permission': PluginUsersPermissionsPermission;
      'plugin::users-permissions.role': PluginUsersPermissionsRole;
      'plugin::users-permissions.user': PluginUsersPermissionsUser;
    }
  }
}
