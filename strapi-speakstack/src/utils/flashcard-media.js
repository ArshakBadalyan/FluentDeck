'use strict';

const path = require('path');

async function uploadFlashcardMedia(strapi, file) {
  if (!file) throw new Error('No file provided');

  const uploadService = strapi.plugin('upload').service('upload');
  const uploaded = await uploadService.upload({
    data: {
      fileInfo: {
        name: file.originalFilename || file.name || 'flashcard-media',
        alternativeText: 'Flashcard media',
      },
    },
    files: file,
  });

  const row = Array.isArray(uploaded) ? uploaded[0] : uploaded;
  if (!row) throw new Error('Upload failed');

  const url = row.url ?? row.formats?.thumbnail?.url ?? '';
  return {
    id: row.id,
    url,
    name: row.name,
    mime: row.mime,
    size: row.size,
  };
}

function absoluteMediaUrl(strapi, url) {
  if (!url) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  const serverUrl = strapi.config.get('server.url') || 'http://localhost:1337';
  return `${serverUrl.replace(/\/$/, '')}${url.startsWith('/') ? url : `/${url}`}`;
}

module.exports = {
  uploadFlashcardMedia,
  absoluteMediaUrl,
};
