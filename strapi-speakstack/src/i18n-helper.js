const { I18n } = require("i18n");
const { join } = require("path");
const i18n = new I18n({
  locales: ["de", "en"],
  defaultLocale: process.env.I18N_DEFAULT_LOCALE || "de",
  directory: join(__dirname, "locales"),
  objectNotation: true,
});
i18n.setLocale(process.env.I18N_DEFAULT_LOCALE || "de")
module.exports = i18n;
