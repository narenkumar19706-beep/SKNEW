const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/db');
const { broadcastLocation } = require('./socket.service');
const { getDeviceById } = require('./device.service');

const STATUS_ACTIVE = 'ACTIVE';
const STATUS_RESOLVED = 'RESOLVED';

class SosServiceError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const ensureSosTables = async () => {
  await query(`
    CREATE TABLE IF NOT EXISTS sos (
      id uuid PRIMARY KEY,
      device_id uuid NOT NULL,
      status text NOT NULL,
      district text,
      last_lat double precision,
      last_lng double precision,
      last_accuracy double precision,
      last_location_at timestamptz,
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now(),
      resolved_at timestamptz
    )
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS sos_updates (
      id uuid PRIMARY KEY,
      sos_id uuid NOT NULL,
      message text NOT NULL,
      created_at timestamptz NOT NULL DEFAULT now()
    )
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS sos_locations (
      id uuid PRIMARY KEY,
      sos_id uuid NOT NULL,
      latitude double precision NOT NULL,
      longitude double precision NOT NULL,
      accuracy double precision,
      captured_at timestamptz NOT NULL DEFAULT now()
    )
  `);
};

const mapSos = (row) => ({
  id: row.id,
  deviceId: row.device_id,
  status: row.status,
  district: row.district,
  lastLatitude: row.last_lat,
  lastLongitude: row.last_lng,
  lastAccuracy: row.last_accuracy,
  lastLocationAt: row.last_location_at,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  resolvedAt: row.resolved_at,
});

const getSosById = async (sosId) => {
  await ensureSosTables();
  const result = await query(`SELECT * FROM sos WHERE id = $1`, [sosId]);
  return result.rows[0] ? mapSos(result.rows[0]) : null;
};

const getActiveSosForDevice = async (deviceId) => {
  await ensureSosTables();
  const result = await query(
    `
      SELECT * FROM sos
      WHERE device_id = $1 AND status = $2
      ORDER BY created_at DESC
      LIMIT 1
    `,
    [deviceId, STATUS_ACTIVE]
  );
  return result.rows[0] ? mapSos(result.rows[0]) : null;
};

const createSos = async ({ deviceId, district, location, message }) => {
  await ensureSosTables();
  const device = await getDeviceById(deviceId);
  if (!device) {
    throw new SosServiceError('DEVICE_NOT_FOUND', 'Device not found');
  }
  const active = await getActiveSosForDevice(deviceId);
  if (active) {
    throw new SosServiceError('ACTIVE_SOS_EXISTS', 'Active SOS already exists');
  }

  const sosId = uuidv4();
  const capturedAt = location?.capturedAt ?? new Date();

  await query(
    `
      INSERT INTO sos (
        id,
        device_id,
        status,
        district,
        last_lat,
        last_lng,
        last_accuracy,
        last_location_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `,
    [
      sosId,
      deviceId,
      STATUS_ACTIVE,
      district,
      location?.latitude ?? null,
      location?.longitude ?? null,
      location?.accuracy ?? null,
      location ? capturedAt : null,
    ]
  );

  if (location) {
    await query(
      `
        INSERT INTO sos_locations (id, sos_id, latitude, longitude, accuracy, captured_at)
        VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [uuidv4(), sosId, location.latitude, location.longitude, location.accuracy ?? null, capturedAt]
    );
  }

  if (message) {
    await query(
      `
        INSERT INTO sos_updates (id, sos_id, message)
        VALUES ($1, $2, $3)
      `,
      [uuidv4(), sosId, message]
    );
  }

  return getSosById(sosId);
};

const addSosUpdate = async ({ sosId, deviceId, message }) => {
  await ensureSosTables();
  const sos = await getSosById(sosId);
  if (!sos) {
    throw new SosServiceError('SOS_NOT_FOUND', 'SOS not found');
  }
  if (sos.deviceId !== deviceId) {
    throw new SosServiceError('FORBIDDEN', 'SOS does not belong to device');
  }
  if (sos.status !== STATUS_ACTIVE) {
    throw new SosServiceError('SOS_NOT_ACTIVE', 'SOS is not active');
  }

  await query(
    `
      INSERT INTO sos_updates (id, sos_id, message)
      VALUES ($1, $2, $3)
    `,
    [uuidv4(), sosId, message]
  );

  await query(`UPDATE sos SET updated_at = now() WHERE id = $1`, [sosId]);
};

const resolveSos = async ({ sosId, deviceId }) => {
  await ensureSosTables();
  const result = await query(
    `
      UPDATE sos
      SET status = $3, resolved_at = now(), updated_at = now()
      WHERE id = $1 AND device_id = $2 AND status = $4
      RETURNING *
    `,
    [sosId, deviceId, STATUS_RESOLVED, STATUS_ACTIVE]
  );

  if (result.rows[0]) {
    return mapSos(result.rows[0]);
  }

  const existing = await getSosById(sosId);
  if (!existing) {
    throw new SosServiceError('SOS_NOT_FOUND', 'SOS not found');
  }
  if (existing.deviceId !== deviceId) {
    throw new SosServiceError('FORBIDDEN', 'SOS does not belong to device');
  }
  throw new SosServiceError('SOS_NOT_ACTIVE', 'SOS is not active');
};

const recordLocation = async ({ sosId, deviceId, latitude, longitude, accuracy, capturedAt }) => {
  await ensureSosTables();
  const sos = await getSosById(sosId);
  if (!sos) {
    throw new SosServiceError('SOS_NOT_FOUND', 'SOS not found');
  }
  if (sos.deviceId !== deviceId) {
    throw new SosServiceError('FORBIDDEN', 'SOS does not belong to device');
  }
  if (sos.status !== STATUS_ACTIVE) {
    throw new SosServiceError('SOS_NOT_ACTIVE', 'SOS is not active');
  }

  const recordedAt = capturedAt ?? new Date();
  await query(
    `
      INSERT INTO sos_locations (id, sos_id, latitude, longitude, accuracy, captured_at)
      VALUES ($1, $2, $3, $4, $5, $6)
    `,
    [uuidv4(), sosId, latitude, longitude, accuracy ?? null, recordedAt]
  );

  await query(
    `
      UPDATE sos
      SET
        last_lat = $2,
        last_lng = $3,
        last_accuracy = $4,
        last_location_at = $5,
        updated_at = now()
      WHERE id = $1
    `,
    [sosId, latitude, longitude, accuracy ?? null, recordedAt]
  );

  const payload = {
    latitude,
    longitude,
    accuracy: accuracy ?? null,
    capturedAt: recordedAt,
  };
  broadcastLocation(sosId, payload);
  return payload;
};

const getLatestLocation = async (sosId) => {
  await ensureSosTables();
  const result = await query(
    `
      SELECT latitude, longitude, accuracy, captured_at
      FROM sos_locations
      WHERE sos_id = $1
      ORDER BY captured_at DESC
      LIMIT 1
    `,
    [sosId]
  );

  if (!result.rows[0]) {
    return null;
  }

  return {
    latitude: result.rows[0].latitude,
    longitude: result.rows[0].longitude,
    accuracy: result.rows[0].accuracy,
    capturedAt: result.rows[0].captured_at,
  };
};

module.exports = {
  SosServiceError,
  STATUS_ACTIVE,
  STATUS_RESOLVED,
  createSos,
  getActiveSosForDevice,
  addSosUpdate,
  resolveSos,
  recordLocation,
  getLatestLocation,
  getSosById,
  ensureSosTables,
};
