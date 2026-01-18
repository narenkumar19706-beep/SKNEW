const { z } = require('zod');
const { resolveDistrict } = require('../services/district.service');
const { getDistrictAlerts } = require('../services/alerts.service');

const querySchema = z
  .object({
    latitude: z.coerce.number(),
    longitude: z.coerce.number(),
  })
  .strict();

const getDistrictAlertsController = async (req, res) => {
  const parsed = querySchema.safeParse(req.query ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid query', details: parsed.error.flatten() });
  }

  try {
    const district = await resolveDistrict({
      latitude: parsed.data.latitude,
      longitude: parsed.data.longitude,
    });

    const alerts = await getDistrictAlerts({
      district,
      latitude: parsed.data.latitude,
      longitude: parsed.data.longitude,
    });

    return res.status(200).json({ district, alerts });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to fetch alerts' });
  }
};

module.exports = {
  getDistrictAlerts: getDistrictAlertsController,
};
