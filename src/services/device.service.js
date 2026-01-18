const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');

const ensureDevicesTable = async () => {
  await query(`
    CREATE TABLE IF NOT EXISTS devices (
      id uuid PRIMARY KEY,
      name text,
      phone text,
      address text,
      district text,
      fcm_token text,
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now()
    )
  `);
};

const mapDevice = (row) => ({
  id: row.id,
  name: row.name,
  phone: row.phone,
  address: row.address,
  district: row.district,
  fcmToken: row.fcm_token,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const createDevice = async ({ name, phone, fcmToken }) => {
  await ensureDevicesTable();
  const id = uuidv4();
  const result = await query(
    `
      INSERT INTO devices (id, name, phone, fcm_token)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `,
    [id, name || null, phone || null, fcmToken || null]
  );

  return mapDevice(result.rows[0]);
};

const getDeviceById = async (deviceId) => {
  await ensureDevicesTable();
  const result = await query(`SELECT * FROM devices WHERE id = $1`, [deviceId]);
  return result.rows[0] ? mapDevice(result.rows[0]) : null;
};

const updateDeviceProfile = async (deviceId, { name, phone, fcmToken }) => {
  await ensureDevicesTable();
  const result = await query(
    `
      UPDATE devices
      SET
        name = COALESCE($2, name),
        phone = COALESCE($3, phone),
        fcm_token = COALESCE($4, fcm_token),
        updated_at = now()
      WHERE id = $1
      RETURNING *
    `,
    [deviceId, name ?? null, phone ?? null, fcmToken ?? null]
  );

  return result.rows[0] ? mapDevice(result.rows[0]) : null;
};

module.exports = {
  createDevice,
  getDeviceById,
  updateDeviceProfile,
  ensureDevicesTable,
};
