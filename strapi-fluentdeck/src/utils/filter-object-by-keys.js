const filterObjectByKeys = (excludedKeys, object) => {
  return Object.fromEntries(
    Object.entries(object).filter(([key, value]) => !excludedKeys.includes(key))
  );
};

module.exports = {
  filterObjectByKeys,
};
