module.exports = ({ env }) => ({
  email: {
    config: {
      provider: "nodemailer",
      providerOptions: {
        // Any SMTP provider (Resend, Brevo, Amazon SES, …); see docs/production.md.
        host: env("SMTP_HOST"),
        port: env.int("SMTP_PORT", 465),
        // true for port 465; false for 587 (STARTTLS).
        secure: env.bool("SMTP_SECURE", true),
        auth: {
          user: env("SMTP_USERNAME"),
          pass: env("SMTP_PASSWORD"),
        },
      },
      settings: {
        defaultFrom: env("EMAIL_FROM"),
        defaultReplyTo: env("EMAIL_REPLY_TO", env("EMAIL_FROM")),
      },
    },
  },
 upload: {
    config: {
      //provider: "local",
      provider: 'aws-s3',
      providerOptions: {
        s3Options: {
          credentials: {
            accessKeyId: env('AWS_ACCESS_KEY_ID'),
            secretAccessKey: env('AWS_SECRET_ACCESS_KEY'),
          },
          region: env('AWS_REGION'),
          params: {
            Bucket: env('AWS_BUCKET'),
          },
        },
      },
      actionOptions: {
        upload: {},
        uploadStream: {},
        delete: {},
      },    
      breakpoints: {
        thumbnail: 245,
        medium: 750 
      },
    },
  },
});
