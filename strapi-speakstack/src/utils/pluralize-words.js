const pluralizeWord = (count, noun, suffix = "s") => {
  return `${noun}${count !== 1 ? suffix : ""}`;
};

module.exports = {
  pluralizeWord
}
