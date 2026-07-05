import type { Schema, Struct } from '@strapi/strapi';

export interface AdminApiToken extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_api_tokens';
  info: {
    description: '';
    displayName: 'Api Token';
    name: 'Api Token';
    pluralName: 'api-tokens';
    singularName: 'api-token';
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
    accessKey: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    adminPermissions: Schema.Attribute.Relation<
      'oneToMany',
      'admin::permission'
    >;
    adminUserOwner: Schema.Attribute.Relation<'manyToOne', 'admin::user'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    description: Schema.Attribute.String &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }> &
      Schema.Attribute.DefaultTo<''>;
    encryptedKey: Schema.Attribute.Text &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    expiresAt: Schema.Attribute.DateTime;
    kind: Schema.Attribute.Enumeration<['content-api', 'admin']> &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'content-api'>;
    lastUsedAt: Schema.Attribute.DateTime;
    lifespan: Schema.Attribute.BigInteger;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<'oneToMany', 'admin::api-token'> &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    permissions: Schema.Attribute.Relation<
      'oneToMany',
      'admin::api-token-permission'
    >;
    publishedAt: Schema.Attribute.DateTime;
    type: Schema.Attribute.Enumeration<['read-only', 'full-access', 'custom']> &
      Schema.Attribute.DefaultTo<'read-only'>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface AdminApiTokenPermission extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_api_token_permissions';
  info: {
    description: '';
    displayName: 'API Token Permission';
    name: 'API Token Permission';
    pluralName: 'api-token-permissions';
    singularName: 'api-token-permission';
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
    action: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'admin::api-token-permission'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    token: Schema.Attribute.Relation<'manyToOne', 'admin::api-token'>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface AdminPermission extends Struct.CollectionTypeSchema {
  collectionName: 'admin_permissions';
  info: {
    description: '';
    displayName: 'Permission';
    name: 'Permission';
    pluralName: 'permissions';
    singularName: 'permission';
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
    action: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    actionParameters: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<{}>;
    apiToken: Schema.Attribute.Relation<'manyToOne', 'admin::api-token'>;
    conditions: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<'oneToMany', 'admin::permission'> &
      Schema.Attribute.Private;
    properties: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<{}>;
    publishedAt: Schema.Attribute.DateTime;
    role: Schema.Attribute.Relation<'manyToOne', 'admin::role'>;
    subject: Schema.Attribute.String &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface AdminRole extends Struct.CollectionTypeSchema {
  collectionName: 'admin_roles';
  info: {
    description: '';
    displayName: 'Role';
    name: 'Role';
    pluralName: 'roles';
    singularName: 'role';
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
    code: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    description: Schema.Attribute.String;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<'oneToMany', 'admin::role'> &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    permissions: Schema.Attribute.Relation<'oneToMany', 'admin::permission'>;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    users: Schema.Attribute.Relation<'manyToMany', 'admin::user'>;
  };
}

export interface AdminSession extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_sessions';
  info: {
    description: 'Session Manager storage';
    displayName: 'Session';
    name: 'Session';
    pluralName: 'sessions';
    singularName: 'session';
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
    i18n: {
      localized: false;
    };
  };
  attributes: {
    absoluteExpiresAt: Schema.Attribute.DateTime & Schema.Attribute.Private;
    childId: Schema.Attribute.String & Schema.Attribute.Private;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    deviceId: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Private;
    expiresAt: Schema.Attribute.DateTime &
      Schema.Attribute.Required &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<'oneToMany', 'admin::session'> &
      Schema.Attribute.Private;
    origin: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    sessionId: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Private &
      Schema.Attribute.Unique;
    status: Schema.Attribute.String & Schema.Attribute.Private;
    type: Schema.Attribute.String & Schema.Attribute.Private;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    userId: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Private;
  };
}

export interface AdminTransferToken extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_transfer_tokens';
  info: {
    description: '';
    displayName: 'Transfer Token';
    name: 'Transfer Token';
    pluralName: 'transfer-tokens';
    singularName: 'transfer-token';
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
    accessKey: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    description: Schema.Attribute.String &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }> &
      Schema.Attribute.DefaultTo<''>;
    expiresAt: Schema.Attribute.DateTime;
    lastUsedAt: Schema.Attribute.DateTime;
    lifespan: Schema.Attribute.BigInteger;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'admin::transfer-token'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    permissions: Schema.Attribute.Relation<
      'oneToMany',
      'admin::transfer-token-permission'
    >;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface AdminTransferTokenPermission
  extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_transfer_token_permissions';
  info: {
    description: '';
    displayName: 'Transfer Token Permission';
    name: 'Transfer Token Permission';
    pluralName: 'transfer-token-permissions';
    singularName: 'transfer-token-permission';
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
    action: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'admin::transfer-token-permission'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    token: Schema.Attribute.Relation<'manyToOne', 'admin::transfer-token'>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface AdminUser extends Struct.CollectionTypeSchema {
  collectionName: 'admin_users';
  info: {
    description: '';
    displayName: 'User';
    name: 'User';
    pluralName: 'users';
    singularName: 'user';
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
    apiTokens: Schema.Attribute.Relation<'oneToMany', 'admin::api-token'> &
      Schema.Attribute.Private;
    blocked: Schema.Attribute.Boolean &
      Schema.Attribute.Private &
      Schema.Attribute.DefaultTo<false>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    email: Schema.Attribute.Email &
      Schema.Attribute.Required &
      Schema.Attribute.Private &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    firstname: Schema.Attribute.String &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    isActive: Schema.Attribute.Boolean &
      Schema.Attribute.Private &
      Schema.Attribute.DefaultTo<false>;
    lastname: Schema.Attribute.String &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<'oneToMany', 'admin::user'> &
      Schema.Attribute.Private;
    password: Schema.Attribute.Password &
      Schema.Attribute.Private &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    preferedLanguage: Schema.Attribute.String;
    publishedAt: Schema.Attribute.DateTime;
    registrationToken: Schema.Attribute.String & Schema.Attribute.Private;
    resetPasswordToken: Schema.Attribute.String & Schema.Attribute.Private;
    roles: Schema.Attribute.Relation<'manyToMany', 'admin::role'> &
      Schema.Attribute.Private;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    username: Schema.Attribute.String;
  };
}

export interface ApiAiAiConfig extends Struct.SingleTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<'oneToMany', 'api::ai.ai-config'> &
      Schema.Attribute.Private;
    notes: Schema.Attribute.Text & Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiAppFeatureConfigAppFeatureConfig
  extends Struct.SingleTypeSchema {
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
    advancedLevelsRequiringPremium: Schema.Attribute.JSON &
      Schema.Attribute.DefaultTo<['B2', 'C1', 'C2']>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    defaultEasyIntervalDays: Schema.Attribute.Decimal &
      Schema.Attribute.SetMinMax<
        {
          min: 0.01;
        },
        number
      > &
      Schema.Attribute.DefaultTo<5>;
    defaultLearningStepsMinutes: Schema.Attribute.JSON &
      Schema.Attribute.DefaultTo<[2, 8, 10]>;
    freeDailyConversationTurns: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<10>;
    freeMaxDecks: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<1>;
    freeMaxNewCardsPerDay: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<10>;
    freeMaxSavedWords: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<20>;
    freePlacementRetakesPerMonth: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<1>;
    freePreviewWordsPerAdvancedList: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<10>;
    freeRolePlayPerCategory: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<2>;
    freeTopicLevelGroups: Schema.Attribute.JSON &
      Schema.Attribute.DefaultTo<['intermediate']>;
    gamesRequirePremium: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    hiddenSpeakingTabs: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::app-feature-config.app-feature-config'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiCardReviewLogCardReviewLog
  extends Struct.CollectionTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    deck: Schema.Attribute.Relation<
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    durationMs: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    flashcard: Schema.Attribute.Relation<
      'manyToOne',
      'api::flashcard.flashcard'
    >;
    intervalAfter: Schema.Attribute.Float & Schema.Attribute.DefaultTo<0>;
    intervalBefore: Schema.Attribute.Float & Schema.Attribute.DefaultTo<0>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::card-review-log.card-review-log'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    rating: Schema.Attribute.Enumeration<['again', 'hard', 'good', 'easy']> &
      Schema.Attribute.Required;
    reviewedAt: Schema.Attribute.DateTime & Schema.Attribute.Required;
    stateAfter: Schema.Attribute.String;
    stateBefore: Schema.Attribute.String;
    undoSnapshot: Schema.Attribute.JSON;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiCardReviewStateCardReviewState
  extends Struct.CollectionTypeSchema {
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
    buriedUntil: Schema.Attribute.DateTime;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    dueAt: Schema.Attribute.DateTime;
    easeFactor: Schema.Attribute.Float & Schema.Attribute.DefaultTo<2.5>;
    firstStudiedAt: Schema.Attribute.DateTime;
    flashcard: Schema.Attribute.Relation<
      'oneToOne',
      'api::flashcard.flashcard'
    >;
    intervalDays: Schema.Attribute.Float & Schema.Attribute.DefaultTo<0>;
    lapses: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    lastReviewedAt: Schema.Attribute.DateTime;
    learningStep: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::card-review-state.card-review-state'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    repetitions: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    state: Schema.Attribute.Enumeration<
      ['new', 'learning', 'review', 'relearning']
    > &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'new'>;
    suspended: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiCustomFlashcardNoteTypeCustomFlashcardNoteType
  extends Struct.CollectionTypeSchema {
  collectionName: 'custom_flashcard_note_types';
  info: {
    description: 'User-defined note templates.';
    displayName: 'Custom Flashcard Note Type';
    pluralName: 'custom-flashcard-note-types';
    singularName: 'custom-flashcard-note-type';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    cardTemplates: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    css: Schema.Attribute.Text;
    fields: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::custom-flashcard-note-type.custom-flashcard-note-type'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String & Schema.Attribute.Required;
    publishedAt: Schema.Attribute.DateTime;
    themeId: Schema.Attribute.String & Schema.Attribute.DefaultTo<'classic'>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiExerciseExercise extends Struct.CollectionTypeSchema {
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
    aiFeedbackEnabled: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    correctAnswer: Schema.Attribute.Text;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    lesson: Schema.Attribute.Relation<'manyToOne', 'api::lesson.lesson'>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::exercise.exercise'
    > &
      Schema.Attribute.Private;
    options: Schema.Attribute.JSON;
    prompt: Schema.Attribute.Text & Schema.Attribute.Required;
    publishedAt: Schema.Attribute.DateTime;
    type: Schema.Attribute.Enumeration<
      ['multipleChoice', 'fillBlank', 'speakingPrompt', 'conversation']
    > &
      Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiFlashcardDeckFlashcardDeck
  extends Struct.CollectionTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    deckOptions: Schema.Attribute.JSON;
    deckSlug: Schema.Attribute.String & Schema.Attribute.Required;
    description: Schema.Attribute.Text;
    filterQuery: Schema.Attribute.JSON;
    flashcards: Schema.Attribute.Relation<
      'oneToMany',
      'api::flashcard.flashcard'
    >;
    isDefault: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    isFiltered: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::flashcard-deck.flashcard-deck'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String & Schema.Attribute.Required;
    parentDeck: Schema.Attribute.Relation<
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiFlashcardNoteFlashcardNote
  extends Struct.CollectionTypeSchema {
  collectionName: 'flashcard_notes';
  info: {
    description: 'A note \u2014 generates one or more flashcards.';
    displayName: 'Flashcard Note';
    pluralName: 'flashcard-notes';
    singularName: 'flashcard-note';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    createReverse: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    deck: Schema.Attribute.Relation<
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    fields: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<{}>;
    flashcards: Schema.Attribute.Relation<
      'oneToMany',
      'api::flashcard.flashcard'
    >;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::flashcard-note.flashcard-note'
    > &
      Schema.Attribute.Private;
    marked: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    mediaUrl: Schema.Attribute.String;
    noteType: Schema.Attribute.Enumeration<
      [
        'basic',
        'basic_reversed',
        'basic_optional_reversed',
        'basic_type_answer',
        'cloze',
        'image_occlusion',
      ]
    > &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'basic'>;
    publishedAt: Schema.Attribute.DateTime;
    tags: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    userNote: Schema.Attribute.Relation<
      'manyToOne',
      'api::user-note.user-note'
    >;
  };
}

export interface ApiFlashcardFlashcard extends Struct.CollectionTypeSchema {
  collectionName: 'flashcards';
  info: {
    description: "Generated study card from a flashcard note's card template.";
    displayName: 'Flashcard';
    pluralName: 'flashcards';
    singularName: 'flashcard';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    back: Schema.Attribute.Text & Schema.Attribute.Required;
    cardType: Schema.Attribute.Enumeration<
      ['basic', 'cloze', 'reversed', 'type_answer', 'image_occlusion']
    > &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'basic'>;
    clozeIndex: Schema.Attribute.Integer;
    clozeText: Schema.Attribute.Text;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    deck: Schema.Attribute.Relation<
      'manyToOne',
      'api::flashcard-deck.flashcard-deck'
    >;
    flag: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          max: 7;
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    flashcardNote: Schema.Attribute.Relation<
      'manyToOne',
      'api::flashcard-note.flashcard-note'
    >;
    front: Schema.Attribute.Text & Schema.Attribute.Required;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::flashcard.flashcard'
    > &
      Schema.Attribute.Private;
    mediaUrl: Schema.Attribute.String;
    occlusionData: Schema.Attribute.JSON;
    publishedAt: Schema.Attribute.DateTime;
    reviewState: Schema.Attribute.Relation<
      'oneToOne',
      'api::card-review-state.card-review-state'
    >;
    tags: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    templateName: Schema.Attribute.String &
      Schema.Attribute.DefaultTo<'Card 1'>;
    templateOrdinal: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    userNote: Schema.Attribute.Relation<
      'manyToOne',
      'api::user-note.user-note'
    >;
  };
}

export interface ApiLessonLesson extends Struct.CollectionTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    description: Schema.Attribute.RichText;
    exercises: Schema.Attribute.Relation<'oneToMany', 'api::exercise.exercise'>;
    level: Schema.Attribute.Enumeration<['A1', 'A2', 'B1', 'B2', 'C1', 'C2']> &
      Schema.Attribute.Required;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::lesson.lesson'
    > &
      Schema.Attribute.Private;
    order: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    publishedAt: Schema.Attribute.DateTime;
    skillType: Schema.Attribute.Enumeration<
      ['speaking', 'grammar', 'vocabulary', 'listening']
    > &
      Schema.Attribute.Required;
    title: Schema.Attribute.String & Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiMobileAppPolicyMobileAppPolicy
  extends Struct.SingleTypeSchema {
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
    androidStoreUrl: Schema.Attribute.String;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    forceMinimumAndroidBuild: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    forceMinimumIosBuild: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    iosStoreUrl: Schema.Attribute.String;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::mobile-app-policy.mobile-app-policy'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    softCampaignId: Schema.Attribute.String & Schema.Attribute.DefaultTo<''>;
    softMessage: Schema.Attribute.Text;
    softSuggestBelowAndroidBuild: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    softSuggestBelowIosBuild: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiNotificationNotification
  extends Struct.CollectionTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::notification.notification'
    > &
      Schema.Attribute.Private;
    metadata: Schema.Attribute.JSON;
    publishedAt: Schema.Attribute.DateTime;
    read: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    text: Schema.Attribute.String;
    title: Schema.Attribute.String;
    type: Schema.Attribute.Enumeration<
      ['congrats', 'unfinished_goal', 'assignment', 'class_membership']
    >;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    users_permissions_user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiPlacementTestResultPlacementTestResult
  extends Struct.CollectionTypeSchema {
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
    answersSummary: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<{}>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    levelBucket: Schema.Attribute.Enumeration<
      ['beginner', 'intermediate', 'advanced']
    > &
      Schema.Attribute.Required;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::placement-test-result.placement-test-result'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    score: Schema.Attribute.Decimal & Schema.Attribute.Required;
    suggestedLevel: Schema.Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    > &
      Schema.Attribute.Required;
    takenAt: Schema.Attribute.DateTime & Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiSpeakingGameSpeakingGame
  extends Struct.CollectionTypeSchema {
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
    accessMode: Schema.Attribute.Enumeration<['automatic', 'free', 'premium']> &
      Schema.Attribute.DefaultTo<'automatic'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    description: Schema.Attribute.Text;
    iconKey: Schema.Attribute.String;
    isVisible: Schema.Attribute.Boolean &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<true>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::speaking-game.speaking-game'
    > &
      Schema.Attribute.Private;
    openingMessage: Schema.Attribute.Text;
    order: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    publishedAt: Schema.Attribute.DateTime;
    slug: Schema.Attribute.UID<'title'> & Schema.Attribute.Required;
    systemPrompt: Schema.Attribute.Text & Schema.Attribute.Required;
    title: Schema.Attribute.String & Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiSpeakingRolePlaySpeakingRolePlay
  extends Struct.CollectionTypeSchema {
  collectionName: 'speaking_role_plays';
  info: {
    description: 'Curated role-play scenarios for speaking practice (never mixed with user-submitted custom scenarios, which stay client-side)';
    displayName: 'Speaking Role Play';
    pluralName: 'speaking-role-plays';
    singularName: 'speaking-role-play';
  };
  options: {
    draftAndPublish: true;
  };
  attributes: {
    accessMode: Schema.Attribute.Enumeration<['automatic', 'free', 'premium']> &
      Schema.Attribute.DefaultTo<'automatic'>;
    category: Schema.Attribute.Enumeration<
      [
        'daily_life',
        'career',
        'travel',
        'relationships',
        'language_testing',
        'business',
        'health',
        'education',
        'technology',
        'finance',
        'housing',
        'emergencies',
        'customer_service',
        'entertainment',
        'social',
        'debate',
        'storytelling',
        'fantasy',
        'survival',
        'mystery',
        'science_fiction',
      ]
    > &
      Schema.Attribute.DefaultTo<'daily_life'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    difficultyLevel: Schema.Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    > &
      Schema.Attribute.Required;
    iconKey: Schema.Attribute.String;
    isVisible: Schema.Attribute.Boolean &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<true>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::speaking-role-play.speaking-role-play'
    > &
      Schema.Attribute.Private;
    order: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    publishedAt: Schema.Attribute.DateTime;
    scenario: Schema.Attribute.Text & Schema.Attribute.Required;
    suggestedVocabulary: Schema.Attribute.JSON;
    title: Schema.Attribute.String & Schema.Attribute.Required;
    tutorRole: Schema.Attribute.String;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    userRole: Schema.Attribute.String;
  };
}

export interface ApiSpeakingSessionSpeakingSession
  extends Struct.CollectionTypeSchema {
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
    completedAt: Schema.Attribute.DateTime & Schema.Attribute.Required;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    durationMinutes: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<1>;
    feedback: Schema.Attribute.Text;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::speaking-session.speaking-session'
    > &
      Schema.Attribute.Private;
    mode: Schema.Attribute.Enumeration<
      ['chat', 'role_play', 'topic', 'game', 'lesson']
    > &
      Schema.Attribute.Required;
    publishedAt: Schema.Attribute.DateTime;
    referenceKey: Schema.Attribute.String;
    score: Schema.Attribute.Integer &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMax<
        {
          max: 10;
          min: 0;
        },
        number
      >;
    summary: Schema.Attribute.String;
    title: Schema.Attribute.String & Schema.Attribute.Required;
    turnCount: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiSpeakingTopicSpeakingTopic
  extends Struct.CollectionTypeSchema {
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
    accessMode: Schema.Attribute.Enumeration<['automatic', 'free', 'premium']> &
      Schema.Attribute.DefaultTo<'automatic'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    iconKey: Schema.Attribute.String;
    isVisible: Schema.Attribute.Boolean &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<true>;
    levelGroup: Schema.Attribute.Enumeration<
      ['intermediate', 'advanced', 'expert']
    > &
      Schema.Attribute.Required;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::speaking-topic.speaking-topic'
    > &
      Schema.Attribute.Private;
    order: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    publishedAt: Schema.Attribute.DateTime;
    starterPrompt: Schema.Attribute.Text & Schema.Attribute.Required;
    suggestedVocabulary: Schema.Attribute.JSON;
    title: Schema.Attribute.String & Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiStudyHallStudyHall extends Struct.SingleTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::study-hall.study-hall'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface ApiSubscriptionSubscription
  extends Struct.CollectionTypeSchema {
  collectionName: 'subscriptions';
  info: {
    description: 'Per-user premium subscription state, verified against Apple/Google.';
    displayName: 'Subscription';
    pluralName: 'subscriptions';
    singularName: 'subscription';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    autoRenewing: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<true>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    currentPeriodEnd: Schema.Attribute.DateTime & Schema.Attribute.Required;
    lastEventPayload: Schema.Attribute.JSON;
    lastVerifiedAt: Schema.Attribute.DateTime;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::subscription.subscription'
    > &
      Schema.Attribute.Private;
    originalTransactionId: Schema.Attribute.String;
    platform: Schema.Attribute.Enumeration<['ios', 'android']> &
      Schema.Attribute.Required;
    productId: Schema.Attribute.String & Schema.Attribute.Required;
    publishedAt: Schema.Attribute.DateTime;
    purchaseToken: Schema.Attribute.Text;
    subscriptionStatus: Schema.Attribute.Enumeration<
      ['active', 'expired', 'cancelled', 'grace_period', 'billing_retry']
    > &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'active'>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'oneToOne',
      'plugin::users-permissions.user'
    >;
  };
}

export interface ApiUserNoteUserNote extends Struct.CollectionTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    definition: Schema.Attribute.Text;
    exampleSentence: Schema.Attribute.Text;
    flashcards: Schema.Attribute.Relation<
      'oneToMany',
      'api::flashcard.flashcard'
    >;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::user-note.user-note'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    source: Schema.Attribute.Enumeration<['catalog', 'speaking', 'manual']> &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'manual'>;
    tags: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    vocabularyEntry: Schema.Attribute.Relation<
      'manyToOne',
      'api::vocabulary-entry.vocabulary-entry'
    >;
    word: Schema.Attribute.String & Schema.Attribute.Required;
  };
}

export interface ApiUserProgressUserProgress
  extends Struct.CollectionTypeSchema {
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
    completedExercises: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    currentLevel: Schema.Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    > &
      Schema.Attribute.DefaultTo<'B1'>;
    flashcardReviewStreakDays: Schema.Attribute.Integer &
      Schema.Attribute.DefaultTo<0>;
    lastFlashcardReviewAt: Schema.Attribute.DateTime;
    lastPracticeAt: Schema.Attribute.DateTime;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::user-progress.user-progress'
    > &
      Schema.Attribute.Private;
    perfectSentencesCount: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    publishedAt: Schema.Attribute.DateTime;
    spokenWordBank: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    streakDays: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    totalSpeakingMinutes: Schema.Attribute.Integer &
      Schema.Attribute.DefaultTo<0>;
    uniqueWordsUsed: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'oneToOne',
      'plugin::users-permissions.user'
    >;
    weakAreas: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
  };
}

export interface ApiUserVocabularyProgressUserVocabularyProgress
  extends Struct.CollectionTypeSchema {
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::user-vocabulary-progress.user-vocabulary-progress'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    savedAt: Schema.Attribute.DateTime;
    status: Schema.Attribute.Enumeration<['new', 'learning', 'known']> &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'new'>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.user'
    >;
    vocabularyEntry: Schema.Attribute.Relation<
      'manyToOne',
      'api::vocabulary-entry.vocabulary-entry'
    >;
  };
}

export interface ApiVocabularyEntryVocabularyEntry
  extends Struct.CollectionTypeSchema {
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
    audioUrl: Schema.Attribute.String;
    cefrLevel: Schema.Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    >;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    definition: Schema.Attribute.Text & Schema.Attribute.Required;
    entryType: Schema.Attribute.Enumeration<
      ['word', 'phrase', 'idiom', 'expression']
    > &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'word'>;
    examples: Schema.Attribute.JSON;
    exampleSentence: Schema.Attribute.Text;
    externalId: Schema.Attribute.String & Schema.Attribute.Unique;
    frequencyBucket: Schema.Attribute.String;
    frequencyRank: Schema.Attribute.Integer & Schema.Attribute.DefaultTo<0>;
    ipa: Schema.Attribute.String;
    lemma: Schema.Attribute.String;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'api::vocabulary-entry.vocabulary-entry'
    > &
      Schema.Attribute.Private;
    partOfSpeech: Schema.Attribute.String;
    publishedAt: Schema.Attribute.DateTime;
    sensePriority: Schema.Attribute.Enumeration<['core', 'extend', 'rare']>;
    source: Schema.Attribute.String & Schema.Attribute.DefaultTo<'import'>;
    topic: Schema.Attribute.String;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    userProgress: Schema.Attribute.Relation<
      'oneToMany',
      'api::user-vocabulary-progress.user-vocabulary-progress'
    >;
    word: Schema.Attribute.String & Schema.Attribute.Required;
  };
}

export interface PluginContentReleasesRelease
  extends Struct.CollectionTypeSchema {
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
    actions: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::content-releases.release-action'
    >;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::content-releases.release'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String & Schema.Attribute.Required;
    publishedAt: Schema.Attribute.DateTime;
    releasedAt: Schema.Attribute.DateTime;
    scheduledAt: Schema.Attribute.DateTime;
    status: Schema.Attribute.Enumeration<
      ['ready', 'blocked', 'failed', 'done', 'empty']
    > &
      Schema.Attribute.Required;
    timezone: Schema.Attribute.String;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface PluginContentReleasesReleaseAction
  extends Struct.CollectionTypeSchema {
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
    contentType: Schema.Attribute.String & Schema.Attribute.Required;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    entryDocumentId: Schema.Attribute.String;
    isEntryValid: Schema.Attribute.Boolean;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::content-releases.release-action'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    release: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::content-releases.release'
    >;
    type: Schema.Attribute.Enumeration<['publish', 'unpublish']> &
      Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface PluginI18NLocale extends Struct.CollectionTypeSchema {
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
    code: Schema.Attribute.String & Schema.Attribute.Unique;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::i18n.locale'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.SetMinMax<
        {
          max: 50;
          min: 1;
        },
        number
      >;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface PluginReviewWorkflowsWorkflow
  extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_workflows';
  info: {
    description: '';
    displayName: 'Workflow';
    name: 'Workflow';
    pluralName: 'workflows';
    singularName: 'workflow';
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
    contentTypes: Schema.Attribute.JSON &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<'[]'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::review-workflows.workflow'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Unique;
    publishedAt: Schema.Attribute.DateTime;
    stageRequiredToPublish: Schema.Attribute.Relation<
      'oneToOne',
      'plugin::review-workflows.workflow-stage'
    >;
    stages: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::review-workflows.workflow-stage'
    >;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface PluginReviewWorkflowsWorkflowStage
  extends Struct.CollectionTypeSchema {
  collectionName: 'strapi_workflows_stages';
  info: {
    description: '';
    displayName: 'Stages';
    name: 'Workflow Stage';
    pluralName: 'workflow-stages';
    singularName: 'workflow-stage';
  };
  options: {
    draftAndPublish: false;
    version: '1.1.0';
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
    color: Schema.Attribute.String & Schema.Attribute.DefaultTo<'#4945FF'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::review-workflows.workflow-stage'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String;
    permissions: Schema.Attribute.Relation<'manyToMany', 'admin::permission'>;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    workflow: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::review-workflows.workflow'
    >;
  };
}

export interface PluginUploadFile extends Struct.CollectionTypeSchema {
  collectionName: 'files';
  info: {
    description: '';
    displayName: 'File';
    pluralName: 'files';
    singularName: 'file';
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
    alternativeText: Schema.Attribute.Text;
    caption: Schema.Attribute.Text;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    ext: Schema.Attribute.String;
    focalPoint: Schema.Attribute.JSON;
    folder: Schema.Attribute.Relation<'manyToOne', 'plugin::upload.folder'> &
      Schema.Attribute.Private;
    folderPath: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.Private &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    formats: Schema.Attribute.JSON;
    hash: Schema.Attribute.String & Schema.Attribute.Required;
    height: Schema.Attribute.Integer;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::upload.file'
    > &
      Schema.Attribute.Private;
    mime: Schema.Attribute.String & Schema.Attribute.Required;
    name: Schema.Attribute.String & Schema.Attribute.Required;
    previewUrl: Schema.Attribute.Text;
    provider: Schema.Attribute.String & Schema.Attribute.Required;
    provider_metadata: Schema.Attribute.JSON;
    publishedAt: Schema.Attribute.DateTime;
    related: Schema.Attribute.Relation<'morphToMany'>;
    size: Schema.Attribute.Decimal & Schema.Attribute.Required;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    url: Schema.Attribute.Text & Schema.Attribute.Required;
    width: Schema.Attribute.Integer;
  };
}

export interface PluginUploadFolder extends Struct.CollectionTypeSchema {
  collectionName: 'upload_folders';
  info: {
    displayName: 'Folder';
    pluralName: 'folders';
    singularName: 'folder';
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
    children: Schema.Attribute.Relation<'oneToMany', 'plugin::upload.folder'>;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    files: Schema.Attribute.Relation<'oneToMany', 'plugin::upload.file'>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::upload.folder'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    parent: Schema.Attribute.Relation<'manyToOne', 'plugin::upload.folder'>;
    path: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 1;
      }>;
    pathId: Schema.Attribute.Integer &
      Schema.Attribute.Required &
      Schema.Attribute.Unique;
    publishedAt: Schema.Attribute.DateTime;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface PluginUsersPermissionsPermission
  extends Struct.CollectionTypeSchema {
  collectionName: 'up_permissions';
  info: {
    description: '';
    displayName: 'Permission';
    name: 'permission';
    pluralName: 'permissions';
    singularName: 'permission';
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
    action: Schema.Attribute.String & Schema.Attribute.Required;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::users-permissions.permission'
    > &
      Schema.Attribute.Private;
    publishedAt: Schema.Attribute.DateTime;
    role: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.role'
    >;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
  };
}

export interface PluginUsersPermissionsRole
  extends Struct.CollectionTypeSchema {
  collectionName: 'up_roles';
  info: {
    description: '';
    displayName: 'Role';
    name: 'role';
    pluralName: 'roles';
    singularName: 'role';
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
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    description: Schema.Attribute.String;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::users-permissions.role'
    > &
      Schema.Attribute.Private;
    name: Schema.Attribute.String &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 3;
      }>;
    permissions: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::users-permissions.permission'
    >;
    publishedAt: Schema.Attribute.DateTime;
    type: Schema.Attribute.String & Schema.Attribute.Unique;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    users: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::users-permissions.user'
    >;
  };
}

export interface PluginUsersPermissionsUser
  extends Struct.CollectionTypeSchema {
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
    ai_turns_count: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    ai_turns_date: Schema.Attribute.String;
    app_opened_datetime: Schema.Attribute.DateTime;
    auto_conversation: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    auto_create_flashcards: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<true>;
    auto_play_voice: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<true>;
    auto_save_corrections: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<true>;
    auto_start_recording: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    blocked: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    confirmationToken: Schema.Attribute.String & Schema.Attribute.Private;
    confirmed: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    correct_sentence_goal: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          max: 100;
          min: 1;
        },
        number
      > &
      Schema.Attribute.DefaultTo<10>;
    correct_sentences_today_count: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    correct_sentences_today_date: Schema.Attribute.String;
    createdAt: Schema.Attribute.DateTime;
    createdBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    daily_reminder_enabled: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    daily_reminder_time: Schema.Attribute.String &
      Schema.Attribute.DefaultTo<'09:00'>;
    email: Schema.Attribute.Email &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    english_level: Schema.Attribute.Enumeration<
      ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
    >;
    hide_screen_explanation: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    is_admin: Schema.Attribute.Boolean &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<false>;
    locale: Schema.Attribute.String & Schema.Attribute.Private;
    localizations: Schema.Attribute.Relation<
      'oneToMany',
      'plugin::users-permissions.user'
    > &
      Schema.Attribute.Private;
    music: Schema.Attribute.Boolean &
      Schema.Attribute.Required &
      Schema.Attribute.DefaultTo<true>;
    name: Schema.Attribute.String;
    notifications: Schema.Attribute.Relation<
      'oneToMany',
      'api::notification.notification'
    >;
    old_data: Schema.Attribute.JSON & Schema.Attribute.Private;
    password: Schema.Attribute.Password &
      Schema.Attribute.Private &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 6;
      }>;
    practice_language: Schema.Attribute.Enumeration<
      ['en', 'es', 'fr', 'de', 'it', 'pt', 'zh', 'ja', 'ru', 'hi']
    > &
      Schema.Attribute.DefaultTo<'en'>;
    provider: Schema.Attribute.String;
    publishedAt: Schema.Attribute.DateTime;
    push_subscribed: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    resetPasswordToken: Schema.Attribute.String & Schema.Attribute.Private;
    response_language: Schema.Attribute.Enumeration<
      ['en', 'es', 'fr', 'de', 'it', 'hi', 'pt', 'zh', 'ja', 'ru']
    > &
      Schema.Attribute.DefaultTo<'en'>;
    role: Schema.Attribute.Relation<
      'manyToOne',
      'plugin::users-permissions.role'
    >;
    show_translations: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    sound: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<true>;
    speaking_auto_notes_count: Schema.Attribute.Integer &
      Schema.Attribute.SetMinMax<
        {
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<0>;
    special: Schema.Attribute.Boolean & Schema.Attribute.DefaultTo<false>;
    surname: Schema.Attribute.String;
    translation_language: Schema.Attribute.Enumeration<
      ['none', 'en', 'es', 'fr', 'de', 'it', 'hi', 'pt', 'zh', 'ja', 'ru']
    > &
      Schema.Attribute.DefaultTo<'none'>;
    tutor_memory: Schema.Attribute.JSON & Schema.Attribute.DefaultTo<[]>;
    type_messages_enabled: Schema.Attribute.Boolean &
      Schema.Attribute.DefaultTo<false>;
    updatedAt: Schema.Attribute.DateTime;
    updatedBy: Schema.Attribute.Relation<'oneToOne', 'admin::user'> &
      Schema.Attribute.Private;
    user_progress: Schema.Attribute.Relation<
      'oneToOne',
      'api::user-progress.user-progress'
    >;
    user_timezone: Schema.Attribute.String;
    username: Schema.Attribute.String &
      Schema.Attribute.Unique &
      Schema.Attribute.SetMinMaxLength<{
        minLength: 3;
      }>;
    volume_music: Schema.Attribute.Integer &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMax<
        {
          max: 100;
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<50>;
    volume_sound: Schema.Attribute.Integer &
      Schema.Attribute.Required &
      Schema.Attribute.SetMinMax<
        {
          max: 100;
          min: 0;
        },
        number
      > &
      Schema.Attribute.DefaultTo<50>;
  };
}

declare module '@strapi/strapi' {
  export module Public {
    export interface ContentTypeSchemas {
      'admin::api-token': AdminApiToken;
      'admin::api-token-permission': AdminApiTokenPermission;
      'admin::permission': AdminPermission;
      'admin::role': AdminRole;
      'admin::session': AdminSession;
      'admin::transfer-token': AdminTransferToken;
      'admin::transfer-token-permission': AdminTransferTokenPermission;
      'admin::user': AdminUser;
      'api::ai.ai-config': ApiAiAiConfig;
      'api::app-feature-config.app-feature-config': ApiAppFeatureConfigAppFeatureConfig;
      'api::card-review-log.card-review-log': ApiCardReviewLogCardReviewLog;
      'api::card-review-state.card-review-state': ApiCardReviewStateCardReviewState;
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
      'api::speaking-role-play.speaking-role-play': ApiSpeakingRolePlaySpeakingRolePlay;
      'api::speaking-session.speaking-session': ApiSpeakingSessionSpeakingSession;
      'api::speaking-topic.speaking-topic': ApiSpeakingTopicSpeakingTopic;
      'api::study-hall.study-hall': ApiStudyHallStudyHall;
      'api::subscription.subscription': ApiSubscriptionSubscription;
      'api::user-note.user-note': ApiUserNoteUserNote;
      'api::user-progress.user-progress': ApiUserProgressUserProgress;
      'api::user-vocabulary-progress.user-vocabulary-progress': ApiUserVocabularyProgressUserVocabularyProgress;
      'api::vocabulary-entry.vocabulary-entry': ApiVocabularyEntryVocabularyEntry;
      'plugin::content-releases.release': PluginContentReleasesRelease;
      'plugin::content-releases.release-action': PluginContentReleasesReleaseAction;
      'plugin::i18n.locale': PluginI18NLocale;
      'plugin::review-workflows.workflow': PluginReviewWorkflowsWorkflow;
      'plugin::review-workflows.workflow-stage': PluginReviewWorkflowsWorkflowStage;
      'plugin::upload.file': PluginUploadFile;
      'plugin::upload.folder': PluginUploadFolder;
      'plugin::users-permissions.permission': PluginUsersPermissionsPermission;
      'plugin::users-permissions.role': PluginUsersPermissionsRole;
      'plugin::users-permissions.user': PluginUsersPermissionsUser;
    }
  }
}
