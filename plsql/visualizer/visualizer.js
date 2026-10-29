/* =============================================================================
   Blood Bank Management System - PL/SQL Project Visualizer & Lab Studio
   Interactive PL/SQL Simulation Engine & DOM Controller
   ============================================================================= */

// Global State mirroring the Oracle / MySQL PL/SQL Database
const dbState = {
  bloodGroups: [
    { id: 'O-', type: 'O', rh: '-', antigen: 'None', antibody: 'Anti-A, Anti-B', uniDonor: true, uniRecip: false, desc: 'Universal Red Blood Cell Donor' },
    { id: 'O+', type: 'O', rh: '+', antigen: 'Rh(D)', antibody: 'Anti-A, Anti-B', uniDonor: false, uniRecip: false, desc: 'Most common blood group; Rh+ recipients' },
    { id: 'A-', type: 'A', rh: '-', antigen: 'A', antibody: 'Anti-B', uniDonor: false, uniRecip: false, desc: 'Can donate to A-, A+, AB-, AB+' },
    { id: 'A+', type: 'A', rh: '+', antigen: 'A, Rh(D)', antibody: 'Anti-B', uniDonor: false, uniRecip: false, desc: 'Can donate to A+ and AB+' },
    { id: 'B-', type: 'B', rh: '-', antigen: 'B', antibody: 'Anti-A', uniDonor: false, uniRecip: false, desc: 'Can donate to B-, B+, AB-, AB+' },
    { id: 'B+', type: 'B', rh: '+', antigen: 'B, Rh(D)', antibody: 'Anti-A', uniDonor: false, uniRecip: false, desc: 'Can donate to B+ and AB+' },
    { id: 'AB-', type: 'AB', rh: '-', antigen: 'A, B', antibody: 'None', uniDonor: false, uniRecip: false, desc: 'Can donate to AB- and AB+' },
    { id: 'AB+', type: 'AB', rh: '+', antigen: 'A, B, Rh', antibody: 'None', uniDonor: false, uniRecip: true, desc: 'Universal Red Blood Cell Recipient' }
  ],

  stock: {
    'O-':  { available: 12, reserved: 0, critical: 5, low: 10, ideal: 100 },
    'O+':  { available: 35, reserved: 2, critical: 8, low: 15, ideal: 100 },
    'A-':  { available: 8,  reserved: 0, critical: 4, low: 8,  ideal: 100 },
    'A+':  { available: 26, reserved: 1, critical: 6, low: 12, ideal: 100 },
    'B-':  { available: 6,  reserved: 0, critical: 4, low: 8,  ideal: 100 },
    'B+':  { available: 30, reserved: 0, critical: 6, low: 14, ideal: 100 },
    'AB-': { available: 4,  reserved: 0, critical: 3, low: 6,  ideal: 100 },
    'AB+': { available: 18, reserved: 0, critical: 4, low: 9,  ideal: 100 }
  },

  compatibility: {
    'O-':  ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
    'O+':  ['O+', 'A+', 'B+', 'AB+'],
    'A-':  ['A-', 'A+', 'AB-', 'AB+'],
    'A+':  ['A+', 'AB+'],
    'B-':  ['B-', 'B+', 'AB-', 'AB+'],
    'B+':  ['B+', 'AB+'],
    'AB-': ['AB-', 'AB+'],
    'AB+': ['AB+']
  },

  donors: [
    { id: 101, name: 'Aman Sharma', email: 'aman@example.com', phone: '9876500001', gender: 'M', dob: '1998-05-14', weight: 68.5, group: 'O+', city: 'Ludhiana', lastDonated: '2026-03-10', totalDonations: 3, status: 'ACTIVE' },
    { id: 102, name: 'Simran Kaur', email: 'simran@example.com', phone: '9876500002', gender: 'F', dob: '2001-08-20', weight: 56.0, group: 'B+', city: 'Ludhiana', lastDonated: '2026-01-12', totalDonations: 1, status: 'ACTIVE' },
    { id: 103, name: 'Rahul Verma', email: 'rahul@example.com', phone: '9876500003', gender: 'M', dob: '1995-11-05', weight: 74.0, group: 'A+', city: 'Chandigarh', lastDonated: '2026-09-15', totalDonations: 4, status: 'ACTIVE' },
    { id: 104, name: 'Neha Gupta', email: 'neha@example.com', phone: '9876500004', gender: 'F', dob: '1999-02-18', weight: 53.5, group: 'O-', city: 'Jalandhar', lastDonated: '2026-02-28', totalDonations: 2, status: 'ACTIVE' },
    { id: 105, name: 'Gurpreet Singh', email: 'gurpreet@example.com', phone: '9876500005', gender: 'M', dob: '1992-06-30', weight: 82.0, group: 'AB+', city: 'Amritsar', lastDonated: '2025-11-20', totalDonations: 5, status: 'ACTIVE' },
    { id: 106, name: 'Pooja Mehta', email: 'pooja@example.com', phone: '9876500006', gender: 'F', dob: '2003-04-12', weight: 58.0, group: 'A-', city: 'Ludhiana', lastDonated: null, totalDonations: 0, status: 'ACTIVE' }
  ],

  requests: [
    { id: 1001, patient: 'Harpreet Singh', hospital: 'Civil Hospital Ludhiana', phone: '9812300001', group: 'B+', units: 2, city: 'Ludhiana', urgency: 'URGENT', reason: 'Cardiac bypass surgery', status: 'PENDING', requestedAt: '2026-10-28 10:15' },
    { id: 1002, patient: 'Rajeshwari Devi', hospital: 'Dayanand Medical College', phone: '9812300002', group: 'O-', units: 1, city: 'Ludhiana', urgency: 'CRITICAL', reason: 'Emergency trauma hemorrhage', status: 'PENDING', requestedAt: '2026-10-28 11:30' },
    { id: 1003, patient: 'Deepak Chopra', hospital: 'Fortis Hospital Mohali', phone: '9812300003', group: 'A+', units: 3, city: 'Chandigarh', urgency: 'NORMAL', reason: 'Orthopedic replacement', status: 'PENDING', requestedAt: '2026-10-28 14:00' }
  ],

  issuances: [],

  auditLog: [
    { id: 1, table: 'DONORS', action: 'INSERT', recordId: '101', values: 'Name=Aman Sharma; Group=O+; City=Ludhiana', time: '10:00:15', user: 'SYSTEM' },
    { id: 2, table: 'BLOOD_STOCK', action: 'INITIALIZE', recordId: 'ALL', values: 'Seeded initial units across all 8 groups', time: '10:00:20', user: 'SYSTEM' },
    { id: 3, table: 'BLOOD_REQUESTS', action: 'INSERT', recordId: '1001', values: 'Patient=Harpreet Singh; Units=2; Urgency=URGENT', time: '10:15:30', user: 'SYSTEM' }
  ]
};

// PL/SQL Functions implemented in JS
function fn_calculate_age(dobString) {
  if (!dobString) return 0;
  const dob = new Date(dobString);
  const now = new Date();
  let age = now.getFullYear() - dob.getFullYear();
  const m = now.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

function fn_get_stock_status(group) {
  const s = dbState.stock[group];
  if (!s) return 'UNKNOWN';
  if (s.available <= s.critical) return 'CRITICAL';
  if (s.available <= s.low) return 'LOW';
  return 'SUFFICIENT';
}

function fn_get_compatible_stock(recipientGroup) {
  let total = 0;
  for (const [donorGroup, recipients] of Object.entries(dbState.compatibility)) {
    if (recipients.includes(recipientGroup)) {
      total += dbState.stock[donorGroup]?.available || 0;
    }
  }
  return total;
}

function fn_check_donor_eligibility(donorId) {
  const donor = dbState.donors.find(d => d.id === donorId);
  if (!donor) return 'INELIGIBLE: Donor ID does not exist';
  if (donor.status !== 'ACTIVE') return `INELIGIBLE: Status is ${donor.status}`;

  const age = fn_calculate_age(donor.dob);
  if (age < 18) return `INELIGIBLE: Underage (${age} yrs). Must be at least 18.`;
  if (age > 65) return `INELIGIBLE: Exceeds age limit (${age} yrs). Max 65.`;

  if (donor.weight < 45.0) return `INELIGIBLE: Weight (${donor.weight} kg) below 45 kg threshold.`;

  if (donor.lastDonated) {
    const lastDate = new Date(donor.lastDonated);
    const now = new Date();
    const diffDays = Math.floor((now - lastDate) / (1000 * 60 * 60 * 24));
    if (diffDays < 90) {
      const nextElig = new Date(lastDate);
      nextElig.setDate(nextElig.getDate() + 90);
      return `INELIGIBLE: Cooldown active (Donated ${diffDays} days ago). Next eligible on ${nextElig.toISOString().split('T')[0]}.`;
    }
  }

  return 'ELIGIBLE';
}

// Log message to terminal console
function logTerminal(text, type = 'info') {
  const term = document.getElementById('terminalOutput');
  if (!term) return;

  const line = document.createElement('div');
  line.className = `terminal-line line-${type}`;
  const timestamp = new Date().toLocaleTimeString();
  line.textContent = `[${timestamp}] ${text}`;
  term.appendChild(line);
  term.scrollTop = term.scrollHeight;
}

// Clear terminal
function clearTerminal() {
  const term = document.getElementById('terminalOutput');
  if (term) term.innerHTML = '';
  logTerminal('Terminal initialized. Ready for PL/SQL procedure execution.', 'dim');
}

// Render Top Metrics
function renderMetrics() {
  let totalUnits = 0;
  let criticalCount = 0;
  for (const [grp, data] of Object.entries(dbState.stock)) {
    totalUnits += data.available;
    if (data.available <= data.critical) criticalCount++;
  }

  const activeDonors = dbState.donors.filter(d => d.status === 'ACTIVE').length;
  const pendingRequests = dbState.requests.filter(r => r.status === 'PENDING').length;

  document.getElementById('metricTotalStock').textContent = totalUnits;
  document.getElementById('metricActiveDonors').textContent = activeDonors;
  document.getElementById('metricPendingRequests').textContent = pendingRequests;
  document.getElementById('metricCriticalGroups').textContent = criticalCount;
}

// Render Blood Stock Cards
function renderStockCards() {
  const container = document.getElementById('stockGrid');
  if (!container) return;

  container.innerHTML = '';

  for (const bg of dbState.bloodGroups) {
    const s = dbState.stock[bg.id];
    const status = fn_get_stock_status(bg.id);
    const compatPool = fn_get_compatible_stock(bg.id);
    const pct = Math.min(Math.round((s.available / s.ideal) * 100), 100);

    let gaugeClass = 'good';
    if (status === 'LOW') gaugeClass = 'warn';
    if (status === 'CRITICAL') gaugeClass = 'danger';

    const card = document.createElement('div');
    card.className = 'stock-card';
    card.innerHTML = `
      <div class="stock-card-top">
        <div class="group-badge">${bg.id}</div>
        <span class="stock-status-pill status-${status.toLowerCase()}">${status}</span>
      </div>
      <div class="stock-units-row">
        <span class="stock-units-big">${s.available}</span>
        <span class="stock-units-label">Units in Stock</span>
      </div>
      <div class="gauge-track">
        <div class="gauge-fill ${gaugeClass}" style="width: ${pct}%"></div>
      </div>
      <div class="stock-compat-info">
        <span>Capacity: <strong>${pct}%</strong></span>
        <span>Compatible Pool: <strong>${compatPool} units</strong></span>
      </div>
    `;
    container.appendChild(card);
  }
}

// Render Donors Table
function renderDonorsTable() {
  const tbody = document.getElementById('donorsTableBody');
  if (!tbody) return;

  tbody.innerHTML = '';

  dbState.donors.forEach(d => {
    const age = fn_calculate_age(d.dob);
    const elig = fn_check_donor_eligibility(d.id);
    const isEligible = elig === 'ELIGIBLE';

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>#${d.id}</strong></td>
      <td><strong>${d.name}</strong></td>
      <td><span class="badge-tag oracle">${d.group}</span></td>
      <td>${age} yrs / ${d.gender}</td>
      <td>${d.weight} kg</td>
      <td>${d.city}</td>
      <td>${d.phone}</td>
      <td>${d.lastDonated || '<span style="color:#64748b">Never</span>'}</td>
      <td>
        <span class="stock-status-pill ${isEligible ? 'status-sufficient' : 'status-low'}" title="${elig}">
          ${isEligible ? 'ELIGIBLE' : 'COOLDOWN / INELIGIBLE'}
        </span>
      </td>
    `;
    tbody.appendChild(tr);
  });

  // Populate donor select dropdowns in procedures
  const donorSelect = document.getElementById('donationDonorSelect');
  if (donorSelect) {
    donorSelect.innerHTML = '';
    dbState.donors.forEach(d => {
      const opt = document.createElement('option');
      opt.value = d.id;
      opt.textContent = `#${d.id} - ${d.name} (${d.group}) [Last: ${d.lastDonated || 'Never'}]`;
      donorSelect.appendChild(opt);
    });
  }
}

// Render Requests Table
function renderRequestsTable() {
  const tbody = document.getElementById('requestsTableBody');
  const reqSelect = document.getElementById('fulfillRequestSelect');
  if (!tbody) return;

  tbody.innerHTML = '';
  if (reqSelect) reqSelect.innerHTML = '';

  dbState.requests.forEach(r => {
    const s = dbState.stock[r.group];
    const canFulfill = s.available >= r.units;

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>#${r.id}</strong></td>
      <td><strong>${r.patient}</strong></td>
      <td>${r.hospital}</td>
      <td><span class="badge-tag oracle">${r.group}</span></td>
      <td><strong>${r.units}</strong></td>
      <td>
        <span class="badge-tag ${r.urgency === 'CRITICAL' ? 'oracle' : (r.urgency === 'URGENT' ? 'mysql' : '')}">
          ${r.urgency}
        </span>
      </td>
      <td>
        <span class="stock-status-pill ${r.status === 'FULFILLED' ? 'status-sufficient' : (r.status === 'PENDING' ? 'status-low' : 'status-critical')}">
          ${r.status}
        </span>
      </td>
      <td>${r.reason}</td>
      <td>
        ${r.status === 'PENDING' ? `
          <button class="btn-primary" style="padding:0.35rem 0.75rem; font-size:0.78rem" onclick="executeFulfillDirect(${r.id})">
            Fulfill (${s.available} in stock)
          </button>
        ` : `<span style="color:#64748b; font-size:0.8rem">Completed</span>`}
      </td>
    `;
    tbody.appendChild(tr);

    if (reqSelect && r.status === 'PENDING') {
      const opt = document.createElement('option');
      opt.value = r.id;
      opt.textContent = `Req #${r.id} - ${r.patient} (${r.units}x ${r.group} for ${r.hospital}) [${r.urgency}]`;
      reqSelect.appendChild(opt);
    }
  });
}

// Render Audit Log Table
function renderAuditLog() {
  const tbody = document.getElementById('auditTableBody');
  if (!tbody) return;

  tbody.innerHTML = '';
  const reversed = [...dbState.auditLog].reverse();

  reversed.forEach(log => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>#${log.id}</strong></td>
      <td><span class="badge-tag oracle">${log.table}</span></td>
      <td><strong>${log.action}</strong></td>
      <td>${log.recordId}</td>
      <td style="font-family:var(--font-mono); font-size:0.78rem">${log.values}</td>
      <td>${log.time}</td>
      <td><span class="badge-tag mysql">${log.user}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// Simulated PL/SQL Procedure: sp_register_donor
function executeRegisterDonor() {
  const fName = document.getElementById('regFirstName').value.trim();
  const lName = document.getElementById('regLastName').value.trim();
  const email = document.getElementById('regEmail').value.trim();
  const phone = document.getElementById('regPhone').value.trim();
  const gender = document.getElementById('regGender').value;
  const dob = document.getElementById('regDob').value;
  const weight = parseFloat(document.getElementById('regWeight').value);
  const group = document.getElementById('regBloodGroup').value;
  const city = document.getElementById('regCity').value.trim();
  const address = document.getElementById('regAddress').value.trim();

  logTerminal(`CALL sp_register_donor('${fName}', '${lName}', '${email}', '${phone}', '${gender}', '${dob}', ${weight}, '${group}', '${city}');`, 'info');

  // Trigger Biometrics Check (Age between 18 and 65)
  const age = fn_calculate_age(dob);
  if (age < 18) {
    logTerminal(`ORA-20001: DONOR_UNDERAGE: Donor age is ${age} years. Blood donation law requires minimum 18 years.`, 'error');
    alert(`Trigger Violation (ORA-20001): Underage donor (${age} yrs). Must be at least 18!`);
    return;
  }
  if (age > 65) {
    logTerminal(`ORA-20002: DONOR_OVERAGE: Donor age is ${age} years. Maximum allowed age is 65.`, 'error');
    alert(`Trigger Violation (ORA-20002): Overage donor (${age} yrs). Max is 65.`);
    return;
  }
  if (weight < 45.0) {
    logTerminal(`ORA-20003: DONOR_UNDERWEIGHT: Donor weight (${weight} kg) is below clinical minimum (45.0 kg).`, 'error');
    alert(`Trigger Violation (ORA-20003): Underweight donor (${weight} kg). Must be >= 45 kg.`);
    return;
  }

  // Duplicate email check
  if (dbState.donors.some(d => d.email.toLowerCase() === email.toLowerCase())) {
    logTerminal(`ORA-00001: unique constraint (BLOOD_BANK.UQ_DONOR_EMAIL) violated. Email ${email} already exists.`, 'error');
    alert(`ORA-00001: Duplicate donor email (${email})!`);
    return;
  }

  const newId = 101 + dbState.donors.length;
  const newDonor = {
    id: newId,
    name: `${fName} ${lName}`,
    email, phone, gender, dob, weight, group, city,
    lastDonated: null,
    totalDonations: 0,
    status: 'ACTIVE'
  };

  dbState.donors.push(newDonor);

  // Add to Audit Log
  const logId = dbState.auditLog.length + 1;
  dbState.auditLog.push({
    id: logId,
    table: 'DONORS',
    action: 'INSERT',
    recordId: String(newId),
    values: `Name=${fName} ${lName}; Group=${group}; City=${city}`,
    time: new Date().toLocaleTimeString(),
    user: 'PLSQL_USER'
  });

  logTerminal(`PL/SQL procedure successfully completed.`, 'success');
  logTerminal(`OUT: o_donor_id = ${newId}`, 'success');
  logTerminal(`OUT: o_status_msg = SUCCESS: Donor registered successfully with ID: ${newId}`, 'success');

  renderMetrics();
  renderDonorsTable();
  renderAuditLog();
  alert(`Donor #${newId} successfully registered!`);
}

// Simulated PL/SQL Procedure: sp_record_donation
function executeRecordDonation() {
  const donorId = parseInt(document.getElementById('donationDonorSelect').value);
  const units = parseInt(document.getElementById('donationUnits').value) || 1;
  const camp = document.getElementById('donationCamp').value;
  const hb = document.getElementById('donationHb').value;

  const donor = dbState.donors.find(d => d.id === donorId);
  if (!donor) return;

  logTerminal(`CALL sp_record_donation(p_donor_id => ${donorId}, p_units => ${units}, p_camp => '${camp}');`, 'info');

  // Check 90-day cooldown via PL/SQL function
  const eligibility = fn_check_donor_eligibility(donorId);
  if (eligibility !== 'ELIGIBLE') {
    logTerminal(`ORA-20004: COOLDOWN_VIOLATION: ${eligibility}`, 'error');
    alert(`Donation Cooldown Trigger Alert:\n${eligibility}`);
    return;
  }

  // Update donor
  const todayStr = new Date().toISOString().split('T')[0];
  donor.lastDonated = todayStr;
  donor.totalDonations += units;

  // Increment stock
  const preUnits = dbState.stock[donor.group].available;
  dbState.stock[donor.group].available += units;
  const postUnits = dbState.stock[donor.group].available;

  const donationId = 501 + dbState.auditLog.length;

  // Audit Logs (Donations insert + Stock update trigger)
  dbState.auditLog.push({
    id: dbState.auditLog.length + 1,
    table: 'DONATIONS',
    action: 'INSERT',
    recordId: String(donationId),
    values: `DonorID=${donorId}; Group=${donor.group}; Units=${units}`,
    time: new Date().toLocaleTimeString(),
    user: 'PLSQL_USER'
  });

  dbState.auditLog.push({
    id: dbState.auditLog.length + 1,
    table: 'BLOOD_STOCK',
    action: 'UPDATE_INVENTORY',
    recordId: donor.group,
    values: `Available=${preUnits} -> ${postUnits} (+${units} units)`,
    time: new Date().toLocaleTimeString(),
    user: 'TRG_AFTER_DONATION'
  });

  logTerminal(`TRIGGER trg_check_donation_cooldown passed.`, 'dim');
  logTerminal(`SUCCESS: Donation recorded (ID: ${donationId}). Stock for ${donor.group} incremented from ${preUnits} to ${postUnits} units.`, 'success');

  renderMetrics();
  renderStockCards();
  renderDonorsTable();
  renderAuditLog();
  alert(`Donation #${donationId} recorded! Stock for ${donor.group} is now ${postUnits} units.`);
}

// Simulated PL/SQL Procedure: sp_process_blood_request (Fulfill)
function executeFulfillRequest() {
  const reqSelect = document.getElementById('fulfillRequestSelect');
  if (!reqSelect || !reqSelect.value) {
    alert('No pending blood requests available to fulfill!');
    return;
  }
  const reqId = parseInt(reqSelect.value);
  executeFulfillDirect(reqId);
}

function executeFulfillDirect(reqId) {
  const req = dbState.requests.find(r => r.id === reqId);
  if (!req) return;

  logTerminal(`CALL sp_process_blood_request(p_request_id => ${reqId}, p_action => 'FULFILL', p_admin => 'ADMIN_CHIEF');`, 'info');

  const stockEntry = dbState.stock[req.group];
  if (stockEntry.available < req.units) {
    logTerminal(`ORA-20005: INSUFFICIENT_STOCK: Cannot fulfill Request #${reqId}. Required: ${req.units} units of ${req.group}, but only ${stockEntry.available} in stock!`, 'error');
    alert(`Insufficient Stock Alert!\nCannot fulfill Request #${reqId}: ${req.units} units of ${req.group} required, but only ${stockEntry.available} in stock.`);
    return;
  }

  // Row locking simulation
  logTerminal(`Acquiring row-level pessimistic lock (SELECT ... FOR UPDATE) on blood_stock for group ${req.group}...`, 'dim');

  // Deduct stock
  const pre = stockEntry.available;
  stockEntry.available -= req.units;
  const post = stockEntry.available;

  // Update request
  req.status = 'FULFILLED';

  const issuanceId = 7001 + dbState.auditLog.length;

  dbState.auditLog.push({
    id: dbState.auditLog.length + 1,
    table: 'BLOOD_STOCK',
    action: 'UPDATE_INVENTORY',
    recordId: req.group,
    values: `Available=${pre} -> ${post} (-${req.units} units for Req #${reqId})`,
    time: new Date().toLocaleTimeString(),
    user: 'TRG_AUDIT_STOCK'
  });

  dbState.auditLog.push({
    id: dbState.auditLog.length + 1,
    table: 'BLOOD_REQUESTS',
    action: 'STATUS_CHANGE',
    recordId: String(reqId),
    values: `Status=PENDING -> FULFILLED; Dispensed=${req.units}x ${req.group} to ${req.hospital}`,
    time: new Date().toLocaleTimeString(),
    user: 'ADMIN_CHIEF'
  });

  logTerminal(`TRIGGER trg_prevent_negative_stock verified (Balance >= 0).`, 'dim');
  logTerminal(`SUCCESS: Request #${reqId} FULFILLED. Dispensed ${req.units} unit(s) of ${req.group} to ${req.hospital} (Issuance #${issuanceId}).`, 'success');

  renderMetrics();
  renderStockCards();
  renderRequestsTable();
  renderAuditLog();
  alert(`Request #${reqId} successfully fulfilled! Dispensed ${req.units} units of ${req.group}.`);
}

// Simulated PL/SQL Procedure: sp_stock_inventory_report
function executeStockReport() {
  logTerminal('EXEC sp_stock_inventory_report;', 'info');
  logTerminal('========================================================================================', 'dim');
  logTerminal('                   BLOOD BANK CENTRAL INVENTORY DASHBOARD REPORT                        ', 'info');
  logTerminal(`                   Generated on: ${new Date().toLocaleString()}                         `, 'dim');
  logTerminal('========================================================================================', 'dim');
  logTerminal('GROUP   AVAILABLE   RESERVED  CRIT_TH   STATUS        COMPAT_POOL   GAUGE', 'warn');
  logTerminal('----------------------------------------------------------------------------------------', 'dim');

  let totalAvail = 0;
  for (const bg of dbState.bloodGroups) {
    const s = dbState.stock[bg.id];
    const status = fn_get_stock_status(bg.id);
    const compat = fn_get_compatible_stock(bg.id);
    totalAvail += s.available;

    const line = `${bg.id.padEnd(8)} ${(s.available + ' units').padEnd(12)} ${String(s.reserved).padEnd(10)} ${String(s.critical).padEnd(10)} [${status.padEnd(10)}] ${(compat + ' units').padEnd(14)} [${status === 'CRITICAL' ? '!! ALERT: CRITICAL LOW !!' : (status === 'LOW' ? '! WARNING: REPLENISH !' : 'OK - HEALTHY')}]`;
    logTerminal(line, status === 'CRITICAL' ? 'error' : (status === 'LOW' ? 'warn' : 'success'));
  }
  logTerminal('----------------------------------------------------------------------------------------', 'dim');
  logTerminal(`TOTAL INVENTORY: ${totalAvail} units currently stored in central repository.`, 'success');
  logTerminal('========================================================================================', 'dim');
}

// Interactive Compatibility Matrix Inspector
function updateCompatibilityInspector() {
  const sel = document.getElementById('compatRecipientSelect');
  if (!sel) return;
  const group = sel.value;

  const bgInfo = dbState.bloodGroups.find(b => b.id === group);
  const compatDonors = [];
  for (const [donorGrp, recipients] of Object.entries(dbState.compatibility)) {
    if (recipients.includes(group)) {
      compatDonors.push(donorGrp);
    }
  }

  const pool = fn_get_compatible_stock(group);

  const container = document.getElementById('compatResultBox');
  if (!container) return;

  container.innerHTML = `
    <div style="background:rgba(255,255,255,0.03); border:1px solid rgba(255,255,255,0.08); border-radius:12px; padding:1.25rem;">
      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1rem;">
        <div>
          <h4 style="font-size:1.15rem; color:#fff; display:flex; align-items:center; gap:0.5rem;">
            Recipient Blood Group: <span class="badge-tag oracle" style="font-size:1.1rem; padding:0.25rem 0.8rem">${group}</span>
          </h4>
          <p style="font-size:0.82rem; color:#94a3b8; margin-top:0.25rem;">${bgInfo.desc}</p>
        </div>
        <div style="text-align:right;">
          <span style="font-size:0.75rem; text-transform:uppercase; color:#64748b;">Total Compatible Units</span>
          <div style="font-size:1.8rem; font-weight:800; color:#38bdf8">${pool} units</div>
        </div>
      </div>
      
      <div style="margin-bottom:0.75rem;">
        <span style="font-size:0.82rem; font-weight:600; color:#cbd5e1;">Compatible Donor Groups (Transfusion Safe):</span>
        <div style="display:flex; flex-wrap:wrap; gap:0.5rem; margin-top:0.5rem;">
          ${compatDonors.map(d => `
            <span class="badge-tag ${d === group ? 'oracle' : 'mysql'}" style="font-size:0.85rem; padding:0.35rem 0.75rem;">
              ${d} (${dbState.stock[d]?.available || 0} in stock) ${d === group ? '★ Exact Match' : '✓ Cross-match'}
            </span>
          `).join('')}
        </div>
      </div>

      <div style="font-size:0.78rem; color:#64748b; margin-top:0.75rem; padding-top:0.5rem; border-top:1px solid rgba(255,255,255,0.05);">
        Antigens Present: <strong style="color:#e2e8f0">${bgInfo.antigen}</strong> | Antibodies in Serum: <strong style="color:#e2e8f0">${bgInfo.antibody}</strong>
      </div>
    </div>
  `;
}

// Tab navigation controller
function setupTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      tabBtns.forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));

      btn.classList.add('active');
      const targetId = btn.getAttribute('data-tab');
      const targetPanel = document.getElementById(targetId);
      if (targetPanel) targetPanel.classList.add('active');
    });
  });
}

// Code viewer tab controller
const codeSnippets = {
  '01_schema_ddl.sql': '-- Loading...',
  '02_functions.sql': '-- Loading...',
  '03_procedures.sql': '-- Loading...',
  '04_triggers.sql': '-- Loading...',
  '05_packages.sql': '-- Loading...',
  '06_test_execution_suite.sql': '-- Loading...',
  'bloodbank_mysql_routines.sql': '-- Loading...'
};

function setupCodeTabs() {
  const codeTabs = document.querySelectorAll('.code-tab');
  const codePre = document.getElementById('codeDisplay');

  codeTabs.forEach(tab => {
    tab.addEventListener('click', async () => {
      codeTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');

      const fileName = tab.getAttribute('data-file');
      await loadCodeFile(fileName);
    });
  });
}

async function loadCodeFile(fileName) {
  const codePre = document.getElementById('codeDisplay');
  if (!codePre) return;

  codePre.textContent = `Loading ${fileName}...`;

  let filePath = `../${fileName}`;
  if (fileName.includes('mysql')) {
    filePath = `../mysql_version/${fileName}`;
  }

  try {
    const res = await fetch(filePath);
    if (!res.ok) throw new Error('File not accessible via HTTP fetch');
    const text = await res.text();
    codePre.textContent = text;
  } catch (err) {
    codePre.textContent = `-- [Note: Local file viewing]\n-- File: ${fileName}\n-- You can inspect the full script directly in: OnlineBloodBank/plsql/${fileName}`;
  }
}

function copyActiveCode() {
  const codePre = document.getElementById('codeDisplay');
  if (!codePre) return;
  navigator.clipboard.writeText(codePre.textContent).then(() => {
    const btn = document.querySelector('.copy-btn');
    if (btn) {
      const orig = btn.innerHTML;
      btn.innerHTML = '<span>✓ Copied!</span>';
      setTimeout(() => btn.innerHTML = orig, 2000);
    }
  });
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  setupTabs();
  setupCodeTabs();
  renderMetrics();
  renderStockCards();
  renderDonorsTable();
  renderRequestsTable();
  renderAuditLog();
  updateCompatibilityInspector();
  logTerminal('PL/SQL Project Visualizer loaded successfully.', 'success');
  logTerminal('Connected to simulated Oracle 21c Database engine.', 'dim');
  executeStockReport();
});
