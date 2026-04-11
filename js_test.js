
  const API = 'https://mediqueue-backend-el5a.onrender.com/api';
  let hospitalId = null, hospitalName = '', hospitalToken = null;
  let socket = null, currentDoctorId = null, allDoctors = [];
  let hospitalDepartments = [];
  let pendingDeleteId = null, pendingDeleteName = '';
  const DEMO_HOSPITAL_ID = '69d20400dcc05573cc367d24';
  const STORAGE_KEYS = {
    token: 'mq_hospital_token',
    hospitalId: 'mq_hospital_id',
    hospitalName: 'mq_hospital_name'
  };

  // ── INIT ──────────────────────────────────────────
  window.onload = () => {
    // Close overlays on backdrop click
    document.querySelectorAll('.overlay').forEach(o => {
      o.addEventListener('click', e => { if (e.target === o) o.classList.remove('show'); });
    });
    restoreSession();
    if (hospitalId && hospitalName) {
      openDashboard();
    }
  };

  function persistSession() {
    if (!hospitalId || !hospitalName || !hospitalToken) return;
    localStorage.setItem(STORAGE_KEYS.token, hospitalToken);
    localStorage.setItem(STORAGE_KEYS.hospitalId, hospitalId);
    localStorage.setItem(STORAGE_KEYS.hospitalName, hospitalName);
  }

  function restoreSession() {
    hospitalToken = localStorage.getItem(STORAGE_KEYS.token);
    hospitalId = localStorage.getItem(STORAGE_KEYS.hospitalId);
    hospitalName = localStorage.getItem(STORAGE_KEYS.hospitalName) || '';
  }

  function clearSession() {
    localStorage.removeItem(STORAGE_KEYS.token);
    localStorage.removeItem(STORAGE_KEYS.hospitalId);
    localStorage.removeItem(STORAGE_KEYS.hospitalName);
  }

  // ── AUTH TAB SWITCH ───────────────────────────────
  function switchAuthTab(id, btn) {
    ['t-login','t-register'].forEach(t => document.getElementById(t).style.display='none');
    document.getElementById(id).style.display = 'block';
    document.querySelectorAll('.auth-tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
  }

  // ── LOGIN ─────────────────────────────────────────
  async function doLogin() {
    const email = document.getElementById('l-email').value.trim();
    const pass  = document.getElementById('l-pass').value;
    hideA('login-err');
    if (!email || !pass) { showA('login-err','Email and password are required'); return; }
    const btn = document.getElementById('btn-login');
    btn.textContent = 'Signing in...'; btn.disabled = true;
    try {
      const res  = await fetch(`${API}/auth/login/hospital`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({email, password:pass})});
      const data = await res.json();
      if (!res.ok) { showA('login-err', data.message || 'Invalid credentials'); return; }
      
      hospitalToken = data.token;
      hospitalId    = data.user.hospitalId;
      hospitalName  = data.user.name;
      persistSession();
      openDashboard();
    } catch(e) { showA('login-err','Server error. Is backend running?'); }
    finally { btn.textContent = 'Sign In →'; btn.disabled = false; }
  }

  // ── REGISTER ─────────────────────────────────────
  async function doRegister() {
    const name  = document.getElementById('r-name').value.trim();
    const addr  = document.getElementById('r-addr').value.trim();
    const depts = document.getElementById('r-depts').value.split(',').map(d=>d.trim()).filter(Boolean);
    const email = document.getElementById('r-email').value.trim();
    const phone = document.getElementById('r-phone').value.trim();
    const pass  = document.getElementById('r-pass').value;
    const pass2 = document.getElementById('r-pass2').value;
    hideA('reg-err');
    if (!name || !addr || !email || !phone || !pass) { showA('reg-err','All fields are required'); return; }
    if (pass !== pass2) { showA('reg-err','Passwords do not match'); return; }
    if (pass.length < 6) { showA('reg-err','Password must be at least 6 characters'); return; }
    const btn = document.getElementById('btn-reg');
    btn.textContent = 'Registering...'; btn.disabled = true;
    try {
      const payload = {
        hospitalName: name,
        address: addr,
        departments: depts,
        email: email,
        phone: phone,
        password: pass
      };
      const res  = await fetch(`${API}/auth/register/hospital`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(payload)});
      const data = await res.json();
      if (!res.ok) { showA('reg-err', data.message || 'Registration failed'); return; }
      // Auto-login after registration — call login route
      const lRes  = await fetch(`${API}/auth/login/hospital`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({email, password:pass})});
      const lData = await lRes.json();
      if (lRes.ok) {
        hospitalToken = lData.token;
        hospitalId    = lData.user.hospitalId;
        hospitalName  = lData.user.name;
        persistSession();
        openDashboard();
      } else {
        // Registration succeeded but auto-login failed — ask user to sign in
        showA('reg-err','Registered! Please sign in now.');
        switchAuthTab('t-login', document.querySelectorAll('.auth-tab')[0]);
        document.getElementById('l-email').value = email;
      }
    } catch(e) { showA('reg-err','Server error. Is backend running?'); }
    finally { btn.textContent = 'Register Hospital →'; btn.disabled = false; }
  }

  // ── LOGOUT ────────────────────────────────────────
  function doLogout() {
    hospitalId = null; hospitalName = ''; hospitalToken = null;
    allDoctors = []; currentDoctorId = null;
    clearSession();
    if (socket) socket.disconnect();
    document.getElementById('dashboard').style.display = 'none';
    document.getElementById('sidebar').style.display   = 'none';
    document.getElementById('h-name-badge').style.display = 'none';
    document.getElementById('auth-screen').style.display  = 'flex';
  }

  // ── OPEN DASHBOARD ────────────────────────────────
  function openDashboard() {
    document.getElementById('auth-screen').style.display  = 'none';
    document.getElementById('dashboard').style.display    = 'block';
    document.getElementById('sidebar').style.display      = 'flex';
    document.getElementById('h-name-badge').textContent   = hospitalName;
    document.getElementById('h-name-badge').style.display = 'inline-block';
    initSocket();
    loadDoctors();
    loadSettingsForm();
  }

  // ── PAGE SWITCHING ────────────────────────────────
  function showPage(id, btn) {
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    document.querySelectorAll('.s-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    if (id === 'p-doctors')   loadDoctors();
    if (id === 'p-settings')  loadSettingsForm();
  }

  // ── MODAL CONTROL ─────────────────────────────────
  function openModal(id)  { document.getElementById(id).classList.add('show'); }
  function closeModal(id) { document.getElementById(id).classList.remove('show'); }

  // ── SOCKET ────────────────────────────────────────
  function initSocket() {
    socket = io('wss://mediqueue-backend-el5a.onrender.com', { transports: ['websocket'] });
    socket.on('connect', () => console.log('Socket connected'));
  }

  function subscribeQueue(doctorId) {
    if (currentDoctorId) { socket.emit('leaveQueue',currentDoctorId); socket.off(`queue:${currentDoctorId}`); }
    socket.emit('joinQueue', doctorId);
    socket.on(`queue:${doctorId}`, data => {
      if (data.type === 'NEXT_PATIENT')    { setToken(data.currentToken,data.currentPatient); renderQueue(data.queue); setCount(data.waitingCount); }
      if (data.type === 'QUEUE_EMPTY')     { setToken(null,'No more patients'); renderQueue([]); setCount(0); }
      if (data.type === 'NEW_APPOINTMENT') loadQueue();
    });
  }

  // ── DOCTORS ───────────────────────────────────────
  async function loadDoctors() {
    try {
      // Guaranteed visibility: load all doctors directly from backend.
      const fetchUrl = hospitalId 
        ? `https://mediqueue-backend-el5a.onrender.com/api/doctors?hospitalId=${hospitalId}`
        : 'https://mediqueue-backend-el5a.onrender.com/api/doctors';
      const res = await fetch(fetchUrl, { cache: 'no-store' });
      const responseData = await res.json();

      console.log('HOSPITAL DATA CHECK:', responseData);

      const incomingData = responseData?.doctors || responseData?.data || responseData;
      allDoctors = Array.isArray(incomingData) ? [...incomingData] : [];

      if (!Array.isArray(incomingData)) {
        console.error('Data is not an array. Check API structure.');
      }

      renderDoctorsTable(allDoctors);
      populateQueueSel(allDoctors);
      updateDoctorStats(allDoctors);
    } catch (err) {
      console.error('API Connection failed:', err);
      allDoctors = [];
      renderDoctorsTable(allDoctors);
      populateQueueSel(allDoctors);
      updateDoctorStats(allDoctors);
    }
  }
  function renderDoctorsTable(docs) {
    const tbody = document.getElementById('doc-tbl-body');
    const safeDoctors = Array.isArray(docs) ? docs : [];
    if (!safeDoctors.length) {
      tbody.innerHTML = `<tr><td colspan="4" style="padding:40px 16px;text-align:center;color:var(--muted);"><div style="display:flex;flex-direction:column;align-items:center;gap:8px;"><p>No doctors found for this Hospital ID.</p><p style="font-size:12px;">Check console for raw data log.</p></div></td></tr>`;
      return;
    }
    tbody.innerHTML = safeDoctors.map((d, index) => `
      <tr>
        <td>
          <div style="display:flex;align-items:center;gap:10px;">
            <div style="width:32px;height:32px;background:var(--primary-lt);border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;">DR</div>
            <strong>${d?.name || 'Unknown Doctor'}</strong>
          </div>
        </td>
        <td><span class="tag tag-blue">${d?.department || 'General'}</span></td>
        <td style="color:var(--muted);">~${d?.avgConsultationTime || d?.avgTime || 15} min</td>
        <td>
          <div style="display:flex;gap:6px;">
            <button class="btn btn-outline btn-sm" onclick="openCabinQRForDoctor('${d?._id || ''}','${escQ(d?.name || 'Unknown Doctor')}','${escQ(d?.department || 'General')}')">QR</button>
            <button class="btn btn-ghost btn-sm" onclick="editDoctor('${d?._id || ''}','${escQ(d?.name || 'Unknown Doctor')}','${escQ(d?.department || 'General')}','${d?.avgConsultationTime || d?.avgTime || 15}')">Edit</button>
            <button class="btn btn-danger btn-sm" onclick="confirmDeleteDoctor('${d?._id || index}','${escQ(d?.name || 'Unknown Doctor')}')">Delete</button>
          </div>
        </td>
      </tr>`).join('');
  }

  function populateQueueSel(docs) {
    const sel = document.getElementById('q-doc-sel');
    sel.innerHTML = '<option value="">-- Select doctor --</option>';
    docs.forEach(d => sel.innerHTML += `<option value="${d._id}">${d.name} — ${d.department}</option>`);
  }

  // ── ADD DOCTOR ────────────────────────────────────
  async function addDoctor() {
    const name = document.getElementById('d-name').value.trim();
    const dept = document.getElementById('d-dept').value.trim();
    const time = document.getElementById('d-time').value;
    hideA('doc-err'); hideA('doc-ok');
    if (!name || !dept) { showA('doc-err','Name and department are required'); return; }
    const btn = document.getElementById('btn-add-doc');
    btn.textContent = 'Adding...'; btn.disabled = true;
    try {
      const res  = await fetch(`${API}/doctors`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({name, hospital:hospitalId, department:dept, avgConsultationTime:parseInt(time)||10})});
      const data = await res.json();
      if (!res.ok) { showA('doc-err', data.message); return; }
      showA('doc-ok', `✅ Dr. ${name} added!`);
      document.getElementById('d-name').value = '';
      document.getElementById('d-dept').value = '';
      document.getElementById('d-time').value = '10';
      toast(`Dr. ${name} added`);
      loadDoctors();
      setTimeout(() => closeModal('modal-add-doctor'), 1200);
    } catch(e) { showA('doc-err','Failed to add doctor'); }
    finally { btn.textContent = 'Add Doctor →'; btn.disabled = false; }
  }

  // ── EDIT DOCTOR ───────────────────────────────────
  function editDoctor(id, name, dept, time) {
    document.getElementById('ed-id').value   = id;
    document.getElementById('ed-name').value = name;
    
    // Set the select element's value if it matches the current predefined options
    const edDept = document.getElementById('ed-dept');
    if (edDept) {
      // Temporarily append the option if it doesn't cleanly exist so edits don't break
      if (!Array.from(edDept.options).some(o => o.value === dept)) {
        edDept.innerHTML += `<option value="${escQ(dept)}">${escQ(dept)}</option>`;
      }
      edDept.value = dept;
    }

    document.getElementById('ed-time').value = time;
    hideA('ed-err');
    openModal('modal-edit-doctor');
  }

  async function saveDoctor() {
    const btn  = document.getElementById('btn-ed');
    const id   = document.getElementById('ed-id').value;
    const name = document.getElementById('ed-name').value.trim();
    const dept = document.getElementById('ed-dept').value.trim();
    const time = document.getElementById('ed-time').value;
    hideA('ed-err');
    if (!name || !dept) { showA('ed-err','Name and department are required'); return; }
    btn.textContent = 'Saving...'; btn.disabled = true;
    try {
      const res  = await fetch(`${API}/doctors/${id}`, {method:'PUT', headers:{'Content-Type':'application/json'}, body:JSON.stringify({name, department:dept, avgConsultationTime:parseInt(time)||10})});
      const data = await res.json();
      if (!res.ok) { showA('ed-err', data.message); return; }
      toast('Doctor updated!');
      closeModal('modal-edit-doctor');
      loadDoctors();
    } catch(e) { showA('ed-err','Server error.'); }
    finally { btn.textContent = 'Save Changes →'; btn.disabled = false; }
  }

  // ── DELETE DOCTOR ─────────────────────────────────
  function confirmDeleteDoctor(id, name) {
    pendingDeleteId   = id;
    pendingDeleteName = name;
    document.getElementById('confirm-msg').textContent = `Dr. ${name} will be permanently removed. This cannot be undone.`;
    openModal('modal-confirm');
  }

  async function confirmDelete() {
    const btn = document.getElementById('confirm-ok-btn');
    btn.textContent = 'Deleting...'; btn.disabled = true;
    try {
      const res = await fetch(`${API}/doctors/${pendingDeleteId}`, {method:'DELETE'});
      if (!res.ok) { toast('Delete failed'); return; }
      toast(`Dr. ${pendingDeleteName} removed`);
      closeModal('modal-confirm');
      loadDoctors();
    } catch(e) { toast('Server error'); }
    finally { btn.textContent = 'Delete →'; btn.disabled = false; }
  }

  // ── QUEUE ─────────────────────────────────────────
  async function loadQueue() {
    const id = document.getElementById('q-doc-sel').value;
    if (!id) return;
    currentDoctorId = id;
    subscribeQueue(id);
    generateCabinQR(id);
    try {
      const res  = await fetch(`${API}/queue/${id}`);
      const data = await res.json();
      setToken(data.currentToken, data.currentPatient);
      renderQueue(data.queue || []);
      setCount(data.waitingCount || 0);
    } catch(e) { console.error(e); }
  }

  async function nextPatient() {
    if (!currentDoctorId) return;
    const btn = document.getElementById('next-btn');
    btn.disabled = true; btn.textContent = 'Loading...';
    try { await fetch(`${API}/queue/${currentDoctorId}/next`, {method:'POST', headers:{'Content-Type':'application/json'}}); }
    catch(e) { console.error(e); }
    btn.disabled = false; btn.textContent = 'Call Next Patient →';
  }

  function setToken(num, name) {
    document.getElementById('ns-token').textContent = num ? `#${num}` : '--';
    document.getElementById('ns-name').textContent  = name || 'No patient yet';
  }
  function setCount(c) {
    document.getElementById('q-count').textContent = `${c} patient${c!==1?'s':''} waiting`;
    document.getElementById('st-wait').textContent = c;
  }

  function renderQueue(queue) {
    const tbody = document.getElementById('q-body');
    const empty = document.getElementById('q-empty');
    const wrap  = document.getElementById('q-table');
    tbody.innerHTML = '';
    if (!queue.length) { wrap.style.display='none'; empty.style.display='block'; empty.innerHTML='<div class="e-ico">🪑</div><p>No patients waiting</p>'; return; }
    wrap.style.display='block'; empty.style.display='none';
    queue.forEach(item => {
      tbody.innerHTML += `<tr>
        <td style="color:var(--muted);">${item.position}</td>
        <td><strong>#${item.tokenNumber}</strong></td>
        <td>${item.patientName}</td>
        <td><span class="badge badge-${item.type==='emergency'?'em':'no'}">${item.type}</span></td>
        <td style="color:var(--muted);">${item.estimatedWaitTime}m</td>
      </tr>`;
    });
  }

  // ── CABIN QR (Doctor) ─────────────────────────────
  function generateCabinQR(doctorId) {
    const el = document.getElementById('qr-inline');
    el.innerHTML = '';
    if (!doctorId) return;
    const qrHospitalId = hospitalId || DEMO_HOSPITAL_ID;
    const payload = `mediqueue://book?doctorId=${doctorId}&hospitalId=${qrHospitalId}`;
    try {
      new QRCode(el, { text: payload, width: 120, height: 120, colorDark: '#0F172A', colorLight: '#F0F4FF', correctLevel: QRCode.CorrectLevel.H });
      setTimeout(() => { const c = el.querySelector('canvas'); if(c) c.style.display='none'; }, 50);
    } catch(e) {
      el.innerHTML = `<p style="font-size:11px;color:var(--muted);word-break:break-all;">${payload}</p>`;
    }
  }

  function openCabinQRModal() {
    if (!currentDoctorId) { toast('Select a doctor first'); return; }
    const doc = allDoctors.find(d => d._id === currentDoctorId);
    openCabinQRForDoctor(currentDoctorId, doc?.name||'Doctor', doc?.department||'');
  }

  function openCabinQRForDoctor(doctorId, name, dept) {
    document.getElementById('m-doc-name').textContent = name;
    document.getElementById('m-dept').textContent     = `${dept} · ${hospitalName}`;
    const el = document.getElementById('qr-render');
    el.innerHTML = '';
    const qrHospitalId = hospitalId || DEMO_HOSPITAL_ID;
    const payload = `mediqueue://book?doctorId=${doctorId}&hospitalId=${qrHospitalId}`;
    try {
      new QRCode(el, { text: payload, width: 180, height: 180, colorDark: '#0F172A', colorLight: '#FFFFFF', correctLevel: QRCode.CorrectLevel.H });
      setTimeout(() => { const c = el.querySelector('canvas'); if(c) c.style.display='none'; }, 50);
    } catch (e) {
      el.innerHTML = `<p style="font-size:11px;color:var(--muted);word-break:break-all;">${payload}</p>`;
    }
    openModal('modal-cabin-qr');
  }

  function printCabinQR() {
    const qrEl = document.getElementById('qr-render').querySelector('img') || document.getElementById('qr-inline').querySelector('img');
    const name = document.getElementById('m-doc-name').textContent || 'Doctor';
    const dept = document.getElementById('m-dept').textContent     || hospitalName;
    const win  = window.open('');
    win.document.write(`<html><body style="text-align:center;padding:48px;font-family:sans-serif;">
      <h2 style="color:#2563EB;font-size:26px;margin-bottom:4px;">MediQueue</h2>
      <h3 style="font-size:20px;margin:8px 0;">${name}</h3>
      <p style="color:#64748B;margin-bottom:20px;">${dept}</p>
      <img src="${qrEl?.src||''}" style="width:260px;height:260px;border-radius:12px;border:1px solid #E2E8F0;"/>
      <p style="font-size:13px;color:#94A3B8;margin-top:16px;">Scan to book your appointment</p>
    </body></html>`);
    win.print();
  }

  // ── RECEPTION QR (Hospital) ───────────────────────
  function loadReceptionQR() {
    console.log('Current Hospital ID for QR:', hospitalId);
    const qrHospitalId = hospitalId || DEMO_HOSPITAL_ID;
    if (!hospitalId) console.warn('Using demo fallback hospital ID for QR:', DEMO_HOSPITAL_ID);
    
    document.getElementById('reception-qr-card').style.display = 'block';
    document.getElementById('reception-hosp-name').textContent = hospitalName;
    const payload = `mediqueue://hospital?id=${qrHospitalId}`;
    document.getElementById('reception-qr-payload').textContent = payload;

    const el = document.getElementById('qr-reception-render');
    el.innerHTML = '';
    try {
      new QRCode(el, { text: payload, width: 200, height: 200, colorDark: '#0F172A', colorLight: '#FFFFFF', correctLevel: QRCode.CorrectLevel.H });
      setTimeout(() => { const c = el.querySelector('canvas'); if(c) c.style.display='none'; }, 50);
    } catch(e) {
      el.innerHTML = `<p style="font-size:11px;color:var(--muted);word-break:break-all;">${payload}</p>`;
    }
  }

  function printReceptionQR() {
    const img = document.getElementById('qr-reception-render').querySelector('img');
    const win = window.open('');
    win.document.write(`<html><body style="text-align:center;padding:48px;font-family:sans-serif;">
      <h2 style="color:#2563EB;font-size:26px;margin-bottom:4px;">MediQueue</h2>
      <h3 style="font-size:20px;margin:8px 0;">${hospitalName}</h3>
      <p style="color:#64748B;margin-bottom:20px;">Reception Check-In</p>
      <img src="${img?.src||''}" style="width:280px;height:280px;border-radius:12px;border:1px solid #E2E8F0;"/>
      <p style="font-size:13px;color:#94A3B8;margin-top:16px;">Scan to browse all doctors &amp; book your slot</p>
    </body></html>`);
    win.print();
  }

  // ── SETTINGS ─────────────────────────────────────
  async function loadSettingsForm() {
    if (!hospitalId) return;
    hideA('set-err'); hideA('set-ok');
    try {
      const res  = await fetch(`${API}/hospitals`, { cache: 'no-store' });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Failed to load hospitals');
      const list = Array.isArray(data) ? data : (Array.isArray(data?.hospitals) ? data.hospitals : []);
      const h    = list.find(x => x._id === hospitalId);
      if (!h) return;
      hospitalDepartments = h.departments || [];
      document.getElementById('set-name').value  = h.name || '';
      document.getElementById('set-addr').value  = h.address || '';
      document.getElementById('set-depts').value = hospitalDepartments.join(', ');
      populateDeptDropdowns();
    } catch(e) { console.error('loadSettingsForm error:', e); }
  }

  function populateDeptDropdowns() {
    const dSel = document.getElementById('d-dept');
    if (dSel) {
      dSel.innerHTML = '<option value="">Select Department...</option>';
      hospitalDepartments.forEach(d => dSel.innerHTML += `<option value="${escQ(d)}">${escQ(d)}</option>`);
    }
    const edSel = document.getElementById('ed-dept');
    if (edSel) {
      edSel.innerHTML = '<option value="">Select Department...</option>';
      hospitalDepartments.forEach(d => edSel.innerHTML += `<option value="${escQ(d)}">${escQ(d)}</option>`);
    }
  }

  async function saveSettings() {
    const btn   = document.getElementById('btn-settings');
    const name  = document.getElementById('set-name').value.trim();
    const addr  = document.getElementById('set-addr').value.trim();
    const depts = document.getElementById('set-depts').value.split(',').map(d=>d.trim()).filter(Boolean);
    hideA('set-err'); hideA('set-ok');
    if (!name || !addr) { showA('set-err','Name and address are required'); return; }
    btn.textContent = 'Saving...'; btn.disabled = true;
    try {
      const res  = await fetch(`${API}/hospitals/${hospitalId}`, {method:'PUT', headers:{'Content-Type':'application/json'}, body:JSON.stringify({name, address:addr, departments:depts})});
      const data = await res.json();
      if (!res.ok) { showA('set-err', data.message); return; }
      hospitalName = data.name;
      hospitalDepartments = depts;
      document.getElementById('h-name-badge').textContent = hospitalName;
      populateDeptDropdowns();
      showA('set-ok','✅ Settings saved!');
      toast('Hospital profile updated');
    } catch(e) { showA('set-err','Server error.'); }
    finally { btn.textContent = 'Save Changes →'; btn.disabled = false; }
  }

  // ── HELPERS ───────────────────────────────────────
  function showA(id, msg) { const el=document.getElementById(id); el.style.display='flex'; document.getElementById(`${id}-msg`).textContent=msg; }
  function hideA(id)      { document.getElementById(id).style.display='none'; }
  function toast(msg)     { const t=document.getElementById('toast'); t.textContent=msg; t.classList.add('show'); setTimeout(()=>t.classList.remove('show'),3000); }
  function updateDoctorStats(doctors) {
    const list = Array.isArray(doctors) ? doctors : [];
    document.getElementById('st-docs').textContent = String(list.length);
    const uniqueDepts = [...new Set(list.map(d => d?.department).filter(Boolean))];
    document.getElementById('st-depts').textContent = String(uniqueDepts.length);
  }
  function normalizeDoctorsResponse(data) {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.doctors)) return data.doctors;
    if (Array.isArray(data?.data)) return data.data;
    console.error('Data received is not an array:', data);
    return [];
  }
  function escQ(str)      { return String(str||'').replace(/'/g,"\\'").replace(/"/g,"&quot;"); }
