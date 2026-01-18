const jwt = require('jsonwebtoken');
const { z } = require('zod');
const { env } = require('../config/env');
const {
  createDevice,
  getDeviceById,
  updateDeviceProfile,
} = require('../services/device.service');

const registerSchema = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    phone: z.string().trim().min(3).max(32).optional(),
    fcmToken: z.string().trim().min(1).optional(),
  })
  .strict();

const updateSchema = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    phone: z.string().trim().min(3).max(32).optional(),
    fcmToken: z.string().trim().min(1).optional(),
  })
  .strict();

const registerDevice = async (req, res) => {
  const parsed = registerSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
  }

  try {
    const device = await createDevice(parsed.data);
    const token = jwt.sign({ deviceId: device.id }, env.jwtSecret, {
      expiresIn: env.jwtTtl,
    });

    return res.status(201).json({
      token,
      expiresIn: env.jwtTtl,
      device,
    });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to register device' });
  }
};

const getProfile = async (req, res) => {
  const deviceId = req.device?.deviceId;
  if (!deviceId) {
    return res.status(401).json({ error: 'Missing device context' });
  }

  try {
    const device = await getDeviceById(deviceId);
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    return res.status(200).json({ device });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to fetch profile' });
  }
};

const updateProfile = async (req, res) => {
  const deviceId = req.device?.deviceId;
  if (!deviceId) {
    return res.status(401).json({ error: 'Missing device context' });
  }

  const parsed = updateSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parsed.error.flatten() });
  }

  try {
    const device = await updateDeviceProfile(deviceId, parsed.data);
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    return res.status(200).json({ device });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to update profile' });
  }
};

module.exports = {
  registerDevice,
  getProfile,
  updateProfile,
};
