const { z } = require('zod');
const {
  SosServiceError,
  createSos,
  addSosUpdate,
  resolveSos,
  getSosById,
} = require('../services/sos.service');
const { resolveDistrict } = require('../services/district.service');
const { sendDistrictNotification } = require('../services/fcm.service');

const triggerSchema = z
  .object({
    latitude: z.number(),
    longitude: z.number(),
    accuracy: z.number().optional(),
    message: z.string().trim().min(1).max(280).optional(),
    capturedAt: z.string().datetime().optional(),
  })
  .strict();

const updateSchema = z
  .object({
    sosId: z.string().uuid(),
    message: z.string().trim().min(1).max(280),
  })
  .strict();

const resolveSchema = z
  .object({
    sosId: z.string().uuid(),
    message: z.string().trim().min(1).max(280).optional(),
  })
  .strict();

const triggerSos = async (req, res) => {
  const deviceId = req.device?.deviceId;
  if (!deviceId) {
    return res.status(401).json({ error: 'Missing device context' });
  }

  const parsed = triggerSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
  }

  const capturedAt = parsed.data.capturedAt ? new Date(parsed.data.capturedAt) : undefined;
  const district = await resolveDistrict({
    latitude: parsed.data.latitude,
    longitude: parsed.data.longitude,
  });

  try {
    const sos = await createSos({
      deviceId,
      district,
      message: parsed.data.message,
      location: {
        latitude: parsed.data.latitude,
        longitude: parsed.data.longitude,
        accuracy: parsed.data.accuracy,
        capturedAt,
      },
    });

    await sendDistrictNotification({
      district,
      eventType: 'SOS_CREATED',
      payload: {
        sosId: sos.id,
        deviceId,
        district,
      },
    });

    return res.status(201).json({ sos });
  } catch (error) {
    if (error instanceof SosServiceError) {
      if (error.code === 'ACTIVE_SOS_EXISTS') {
        return res.status(409).json({ error: error.message });
      }
      if (error.code === 'DEVICE_NOT_FOUND') {
        return res.status(404).json({ error: error.message });
      }
    }
    return res.status(500).json({ error: 'Failed to trigger SOS' });
  }
};

const addUpdate = async (req, res) => {
  const deviceId = req.device?.deviceId;
  if (!deviceId) {
    return res.status(401).json({ error: 'Missing device context' });
  }

  const parsed = updateSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
  }

  try {
    await addSosUpdate({
      sosId: parsed.data.sosId,
      deviceId,
      message: parsed.data.message,
    });

    const sos = await getSosById(parsed.data.sosId);
    if (sos) {
      await sendDistrictNotification({
        district: sos.district ?? 'unknown',
        eventType: 'SOS_UPDATED',
        payload: {
          sosId: sos.id,
          deviceId,
          district: sos.district ?? 'unknown',
        },
      });
    }

    return res.status(200).json({ status: 'ok' });
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
    return res.status(500).json({ error: 'Failed to update SOS' });
  }
};

const resolveActiveSos = async (req, res) => {
  const deviceId = req.device?.deviceId;
  if (!deviceId) {
    return res.status(401).json({ error: 'Missing device context' });
  }

  const parsed = resolveSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
  }

  try {
    if (parsed.data.message) {
      await addSosUpdate({
        sosId: parsed.data.sosId,
        deviceId,
        message: parsed.data.message,
      });
    }

    const sos = await resolveSos({
      sosId: parsed.data.sosId,
      deviceId,
    });

    await sendDistrictNotification({
      district: sos.district ?? 'unknown',
      eventType: 'SOS_RESOLVED',
      payload: {
        sosId: sos.id,
        deviceId,
        district: sos.district ?? 'unknown',
      },
    });

    return res.status(200).json({ sos });
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
    return res.status(500).json({ error: 'Failed to resolve SOS' });
  }
};

module.exports = {
  triggerSos,
  addUpdate,
  resolveActiveSos,
};
