const resolveDistrict = async ({ latitude, longitude }) => {
  if (process.env.DEFAULT_DISTRICT) {
    return process.env.DEFAULT_DISTRICT;
  }

  if (typeof latitude !== 'number' || typeof longitude !== 'number') {
    return 'unknown';
  }

  const latBucket = latitude.toFixed(2);
  const lngBucket = longitude.toFixed(2);
  return `district-${latBucket}-${lngBucket}`;
};

module.exports = { resolveDistrict };
