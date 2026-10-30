// The public address of the API, e.g. https://api.riovox.app (docs/production.md).
module.exports = ({ env }) => ({
  url: env('PUBLIC_URL'),
});
