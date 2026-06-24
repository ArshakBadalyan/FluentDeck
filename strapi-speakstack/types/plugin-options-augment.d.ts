/**
 * Strapi’s generated `types/generated/contentTypes.d.ts` declares `pluginOptions` for
 * admin keys (`content-manager`, `content-type-builder`), but `@strapi/types`
 * `PluginOptions` only lists `i18n` — TypeScript then errors on
 * `extends Schema.CollectionType`. This file augments the core type to match reality.
 *
 * IDE: Point TypeScript at `tsconfig.webstorm.json`, not `tsconfig.json`.
 * (`tsconfig.json` at the repo root makes Strapi think the project is TS and
 * crashes production with “undefined directory not found” unless a compile outDir exists.)
 */

import type {} from '@strapi/types';

declare module '@strapi/types/dist/types/core/schemas/index' {
  export interface PluginOptions {
    'content-manager'?: {
      visible?: boolean;
    };
    'content-type-builder'?: {
      visible?: boolean;
    };
  }
}
