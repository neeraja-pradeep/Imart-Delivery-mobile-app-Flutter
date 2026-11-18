/**
 * Stateful local mock of the iMart delivery-partner API.
 *
 * Contract: docs/delivery_partner_api.md and
 * docs/imart_delivery_partner_api.postman_collection.json. Covers only what
 * the partner app calls; the rules (session cookie + CSRF, OTP limits, one
 * status step per call, exact COD cash, required fail reasons, availability
 * rules) follow the doc so the app meets the same errors it would in prod.
 *
 * Run:   postman mock run postman/mocks/delivery-partner-api --port 8010
 * App:   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010
 * Login: phone 9876500001, OTP 123456 (mock only).
 *
 * Trips (9.x, 4.13, 2.6) and rider pay (10.2) follow the 2026-11-14 doc; pay
 * uses one fixed rate card (MOCK_RATES) and straight-line legs, as the
 * server does.
 *
 * Mock-only helpers (not part of the real API):
 *   POST /__mock/reset   reseed partner + 3 assigned deliveries
 *   POST /__mock/assign  assign 2 more deliveries (joins the open trip)
 *   GET  /__mock/last-point  ping count, last location body, trips
 */
const http = require('http');
const crypto = require('crypto');

const PORT = process.env.PORT || 8010;
const PAGE_SIZE = 25;
const OTP = '123456';
const OTP_RESEND_SECONDS = 30;
const OTP_MAX_ATTEMPTS = 5;
const PARTNER_PHONE = '+919876500001';
const CDN_HOST = 'imart-grocery.b-cdn.net';
const AVG_SPEED_KMPH = 20;
const MOCK_RATES = { per_delivery: 25, per_km: 6, free_km: 2, per_cod_delivery: 10, per_failed_attempt: 0, per_trip: 20, per_extra_stop: 10 };

const FAIL_REASONS = [
  { code: 'customer_unavailable', label: 'Customer unavailable', requires_notes: false },
  { code: 'wrong_address', label: 'Wrong address', requires_notes: false },
  { code: 'customer_refused', label: 'Customer refused', requires_notes: false },
  { code: 'unable_to_contact', label: 'Unable to contact customer', requires_notes: false },
  { code: 'other', label: 'Other', requires_notes: true },
];

const NEXT = {
  assigned: ['at_pickup', 'pending'],
  at_pickup: ['picked_up', 'pending'],
  picked_up: ['out_for_delivery'],
  out_for_delivery: ['delivered', 'failed'],
};
const ACTIVE = ['assigned', 'at_pickup', 'picked_up', 'out_for_delivery'];
const LOCATION_OK = ['at_pickup', 'picked_up', 'out_for_delivery'];
const UI_STAGE = {
  pending: 'accepted', assigned: 'accepted', at_pickup: 'pickup', picked_up: 'pickup',
  out_for_delivery: 'on_the_way', delivered: 'completed', failed: 'completed',
};

let db;

function nowIst() {
  const d = new Date(Date.now() + 5.5 * 3600 * 1000);
  return d.toISOString().replace('Z', '+05:30');
}
const nowUtc = () => new Date().toISOString().replace('Z', '+00:00');
const money = (n) => Number(n).toFixed(2);

function seed() {
  db = {
    nextDeliveryId: 16,
    nextOrderId: 50,
    nextAttemptId: 30,
    nextTripId: 9,
    trips: [],
    earnings: [],
    sessions: {},
    otp: { sentAt: 0, attempts: 0 },
    pings: 0,
    user: {
      id: 58, username: 'ravi.k', email: 'ravi.k@example.com', first_name: 'Ravi',
      last_name: 'Kumar', phone_number: PARTNER_PHONE, role: 'delivery',
      profile_photo: null, created_at: nowIst(),
    },
    profile: {
      id: 22, user: 58, username: 'ravi.k', email: 'ravi.k@example.com',
      vehicle_type: 'bike', vehicle_number: 'KL07AB1234', latitude: null, longitude: null,
      availability_status: 'online', warehouse: 14, created_at: nowIst(), updated_at: nowIst(),
    },
    warehouse: { id: 14, name: 'Kochi Central', address: '12 MG Road, Kochi, 682001', latitude: 9.9312, longitude: 76.2673 },
    deliveries: [],
    attempts: [],
  };
  assignBatch([
    { first: 'Anita', last: 'M', phone: '9000000001', street: '12 MG Road', landmark: 'Near metro', locality: 'Ernakulam South', city: 'Kochi', pin: '682011', lat: 9.9667, lng: 76.2833, mode: 'cod', total: 500, km: 4.7,
      items: [['Tomato', '1 kg', 2], ['Toned Milk', '500 ml', 2], ['Brown Bread', '400 g', 1]] },
    { first: 'Joseph', last: 'P', phone: '9000000002', street: '44 Panampilly Nagar', landmark: '', locality: 'Panampilly Nagar', city: 'Kochi', pin: '682036', lat: 9.9583, lng: 76.2958, mode: 'prepaid', total: 120, km: 3.1,
      items: [['Eggs', '12 pcs', 1], ['Onion', '1 kg', 1]] },
    { first: 'Meera', last: 'S', phone: '9000000003', street: '7 Kadavanthra Road', landmark: 'Opp. stadium', locality: 'Kadavanthra', city: 'Kochi', pin: '682020', lat: 9.9665, lng: 76.2999, mode: 'cod', total: 845.5, km: 6.2,
      items: [['Basmati Rice', '5 kg', 1], ['Sunflower Oil', '1 L', 2], ['Paneer', '200 g', 1], ['Curd', '400 g', 1, false]] },
  ]);
}

function openTrip() {
  let trip = db.trips.find((t) => t.status === 'open');
  if (!trip) {
    trip = { id: db.nextTripId++, delivery_partner: db.user.id, status: 'open', started_at: nowIst(), departed_at: null, ended_at: null, order: [] };
    db.trips.unshift(trip);
  }
  return trip;
}

function assignBatch(customers) {
  const trip = openTrip();
  for (const c of customers) {
    const orderId = db.nextOrderId++;
    const items = c.items.map((it, i) => ({
      id: orderId * 10 + i, product_name: it[0], variant_name: it[1], sku: `SKU-${orderId}-${i}`,
      quantity: it[2], fulfilled_quantity: it[3] === false ? 0 : it[2], is_available: it[3] !== false,
    }));
    const address = {
      id: orderId + 100, first_name: c.first, last_name: c.last, street_address1: c.street,
      street_address2: null, landmark: c.landmark, city: c.city, state: 'KL', postal_code: c.pin,
      country: 'IN', latitude: String(c.lat), longitude: String(c.lng), address_type: 'home',
      selected: false, created_at: nowIst(), updated_at: nowIst(), locality: c.locality || c.landmark || null,
    };
    db.deliveries.push({
      id: db.nextDeliveryId++,
      order: orderId,
      order_details: {
        id: orderId,
        user: { id: orderId + 1000, first_name: c.first, last_name: c.last, phone_number: c.phone },
        shipping_address: address, billing_address: address, latitude: null, longitude: null,
        status: 'packed', total: money(c.total), payment_mode: c.mode,
        amount_to_collect: c.mode === 'cod' ? money(c.total) : '0.00',
        created_at: nowIst(), updated_at: nowIst(),
      },
      items,
      delivery_partner: db.user.id,
      status: 'assigned',
      status_changed_at: nowUtc(),
      delivery_fee: '0.00',
      assigned_at: nowIst(), picked_up_at: null, delivered_at: null,
      proof_of_delivery: null, notes: null,
      pickup_points: [db.warehouse],
      trip: { distance_km: c.km, eta_minutes: Math.round((c.km / AVG_SPEED_KMPH) * 60), method: 'straight_line' },
      trip_id: trip.id,
      fail_reason: '', fail_reason_display: '',
      cash_collected: null, cash_collected_at: null, cash_deposited_at: null, cash_deposit_reference: '',
      created_at: nowIst(), updated_at: nowIst(),
    });
    trip.order.push(db.nextDeliveryId - 1);
  }
  db.profile.availability_status = 'on_delivery';
}

// ------------------------------------------------------------------ trips

function km(aLat, aLng, bLat, bLng) {
  const r = (x) => (x * Math.PI) / 180;
  const h = Math.sin(r(bLat - aLat) / 2) ** 2 + Math.cos(r(aLat)) * Math.cos(r(bLat)) * Math.sin(r(bLng - aLng) / 2) ** 2;
  return Math.round(2 * 6371 * Math.asin(Math.sqrt(h)) * 100) / 100;
}

const tripOf = (d) => db.trips.find((t) => t.id === d.trip_id);
const tripDeliveries = (trip) => trip.order.map((id) => db.deliveries.find((d) => d.id === id)).filter(Boolean);
const stopNumber = (d) => { const t = tripOf(d); return t ? t.order.indexOf(d.id) + 1 : null; };
function stopsAhead(d) {
  const t = tripOf(d);
  if (!t || !ACTIVE.includes(d.status)) return null;
  const all = tripDeliveries(t);
  return all.slice(0, all.indexOf(d)).filter((x) => ACTIVE.includes(x.status)).length;
}

function earn(kind, amount, d, note) {
  if (!amount) return 0;
  db.earnings.unshift({ id: db.earnings.length + 1, delivery_partner: db.user.id, kind, amount: money(amount), order_id: d ? d.order : null, delivery_id: d ? d.id : null, trip_id: d ? d.trip_id : null, earned_at: nowIst(), note });
  return amount;
}

/** Straight-line leg from the previous finished stop (or the warehouse). */
function legKm(d) {
  const t = tripOf(d);
  const done = t ? tripDeliveries(t).filter((x) => x !== d && x.ended_seq) : [];
  done.sort((a, b) => b.ended_seq - a.ended_seq);
  const from = done.length ? done[0].order_details.shipping_address : { latitude: db.warehouse.latitude, longitude: db.warehouse.longitude };
  const to = d.order_details.shipping_address;
  return km(Number(from.latitude), Number(from.longitude), Number(to.latitude), Number(to.longitude));
}

function finishStop(d, outcome) {
  const leg = legKm(d);
  d.ended_seq = (db.endSeq = (db.endSeq || 0) + 1);
  let earned = 0;
  if (outcome === 'delivered') {
    earned += earn('delivery', MOCK_RATES.per_delivery, d, 'Delivered');
    const paidKm = Math.max(0, leg - MOCK_RATES.free_km);
    earned += earn('distance', Math.round(paidKm * MOCK_RATES.per_km * 100) / 100, d, `${paidKm.toFixed(2)} km × ₹${money(MOCK_RATES.per_km)}`);
    if (d.order_details.payment_mode === 'cod') earned += earn('cod_handling', MOCK_RATES.per_cod_delivery, d, 'COD');
  } else {
    earned += earn('failed_attempt', MOCK_RATES.per_failed_attempt, d, 'Failed attempt');
  }
  d.leg_km = leg;
  d.earned = money(earned);
  logAttempt(d, outcome);
  const t = tripOf(d);
  if (t && !tripDeliveries(t).some((x) => ACTIVE.includes(x.status))) {
    t.status = 'completed';
    t.ended_at = nowIst();
    const delivered = tripDeliveries(t).filter((x) => x.status === 'delivered').length;
    if (delivered) {
      earn('trip', MOCK_RATES.per_trip, null, `Trip #${t.id}`);
      earn('extra_stop', MOCK_RATES.per_extra_stop * (delivered - 1), null, `Trip #${t.id}`);
    }
  }
}

function tripView(t) {
  const all = tripDeliveries(t);
  const cod = (x) => x.order_details.payment_mode === 'cod';
  return {
    id: t.id, delivery_partner: t.delivery_partner, status: t.status,
    started_at: t.started_at, departed_at: t.departed_at, ended_at: t.ended_at,
    counts: { total: all.length, active: all.filter((x) => ACTIVE.includes(x.status)).length, delivered: all.filter((x) => x.status === 'delivered').length, failed: all.filter((x) => x.status === 'failed').length },
    cash_to_collect: money(all.filter((x) => cod(x) && ACTIVE.includes(x.status)).reduce((n, x) => n + Number(x.order_details.amount_to_collect), 0)),
    cash_collected: money(all.reduce((n, x) => n + Number(x.cash_collected || 0), 0)),
    total_km: Math.round(all.reduce((n, x) => n + (x.leg_km || 0), 0) * 100) / 100,
    earned: money(db.earnings.filter((e) => e.trip_id === t.id || (e.note || '').endsWith(`#${t.id}`)).reduce((n, e) => n + Number(e.amount), 0)),
    stops: all.map((x) => {
      const a = x.order_details.shipping_address;
      return {
        delivery_id: x.id, order_id: x.order, stop_number: stopNumber(x), status: x.status, reassigned: false,
        customer_name: `${a.first_name} ${a.last_name}`, customer_phone: `+91${x.order_details.user.phone_number}`,
        locality: a.locality, latitude: Number(a.latitude), longitude: Number(a.longitude),
        payment_mode: x.order_details.payment_mode, amount_to_collect: x.order_details.amount_to_collect,
        cash_collected: x.cash_collected, fail_reason: x.fail_reason || null,
      };
    }),
  };
}

function view(d) {
  const { user } = db;
  return {
    ...d,
    ui_stage: UI_STAGE[d.status],
    stop_number: stopNumber(d),
    stops_ahead: stopsAhead(d),
    item_count: d.items.reduce((n, it) => n + it.fulfilled_quantity, 0),
    delivery_partner_details: d.delivery_partner ? {
      id: user.id, username: user.username, first_name: user.first_name, last_name: user.last_name,
      phone_number: user.phone_number, role: 'delivery', created_at: user.created_at,
    } : null,
    delivery_partner_profile: d.delivery_partner ? (({ email, ...p }) => p)(db.profile) : null,
  };
}

// ---------------------------------------------------------------- helpers

function send(res, status, body, headers = {}) {
  res.writeHead(status, { 'Content-Type': 'application/json', ...headers });
  res.end(body === undefined ? '' : JSON.stringify(body));
}

function cookies(req) {
  const out = {};
  for (const part of (req.headers.cookie || '').split(';')) {
    const i = part.indexOf('=');
    if (i > 0) out[part.slice(0, i).trim()] = part.slice(i + 1).trim();
  }
  return out;
}

function readBody(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (c) => { raw += c; });
    req.on('end', () => {
      try { resolve(raw ? JSON.parse(raw) : {}); } catch (_) { resolve(null); }
    });
  });
}

function page(rows, url) {
  const n = Number(url.searchParams.get('page') || 1);
  const start = (n - 1) * PAGE_SIZE;
  if (n < 1 || (start >= rows.length && rows.length > 0)) return null;
  const base = `http://${url.host}${url.pathname}`;
  return {
    count: rows.length,
    next: start + PAGE_SIZE < rows.length ? `${base}?page=${n + 1}` : null,
    previous: n > 1 ? `${base}?page=${n - 1}` : null,
    results: rows.slice(start, start + PAGE_SIZE),
  };
}

function normalisePhone(raw) {
  const digits = String(raw || '').replace(/\D/g, '');
  const ten = digits.length > 10 ? digits.slice(-10) : digits;
  return /^[6-9]\d{9}$/.test(ten) ? `+91${ten}` : null;
}

function hasActiveJob() {
  return db.deliveries.some((d) => d.delivery_partner === db.user.id && ACTIVE.includes(d.status));
}

function freePartnerIfIdle() {
  if (!hasActiveJob()) db.profile.availability_status = 'online';
}

function logAttempt(d, outcome) {
  const a = d.order_details.shipping_address;
  db.attempts.unshift({
    attempt_id: db.nextAttemptId++, delivery_id: d.id, order_id: d.order, outcome,
    fail_reason: outcome === 'failed' ? d.fail_reason : null,
    fail_reason_display: outcome === 'failed' ? d.fail_reason_display : null,
    notes: d.notes || '', payment_mode: d.order_details.payment_mode,
    order_total: d.order_details.total, cash_collected: d.cash_collected,
    distance_km: d.trip.distance_km, leg_km: d.leg_km, earned: d.earned, trip_id: d.trip_id,
    customer_name: `${a.first_name} ${a.last_name}`, drop_locality: `${a.city}, ${a.postal_code}`,
    assigned_at: d.assigned_at, ended_at: nowUtc(),
  });
}

// ------------------------------------------------------------- handlers

function patchDelivery(d, body, res) {
  const allowed = ['status', 'notes', 'proof_of_delivery', 'fail_reason', 'cash_collected'];
  for (const key of Object.keys(body)) {
    if (key === 'order') return send(res, 400, { order: ['The order of an existing delivery cannot be changed.'] });
    if (!allowed.includes(key)) {
      return send(res, 400, { [key]: ['Delivery partners can only update status, notes and proof_of_delivery.'] });
    }
  }
  const order = d.order_details;
  const to = body.status;
  if (to !== undefined && to !== d.status) {
    if (!(NEXT[d.status] || []).includes(to)) {
      return send(res, 400, { status: `Cannot transition from '${d.status}' to '${to}'` });
    }
    if (to === 'out_for_delivery' && order.status !== 'packed') {
      return send(res, 400, { status: `Cannot transition order from '${order.status}' to 'out_for_delivery'.` });
    }
    if (to === 'delivered') {
      const due = order.amount_to_collect;
      if (order.payment_mode === 'cod') {
        if (body.cash_collected === undefined || body.cash_collected === null) {
          return send(res, 400, { cash_collected: [`This is a cash-on-delivery order. Collect ₹${due} and send cash_collected to complete it.`] });
        }
        if (money(body.cash_collected) !== due) {
          return send(res, 400, { cash_collected: [`Cash collected (₹${money(body.cash_collected)}) must equal the amount due (₹${due}).`] });
        }
      } else if (body.cash_collected !== undefined && body.cash_collected !== null) {
        return send(res, 400, { cash_collected: ['This order is prepaid; there is no cash to collect.'] });
      }
    }
    if (to === 'failed') {
      const reason = FAIL_REASONS.find((r) => r.code === body.fail_reason);
      if (!body.fail_reason) {
        return send(res, 400, { fail_reason: [`Say why the delivery failed. One of: ${FAIL_REASONS.map((r) => r.code).join(', ')}.`] });
      }
      if (!reason) return send(res, 400, { fail_reason: [`"${body.fail_reason}" is not a valid choice.`] });
      if (reason.requires_notes && !body.notes) {
        return send(res, 400, { notes: ["Describe what happened when the fail reason is 'other'."] });
      }
    }
  }
  if (body.proof_of_delivery && !String(body.proof_of_delivery).includes(CDN_HOST)) {
    return send(res, 400, { proof_of_delivery: ['Proof of delivery must be a URL hosted on the configured CDN.'] });
  }

  if (body.notes !== undefined) d.notes = body.notes;
  if (body.proof_of_delivery !== undefined) d.proof_of_delivery = body.proof_of_delivery;
  if (to !== undefined && to !== d.status) {
    d.status = to;
    d.status_changed_at = nowUtc();
    if (to === 'picked_up') {
      d.picked_up_at = nowIst();
      const t = tripOf(d);
      if (t && !t.departed_at) t.departed_at = nowIst();
    }
    if (to === 'out_for_delivery') order.status = 'out_for_delivery';
    if (to === 'pending') {
      d.notes = [d.notes, `Rejected by ${db.user.username}`].filter(Boolean).join('\n');
      d.delivery_partner = null;
      const t = tripOf(d);
      if (t) t.order = t.order.filter((id) => id !== d.id);
      d.trip_id = null;
      freePartnerIfIdle();
    }
    if (to === 'delivered') {
      d.delivered_at = nowIst();
      order.status = 'delivered';
      if (order.payment_mode === 'cod') {
        d.cash_collected = money(body.cash_collected);
        d.cash_collected_at = nowIst();
      }
      finishStop(d, 'delivered');
      freePartnerIfIdle();
    }
    if (to === 'failed') {
      const reason = FAIL_REASONS.find((r) => r.code === body.fail_reason);
      d.fail_reason = reason.code;
      d.fail_reason_display = reason.label;
      d.notes = [body.notes, `Failed by ${db.user.username}: ${reason.label}`].filter(Boolean).join('\n');
      order.status = order.payment_mode === 'cod' && reason.code === 'customer_refused' ? 'cancelled' : 'packed';
      finishStop(d, 'failed');
      freePartnerIfIdle();
    }
  }
  d.updated_at = nowIst();
  return send(res, 200, view(d));
}

function patchMe(body, res) {
  const p = db.profile;
  const next = { ...p };
  if (body.vehicle_type !== undefined) {
    const types = ['bike', 'scooter', 'electric_bike', 'electric_scooter', 'cycle'];
    if (!types.includes(body.vehicle_type)) {
      return send(res, 400, { vehicle_type: [`"${body.vehicle_type}" is not a valid choice.`] });
    }
    next.vehicle_type = body.vehicle_type;
  }
  if (body.vehicle_number !== undefined) next.vehicle_number = String(body.vehicle_number);
  if (body.availability_status !== undefined && body.availability_status !== p.availability_status) {
    const to = body.availability_status;
    if (to === 'on_delivery') {
      return send(res, 400, { availability_status: ["'on_delivery' is set automatically when an order is assigned to you."] });
    }
    if (!['online', 'offline'].includes(to)) {
      return send(res, 400, { availability_status: [`"${to}" is not a valid choice.`] });
    }
    if (hasActiveJob()) {
      return send(res, 400, { availability_status: ["You can't change availability while you have an active delivery."] });
    }
    if (to === 'online' && (!next.vehicle_type || !next.vehicle_number)) {
      return send(res, 400, { availability_status: ['Set your vehicle type and number before going online.'] });
    }
    next.availability_status = to;
  }
  next.updated_at = nowIst();
  db.profile = next;
  return send(res, 200, db.profile);
}

async function handle(req, res) {
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const path = url.pathname;
  const method = req.method;
  const body = ['POST', 'PATCH', 'PUT', 'DELETE'].includes(method) ? await readBody(req) : {};
  if (body === null) return send(res, 400, { detail: 'JSON parse error.' });

  // ---- mock-only helpers
  if (method === 'POST' && path === '/__mock/reset') { seed(); return send(res, 200, { reset: true }); }
  if (method === 'GET' && path === '/__mock/last-point') {
    return send(res, 200, { pings: db.pings, last: db.lastPoint || null, trips: db.trips.map((t) => ({ id: t.id, status: t.status, order: t.order })) });
  }
  if (method === 'POST' && path === '/__mock/assign') {
    assignBatch([
      { first: 'Fathima', last: 'K', phone: '9000000004', street: '3 Marine Drive', landmark: '', city: 'Kochi', pin: '682031', lat: 9.9774, lng: 76.2766, mode: 'prepaid', total: 260, km: 2.4, items: [['Apples', '1 kg', 1]] },
      { first: 'Arjun', last: 'V', phone: '9000000005', street: '18 Vyttila Hub Road', landmark: 'Near mobility hub', city: 'Kochi', pin: '682019', lat: 9.9675, lng: 76.3207, mode: 'cod', total: 199, km: 5.5, items: [['Atta', '5 kg', 1]] },
    ]);
    return send(res, 200, { assigned: 2 });
  }

  // ---- public / CSRF-exempt
  if (method === 'GET' && path === '/api/delivery/v1/serviceability/') {
    const pin = url.searchParams.get('pincode');
    if (!pin) return send(res, 400, { detail: 'pincode query param is required.' });
    return send(res, 200, { pincode: pin, serviceable: pin.startsWith('682'), locality: pin.startsWith('682') ? 'Ernakulam' : null, eta_minutes: pin.startsWith('682') ? 20 : null });
  }
  if (method === 'POST' && path === '/api/auth/v1/delivery/otp/send/') {
    const phone = normalisePhone(body.phone_number);
    if (!phone) return send(res, 400, { error: 'Enter a valid 10-digit mobile number.', code: 'invalid_phone' });
    if (phone !== PARTNER_PHONE) {
      return send(res, 403, { error: 'This number is not registered as a delivery partner. Please contact your admin.', code: 'not_a_partner' });
    }
    const waited = (Date.now() - db.otp.sentAt) / 1000;
    if (waited < OTP_RESEND_SECONDS) {
      return send(res, 429, { error: 'Please wait before requesting another OTP.', code: 'resend_too_soon', retry_after_seconds: Math.ceil(OTP_RESEND_SECONDS - waited) });
    }
    db.otp = { sentAt: Date.now(), attempts: 0 };
    return send(res, 200, { message: 'OTP sent successfully', phone_number: phone, resend_after_seconds: OTP_RESEND_SECONDS, expires_in_seconds: 600 });
  }
  if (method === 'POST' && path === '/api/auth/v1/delivery/otp/verify/') {
    const phone = normalisePhone(body.phone_number);
    if (!phone) return send(res, 400, { error: 'Enter a valid 10-digit mobile number.', code: 'invalid_phone' });
    if (!/^\d{4,6}$/.test(String(body.otp_code || ''))) {
      return send(res, 400, { error: 'Enter the OTP you received.', code: 'invalid_otp_format' });
    }
    if (phone !== PARTNER_PHONE) {
      return send(res, 403, { error: 'This number is not registered as a delivery partner. Please contact your admin.', code: 'not_a_partner' });
    }
    if (!db.otp.sentAt || Date.now() - db.otp.sentAt > 600000) {
      return send(res, 401, { error: 'This OTP has expired. Request a new one.', code: 'otp_expired' });
    }
    if (db.otp.attempts >= OTP_MAX_ATTEMPTS) {
      return send(res, 429, { error: 'Too many wrong attempts. Request a new OTP.', code: 'too_many_attempts' });
    }
    if (String(body.otp_code) !== OTP) {
      db.otp.attempts += 1;
      return send(res, 401, { error: 'Incorrect OTP.', code: 'invalid_otp', attempts_remaining: OTP_MAX_ATTEMPTS - db.otp.attempts });
    }
    db.otp = { sentAt: 0, attempts: 0 };
    const sid = crypto.randomBytes(16).toString('hex');
    const csrf = crypto.randomBytes(16).toString('hex');
    db.sessions[sid] = csrf;
    return send(res, 200, { message: 'Delivery partner login successful', user: db.user, profile: db.profile }, {
      'Set-Cookie': [`sessionid=${sid}; HttpOnly; Path=/; SameSite=Lax`, `csrftoken=${csrf}; Path=/; SameSite=Lax`],
    });
  }

  // ---- everything else needs a session (403, not 401, like DRF session auth)
  const jar = cookies(req);
  if (!jar.sessionid || !db.sessions[jar.sessionid]) {
    return send(res, 403, { detail: 'Authentication credentials were not provided.' });
  }
  if (method !== 'GET' && req.headers['x-csrftoken'] !== jar.csrftoken) {
    return send(res, 403, { detail: 'CSRF Failed: CSRF token missing.' });
  }

  if (method === 'POST' && path === '/api/auth/v1/logout/') {
    delete db.sessions[jar.sessionid];
    return send(res, 200, { message: 'Logout successful' });
  }
  if (path === '/api/auth/v1/profile/') {
    if (method === 'PATCH') {
      if (body.email !== undefined && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(body.email)) {
        return send(res, 400, { email: ['Enter a valid email address.'] });
      }
      for (const k of ['first_name', 'last_name', 'email']) if (body[k] !== undefined) db.user[k] = body[k];
      db.profile.email = db.user.email;
    }
    return send(res, 200, db.user);
  }
  if (path === '/api/delivery/v1/delivery-profiles/me/') {
    if (method === 'PATCH') return patchMe(body, res);
    return send(res, 200, db.profile);
  }

  const mine = db.deliveries.filter((d) => d.delivery_partner === db.user.id);
  if (method === 'POST' && path === '/api/delivery/v1/delivery-profiles/me/location/') {
    if (body.latitude === undefined || body.longitude === undefined) {
      return send(res, 400, { error: 'latitude and longitude are required' });
    }
    const lat = Number(body.latitude);
    const lng = Number(body.longitude);
    if (Number.isNaN(lat) || Number.isNaN(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180) {
      return send(res, 400, { error: 'latitude must be between -90 and 90 and longitude between -180 and 180' });
    }
    let at = Date.now();
    if (body.recorded_at !== undefined) {
      if (!/([+-]\d{2}:\d{2}|Z)$/.test(String(body.recorded_at)) || Number.isNaN(Date.parse(body.recorded_at))) {
        return send(res, 400, { error: 'recorded_at must be an ISO-8601 datetime with a UTC offset' });
      }
      at = Date.parse(body.recorded_at);
      if (at > Date.now() + 120000) return send(res, 400, { error: 'recorded_at is in the future' });
    }
    for (const [key, max] of [['accuracy_m', 100000], ['speed_mps', 100], ['heading', 360]]) {
      if (body[key] !== undefined && !(Number(body[key]) >= 0 && Number(body[key]) <= max)) {
        return send(res, 400, { error: `${key} must be between 0 and ${max}` });
      }
    }
    const updated = [];
    const stale = [];
    for (const d of mine.filter((x) => LOCATION_OK.includes(x.status))) {
      if (d.last_fix_at && at <= d.last_fix_at) { stale.push(d.id); continue; }
      d.last_fix_at = at;
      updated.push(d.id);
    }
    db.pings += 1;
    db.lastPoint = { ...body, received_at: nowUtc() };
    db.profile.latitude = lat.toFixed(6);
    db.profile.longitude = lng.toFixed(6);
    return send(res, 200, { deliveries_updated: updated, stale });
  }
  if (method === 'POST' && path === '/api/delivery/v1/deliveries/arrange/') {
    const ids = body.delivery_ids;
    if (!Array.isArray(ids) || !ids.length) return send(res, 400, { error: 'delivery_ids must be a non-empty list of delivery ids.' });
    if (new Set(ids).size !== ids.length) return send(res, 400, { error: 'delivery_ids contains duplicates.' });
    const trip = db.trips.find((t) => t.status === 'open');
    if (!trip) return send(res, 400, { error: 'You have no open trip.', code: 'no_open_trip' });
    const active = tripDeliveries(trip).filter((d) => ACTIVE.includes(d.status)).map((d) => d.id);
    if (ids.length !== active.length || !ids.every((id) => active.includes(id))) {
      return send(res, 400, { error: 'delivery_ids must list every active stop of your open trip exactly once.', active_delivery_ids: active });
    }
    const done = trip.order.filter((id) => !active.includes(id));
    trip.order = [...done, ...ids];
    return send(res, 200, tripView(trip));
  }
  if (method === 'GET' && path === '/api/delivery/v1/delivery-trips/current/') {
    const trip = db.trips.find((t) => t.status === 'open');
    return trip ? send(res, 200, tripView(trip)) : send(res, 404, { error: 'You have no open trip.', code: 'no_open_trip' });
  }
  if (method === 'GET' && path === '/api/delivery/v1/delivery-trips/') {
    const p = page(db.trips.map(tripView), url);
    return p ? send(res, 200, p) : send(res, 404, { detail: 'Invalid page.' });
  }
  const tm = path.match(/^\/api\/delivery\/v1\/delivery-trips\/(\d+)\/$/);
  if (method === 'GET' && tm) {
    const trip = db.trips.find((t) => t.id === Number(tm[1]));
    return trip ? send(res, 200, tripView(trip)) : send(res, 404, { detail: 'Not found.' });
  }
  if (method === 'GET' && path === '/api/payouts/v1/me/earnings/summary/') {
    const days = Number(url.searchParams.get('days') || 7);
    if (!Number.isInteger(days) || days < 1 || days > 90) {
      return send(res, 400, { error: 'days must be an integer between 1 and 90.' });
    }
    const istDate = (iso) => new Date(Date.parse(iso) + 5.5 * 3600 * 1000).toISOString().slice(0, 10);
    const today = istDate(new Date().toISOString());
    const byDay = [];
    for (let i = days - 1; i >= 0; i--) {
      const date = istDate(new Date(Date.now() - i * 86400000).toISOString());
      const att = db.attempts.filter((a) => istDate(a.ended_at) === date);
      byDay.push({
        date,
        earned: money(db.earnings.filter((e) => istDate(e.earned_at) === date).reduce((n, e) => n + Number(e.amount), 0)),
        delivered: att.filter((a) => a.outcome === 'delivered').length,
        failed: att.filter((a) => a.outcome === 'failed').length,
        distance_km: Math.round(att.reduce((n, a) => n + (a.leg_km || 0), 0) * 10) / 10,
      });
    }
    const total = money(db.earnings.reduce((n, e) => n + Number(e.amount), 0));
    return send(res, 200, {
      today: byDay[byDay.length - 1].earned,
      this_period: { start: today, end: today, earned: total },
      unpaid_total: total, last_paid: null, days, by_day: byDay,
    });
  }
  if (method === 'GET' && path === '/api/delivery/v1/deliveries/') {
    const status = url.searchParams.get('status');
    const rows = (status ? mine.filter((d) => d.status === status) : mine).map(view);
    const p = page(rows, url);
    return p ? send(res, 200, p) : send(res, 404, { detail: 'Invalid page.' });
  }
  if (method === 'GET' && path === '/api/delivery/v1/deliveries/fail-reasons/') {
    return send(res, 200, { results: FAIL_REASONS });
  }
  if (method === 'GET' && path === '/api/delivery/v1/deliveries/history/') {
    const days = Number(url.searchParams.get('days') || 7);
    if (!Number.isInteger(days) || days < 1 || days > 90) {
      return send(res, 400, { error: 'days must be an integer between 1 and 90.' });
    }
    const since = Date.now() - days * 86400000;
    const rows = db.attempts.filter((a) => Date.parse(a.ended_at) >= since);
    const cash = rows.reduce((n, a) => n + Number(a.cash_collected || 0), 0);
    const p = page(rows, url) || { count: 0, next: null, previous: null, results: [] };
    return send(res, 200, {
      days,
      summary: {
        total: rows.length, delivered: rows.filter((a) => a.outcome === 'delivered').length, failed: rows.filter((a) => a.outcome === 'failed').length, cash_collected: money(cash),
        distance_km: Math.round(rows.reduce((n, a) => n + (a.distance_km || 0), 0) * 10) / 10,
        earned: money(rows.reduce((n, a) => n + Number(a.earned || 0), 0)),
      },
      ...p,
    });
  }
  if (method === 'GET' && path === '/api/delivery/v1/deliveries/cash-summary/') {
    const held = mine.filter((d) => d.cash_collected && !d.cash_deposited_at);
    return send(res, 200, {
      partner_id: db.user.id,
      cash_in_hand: money(held.reduce((n, d) => n + Number(d.cash_collected), 0)),
      count: held.length,
      deliveries: held.map((d) => ({ delivery_id: d.id, order_id: d.order, amount: d.cash_collected, collected_at: d.cash_collected_at })),
    });
  }

  const m = path.match(/^\/api\/delivery\/v1\/deliveries\/(\d+)\/(update_location\/)?$/);
  if (m) {
    const d = mine.find((x) => x.id === Number(m[1]));
    if (!d) return send(res, 404, { detail: 'No Delivery matches the given query.' });
    if (m[2] && method === 'POST') {
      if (!LOCATION_OK.includes(d.status)) return send(res, 400, { error: 'Cannot update location for this delivery status' });
      if (body.latitude === undefined || body.longitude === undefined) {
        return send(res, 400, { error: 'latitude and longitude are required' });
      }
      const lat = Number(body.latitude);
      const lng = Number(body.longitude);
      if (Number.isNaN(lat) || Number.isNaN(lng)) return send(res, 400, { error: 'latitude and longitude must be valid numbers' });
      if (Math.abs(lat) > 90 || Math.abs(lng) > 180) {
        return send(res, 400, { error: 'latitude must be between -90 and 90 and longitude between -180 and 180' });
      }
      db.pings += 1;
      if (db.pings % 10 === 1) { db.profile.latitude = lat.toFixed(6); db.profile.longitude = lng.toFixed(6); }
      return send(res, 200, {
        message: 'Location updated successfully (cached in Redis)',
        location: { delivery_id: d.id, latitude: lat, longitude: lng, timestamp: nowUtc(), user_id: db.user.id, order_id: d.order, partner_name: db.user.username },
        storage: { cache: 'Redis (primary storage)', db_persistence: 'Every 10 updates', current_update: db.pings, next_db_persist: Math.ceil(db.pings / 10) * 10 },
      });
    }
    if (!m[2] && method === 'GET') return send(res, 200, view(d));
    if (!m[2] && method === 'PATCH') return patchDelivery(d, body, res);
  }

  return send(res, 404, { detail: 'Not found.' });
}

seed();
http.createServer((req, res) => {
  handle(req, res).catch((err) => send(res, 500, { detail: String(err && err.message) }));
}).listen(PORT);
