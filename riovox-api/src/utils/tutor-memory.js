'use strict';

const MAX_MEMORY_FACTS = 25;

function normalizeFacts(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((item) => {
      if (typeof item === 'string') {
        const text = item.trim();
        return text ? { fact: text, category: 'general' } : null;
      }
      if (!item || typeof item !== 'object') return null;
      const fact = String(item.fact ?? item.text ?? '').trim();
      if (!fact) return null;
      const category = String(item.category ?? 'general').trim() || 'general';
      return { fact, category };
    })
    .filter(Boolean);
}

function formatMemoryBlock(facts) {
  const normalized = normalizeFacts(facts);
  if (!normalized.length) return '';

  const lines = normalized.map((item, index) => `${index + 1}. [${item.category}] ${item.fact}`);
  return `\nLearner memory (personal details from past sessions — reference naturally, do not list them back unless relevant):\n${lines.join('\n')}\n`;
}

function parseMemoryUpdate(text) {
  const match = text.match(
    /(?:^|\n)MEMORY_UPDATE_JSON:\s*(\{[\s\S]*?\})(?=\s*(?:\nCORRECTIONS_JSON:|\s*$))/i,
  );
  if (!match) return null;
  try {
    const parsed = JSON.parse(match[1]);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
}

function mergeMemoryFacts(existing, update) {
  const current = normalizeFacts(existing);
  if (!update || update.action === 'none') {
    return current;
  }

  const toAdd = normalizeFacts(update.add);
  const toRemove = Array.isArray(update.remove)
    ? update.remove.map((item) => String(item).trim().toLowerCase()).filter(Boolean)
    : [];

  let merged = current.filter(
    (item) => !toRemove.includes(item.fact.trim().toLowerCase()),
  );

  for (const item of toAdd) {
    const duplicate = merged.some(
      (existingItem) =>
        existingItem.fact.trim().toLowerCase() === item.fact.trim().toLowerCase(),
    );
    if (!duplicate) {
      merged.push(item);
    }
  }

  if (merged.length > MAX_MEMORY_FACTS) {
    merged = merged.slice(merged.length - MAX_MEMORY_FACTS);
  }

  return merged;
}

async function loadTutorMemory(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['tutor_memory'],
  });
  return normalizeFacts(user?.tutor_memory ?? user?.tutorMemory);
}

async function saveTutorMemory(strapi, userId, facts) {
  const normalized = normalizeFacts(facts);
  await strapi.db.query('plugin::users-permissions.user').update({
    where: { id: userId },
    data: { tutor_memory: normalized },
  });
  return normalized;
}

async function processMemoryUpdate(strapi, userId, memoryUpdate) {
  if (!memoryUpdate || memoryUpdate.action === 'none') {
    return { updated: false, facts: await loadTutorMemory(strapi, userId) };
  }

  const existing = await loadTutorMemory(strapi, userId);
  const merged = mergeMemoryFacts(existing, memoryUpdate);
  const changed = JSON.stringify(existing) !== JSON.stringify(merged);
  if (changed) {
    await saveTutorMemory(strapi, userId, merged);
  }
  return { updated: changed, facts: merged };
}

async function deleteMemoryFact(strapi, userId, factIndex) {
  const facts = await loadTutorMemory(strapi, userId);
  const index = Number(factIndex);
  if (!Number.isInteger(index) || index < 0 || index >= facts.length) {
    return { ok: false, facts };
  }
  facts.splice(index, 1);
  await saveTutorMemory(strapi, userId, facts);
  return { ok: true, facts };
}

module.exports = {
  MAX_MEMORY_FACTS,
  normalizeFacts,
  formatMemoryBlock,
  parseMemoryUpdate,
  mergeMemoryFacts,
  loadTutorMemory,
  saveTutorMemory,
  processMemoryUpdate,
  deleteMemoryFact,
};
