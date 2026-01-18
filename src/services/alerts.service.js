const { query } = require('../config/db');
const { ensureSosTables, STATUS_ACTIVE } = require('./sos.service');
const { ensureDevicesTable } = require('./device.service');
const { haversineDistanceKm } = require('../utils/distance');

const getDistrictAlerts = async ({ district, latitude, longitude }) => {
  await ensureSosTables();
  await ensureDevicesTable();
  const result = await query(
    `
      SELECT s.*, d.name AS device_name, d.phone AS device_phone
      FROM sos s
      JOIN devices d ON d.id = s.device_id
      WHERE s.status = $1 AND s.district = $2
      ORDER BY s.created_at DESC
    `,
    [STATUS_ACTIVE, district]
  );

  return result.rows.map((row) => ({
    sosId: row.id,
    deviceId: row.device_id,
    district: row.district,
    status: row.status,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    lastLatitude: row.last_lat,
    lastLongitude: row.last_lng,
    lastLocationAt: row.last_location_at,
    distanceKm: haversineDistanceKm(latitude, longitude, row.last_lat, row.last_lng),
    reporter: {
      name: row.device_name,
      phone: row.device_phone,
    },
  }));
};

module.exports = { getDistrictAlerts };
