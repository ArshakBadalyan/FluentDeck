const s3MediaOrigin = ({ env }) => {
  const bucket = env('AWS_BUCKET');
  const region = env('AWS_REGION');
  if (!bucket || !region) {
    return 'https://math-app-bucket.s3.eu-west-3.amazonaws.com';
  }
  return `https://${bucket}.s3.${region}.amazonaws.com`;
};

module.exports = ({ env }) => [
  "strapi::errors",
  {
    name: 'strapi::cors',
    config: {
      // Must be the string '*' (or explicit URLs). Arrays are matched with
      // includes(Origin)—so ['*'] never matches real browser origins → CORS failure.
      origin: '*',
      maxAge: 86400,
    },
  },
  "strapi::poweredBy",
  "strapi::logger",
  "strapi::query",
  {
    name: "strapi::body",
    config: {
      formLimit: "16mb", // modify here limit of the form body
      jsonLimit: "16mb", // modify here limit of the JSON body
      textLimit: "16mb", // modify here limit of the text body
      formidable: {
        maxFileSize: 100 * 1024 * 1024, // multipart data, modify here limit of uploaded file size
      },
    },
  },
  "strapi::session",
  "strapi::favicon",
  "strapi::public",
  {
    name: "strapi::security",
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          // keep your existing script-src
          "script-src": ["'self'", "blob:"],

          // ✅ allow images from S3 (and common admin image sources)
          "img-src": [
            "'self'",
            "data:",
            "blob:",
            s3MediaOrigin({ env }),
          ],

          // ✅ if Strapi treats some assets as media
          "media-src": [
            "'self'",
            "data:",
            "blob:",
            s3MediaOrigin({ env }),
          ],

          // optional but sometimes needed for admin previews / uploads
          "connect-src": ["'self'", "https:", "http:"],

          upgradeInsecureRequests: null,
        },
      },
    },
  }
];
