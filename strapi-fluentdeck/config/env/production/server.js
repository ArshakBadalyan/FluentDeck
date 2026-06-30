// https://docs.strapi.io/developer-docs/latest/setup-deployment-guides/deployment/hosting-guides/heroku.html
module.exports = ({ env }) => ({
  url: env('MY_HEROKU_URL'),
});
