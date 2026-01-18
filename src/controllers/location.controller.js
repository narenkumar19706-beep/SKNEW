const { z } = require('zod');
const {
  SosServiceError,
  recordLocation,
  getLatestLocation,
  getActiveSosForDevice,
} = require('../services/sos.service');

const updateSchema = z
  .object({
    sosId: z.string().uuid().optional(),
    latitude: z.number(),
    longitude: z.number(),
    accuracy: z.number().optional(),
    capturedAt: z.string().datetime().optional(),
  })
  .strict();

const updateLocation = async (req, res) => {
  const deviceId = req.device?.deviceId;
  if (!deviceId) {
    return res.status(401).json({ error: 'Missing device context' });
  }

  const parsed = updateSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
  }

  try {
    let sosId = parsed.data.sosId;
    if (!sosId) {
      const active = await getActiveSosForDevice(deviceId);
      if (!active) {
        return res.status(409).json({ error: 'No active SOS' });
      }
      sosId = active.id;
    }

    const capturedAt = parsed.data.capturedAt ? new Date(parsed.data.capturedAt) : undefined;
    const payload = await recordLocation({
      sosId,
      deviceId,
      latitude: parsed.data.latitude,
      longitude: parsed.data.longitude,
      accuracy: parsed.data.accuracy,
      capturedAt,
    });

    return res.status(200).json({ location: payload });
  } catch (error) {
    if (error instanceof SosServiceError) {
      if (error.code === 'SOS_NOT_FOUND') {
        return res.status(404).json({ error: error.message });
      }
      if (error.code === 'FORBIDDEN') {
        return res.status(403).json({ error: error.message });
      }
      if (error.code === 'SOS_NOT_ACTIVE') {
        return res.status(409).json({ error: error.message });
      }
    }
    return res.status(500).json({ error: 'Failed to update location' });
  }
};

const getLiveLocation = async (req, res) => {
  const { sosId } = req.params;
  if (!sosId) {
    return res.status(400).json({ error: 'Missing sosId' });
  }

  try {
    const latest = await getLatestLocation(sosId);
    return res.status(200).json({ location: latest });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to load live location' });
  }
};

module.exports = {
  updateLocation,
  getLiveLocation,
};
