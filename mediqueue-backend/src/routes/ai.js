const router = require('express').Router();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Hospital = require('../models/Hospital');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const GEMINI_MODEL_CANDIDATES = [
  process.env.GEMINI_MODEL,
  'gemini-2.0-flash',
  'gemini-2.0-flash-001',
  'gemini-2.0-flash-lite',
  'gemini-2.0-flash-lite-001',
].filter(Boolean);

async function generateWithGemini(prompt, label) {
  let lastError = null;

  for (const modelName of GEMINI_MODEL_CANDIDATES) {
    try {
      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const responseText = result.response.text().trim();
      console.log(`📨 Gemini ${label} response (${modelName}):`, responseText);
      return responseText;
    } catch (error) {
      lastError = error;
      console.warn(`⚠️ Gemini ${label} failed with ${modelName}:`, error.message);
    }
  }

  throw lastError || new Error('No Gemini model could generate content');
}

// Fallback triage map for when API fails - matches database departments
const triageMap = {
  'chest': { department: 'Cardiology', emoji: '❤️', message: 'Chest discomfort may indicate a cardiac condition. A cardiologist can provide prompt evaluation.' },
  'heart': { department: 'Cardiology', emoji: '❤️', message: 'Heart-related symptoms warrant immediate cardiac assessment.' },
  'breath': { department: 'General', emoji: '🫁', message: 'Breathing difficulties need medical evaluation.' },
  'breathe': { department: 'General', emoji: '🫁', message: 'Respiratory issues need medical attention.' },
  'head': { department: 'Neurology', emoji: '🧠', message: 'Headaches may be neurological and should be evaluated by a neurologist if persistent.' },
  'dizziness': { department: 'Neurology', emoji: '🧠', message: 'Dizziness can be a neurological sign and should be evaluated by a neurologist.' },
  'numbness': { department: 'Neurology', emoji: '🧠', message: 'Numbness may point to a neurological issue and should be assessed by a neurologist.' },
  'vision': { department: 'Neurology', emoji: '👁️', message: 'Vision changes can be neurological and need a specialist review.' },
  'seizure': { department: 'Neurology', emoji: '🧠', message: 'Seizure-like symptoms require urgent neurological assessment.' },
  'fever': { department: 'General', emoji: '🌡️', message: 'Fever needs medical evaluation first.' },
  'stomach': { department: 'General', emoji: '🩺', message: 'Stomach issues need medical attention.' },
  'skin': { department: 'General', emoji: '✨', message: 'Skin conditions require medical evaluation.' },
  'eye': { department: 'Neurology', emoji: '👁️', message: 'Eye symptoms can be neurological and should be assessed by a specialist.' },
  'back': { department: 'Neurology', emoji: '🦴', message: 'Back pain may need neurological evaluation depending on the symptoms.' },
  'joint': { department: 'General', emoji: '🦴', message: 'Joint discomfort needs medical attention.' },
  'throat': { department: 'ENT', emoji: '👄', message: 'Throat pain often needs ENT evaluation.' },
  'ear': { department: 'ENT', emoji: '👂', message: 'Ear pain and ear symptoms should be evaluated by an ENT specialist.' },
  'pain': { department: 'General', emoji: '🩺', message: 'Let a doctor assess your pain.' },
  'blood': { department: 'General', emoji: '🩺', message: 'Blood-related concerns need medical attention.' },
  'child': { department: 'Pediatrics', emoji: '👶', message: 'Pediatric care is recommended for children.' },
  'baby': { department: 'Pediatrics', emoji: '👶', message: 'Your baby needs pediatric specialist care.' },
};

// Normalize department names and synonyms to canonical forms
function canonicalDepartmentName(dept) {
  if (!dept) return '';
  const normalized = String(dept).toLowerCase().trim();

  const departmentMap = {
    'general medicine': 'General Medicine',
    'general': 'General Medicine',
    'gp': 'General Medicine',
    'physician': 'General Medicine',
    'internal medicine': 'General Medicine',
    'medicine': 'General Medicine',
    'cardiology': 'Cardiology',
    'cardiac': 'Cardiology',
    'heart': 'Cardiology',
    'pediatrics': 'Pediatrics',
    'pediatric': 'Pediatrics',
    'child': 'Pediatrics',
    'pediatrician': 'Pediatrics',
    'neurology': 'Neurology',
    'neurological': 'Neurology',
    'brain': 'Neurology',
    'headache': 'Neurology',
    'vision': 'Neurology',
    'dizziness': 'Neurology',
    'seizure': 'Neurology',
    'ent': 'ENT',
    'ear': 'ENT',
    'throat': 'ENT',
    'otolaryngology': 'ENT',
    'gastroenterology': 'Gastroenterology',
    'gastric': 'Gastroenterology',
    'stomach': 'Gastroenterology',
    'dermatology': 'Dermatology',
    'skin': 'Dermatology',
    'orthopedics': 'Orthopedics',
    'orthopaedics': 'Orthopedics',
    'bone': 'Orthopedics',
    'joint': 'Orthopedics',
    'rheumatology': 'Rheumatology',
    'ophthalmology': 'Ophthalmology',
    'eye': 'Ophthalmology',
    'pulmonology': 'Pulmonology',
    'respiratory': 'Pulmonology',
  };

  if (departmentMap[normalized]) {
    return departmentMap[normalized];
  }

  if (/\b(ent|ear|nose|throat|otolaryngology)\b/.test(normalized)) {
    return 'ENT';
  }

  if (/\b(general|medicine|internal)\b/.test(normalized)) {
    return 'General Medicine';
  }

  if (/\b(cardio|heart)\b/.test(normalized)) {
    return 'Cardiology';
  }

  if (/\b(neuro|brain|headache|dizziness|vision|seizure|stroke)\b/.test(normalized)) {
    return 'Neurology';
  }

  if (/\b(pediatr|child|baby)\b/.test(normalized)) {
    return 'Pediatrics';
  }

  if (/\b(derm|skin)\b/.test(normalized)) {
    return 'Dermatology';
  }

  if (/\b(gastro|stomach|digest|intestinal|hepatic|liver)\b/.test(normalized)) {
    return 'Gastroenterology';
  }

  if (/\b(ophthalm|eye|vision)\b/.test(normalized)) {
    return 'Ophthalmology';
  }

  if (/\b(ortho|bone|joint)\b/.test(normalized)) {
    return 'Orthopedics';
  }

  if (/\b(pulmon|lung|respir)\b/.test(normalized)) {
    return 'Pulmonology';
  }

  if (/\b(rheumat)\b/.test(normalized)) {
    return 'Rheumatology';
  }

  return dept.trim();
}

async function getAvailableDepartments() {
  const hospitals = await Hospital.find().select('departments');
  const departments = new Set();

  hospitals.forEach(hospital => {
    (hospital.departments || []).forEach(dept => {
      const trimmed = String(dept || '').trim();
      if (trimmed) {
        departments.add(trimmed);
      }
    });
  });

  return Array.from(departments);
}

function findMatchingDepartment(requestedDept, availableDepartments) {
  if (!requestedDept || !Array.isArray(availableDepartments)) return null;

  const normalizedRequested = canonicalDepartmentName(requestedDept);
  const exactMatch = availableDepartments.find(dept => dept.toLowerCase() === requestedDept.toLowerCase());
  if (exactMatch) return exactMatch;

  const availableMap = new Map();
  availableDepartments.forEach(dept => {
    const canonical = canonicalDepartmentName(dept);
    availableMap.set(canonical.toLowerCase(), dept);
  });

  if (availableMap.has(normalizedRequested.toLowerCase())) {
    return availableMap.get(normalizedRequested.toLowerCase());
  }

  // If the request maps to a canonical general department, prefer any general-like department available
  if (normalizedRequested.toLowerCase() === 'general medicine') {
    const generalMatch = availableDepartments.find(dept => dept.toLowerCase().includes('general'));
    if (generalMatch) return generalMatch;
  }

  return null;
}

// Personalized fallback logic for symptom-based questions and routing
function buildPatientText(symptoms, answers = '') {
  return `${symptoms || ''}\n${answers || ''}`.toLowerCase();
}

function hasAny(text, patterns) {
  return patterns.some((pattern) => pattern.test(text));
}

function pickSymptomProfile(symptoms, answers = '') {
  const text = buildPatientText(symptoms, answers);

  const profiles = [
    {
      id: 'cardiac',
      department: 'Cardiology',
      emoji: '\u2764\uFE0F',
      specialistMessage: 'Your symptoms sound more heart or circulation related, so Cardiology is the better fit.',
      generalMessage: 'If the discomfort is mild or non-specific, starting with General Medicine is reasonable.',
      keywords: [/\bchest\b/, /\bheart\b/, /\bpalpitation/, /\bpressure\b/, /\btightness\b/],
      specialistTriggers: [/\bchest pain\b/, /\bchest pressure\b/, /\btightness\b/, /\bpalpitation/, /\bpain.*left arm\b/, /\bsweating\b/, /\bshortness of breath\b/],
      emergencyTriggers: [/\bcrushing chest pain\b/, /\bsevere chest pain\b/, /\bcannot breathe\b/, /\bfaint(ed|ing)?\b/],
      questions: [
        'Where exactly is the chest discomfort, and does it feel like pressure, tightness, burning, or stabbing pain?',
        'Does it spread to your arm, jaw, shoulder, or back, or happen with walking or climbing stairs?',
        'Are you also having shortness of breath, sweating, dizziness, or palpitations?',
        'How long does each episode last, and is it getting worse or happening more often?',
      ],
    },
    {
      id: 'respiratory',
      department: 'Pulmonology',
      emoji: '\uD83E\uDEC1',
      specialistMessage: 'Because the symptoms center on breathing or the lungs, Pulmonology is the better specialty.',
      generalMessage: 'For a mild cough, cold, or simple viral illness, General Medicine is usually the right starting point.',
      keywords: [/\bcough\b/, /\bbreath\b/, /\bbreathing\b/, /\bwheez/, /\blung\b/, /\bcongestion\b/],
      specialistTriggers: [/\bshortness of breath\b/, /\bwheez/, /\btrouble breathing\b/, /\bchest tightness\b/, /\bcoughing up blood\b/],
      emergencyTriggers: [/\bcannot breathe\b/, /\bblue lips\b/, /\bsevere shortness of breath\b/],
      questions: [
        'Is it mainly cough, wheezing, chest tightness, or trouble taking a full breath?',
        'Did this start after a cold, dust exposure, exercise, allergy trigger, or suddenly without warning?',
        'Do you have fever, mucus, wheezing, or pain when breathing deeply?',
        'Can you speak and walk normally, or do you get breathless with small activity?',
      ],
    },
    {
      id: 'neuro',
      department: 'Neurology',
      emoji: '\uD83E\uDDE0',
      specialistMessage: 'Because there are neurological warning signs with the headache or nerve symptoms, Neurology is the better fit.',
      generalMessage: 'For a simple short-term headache without red flags, General Medicine is the right first step.',
      keywords: [/\bheadache\b/, /\bmigraine\b/, /\bdizziness\b/, /\bnumbness\b/, /\bseizure\b/, /\bvision change\b/, /\bweakness\b/],
      specialistTriggers: [/\bnumbness\b/, /\bvision\b/, /\bseizure\b/, /\bweakness\b/, /\bbalance\b/, /\bslurred speech\b/, /\bconfusion\b/, /\bpersistent headache\b/],
      emergencyTriggers: [/\bworst headache\b/, /\bpassed out\b/, /\bslurred speech\b/, /\bone-sided weakness\b/, /\bseizure\b/],
      questions: [
        'Where is the headache or neurological symptom, and is it new, sudden, one-sided, or different from usual?',
        'Do you also have vomiting, blurred vision, numbness, weakness, imbalance, or trouble speaking?',
        'How severe is it from 1 to 10, and has it been constant or getting worse over time?',
        'Did it start after fever, injury, lack of sleep, stress, or does it happen without a clear trigger?',
      ],
    },
    {
      id: 'gastro',
      department: 'Gastroenterology',
      emoji: '\uD83E\uDE7A',
      specialistMessage: 'The symptoms sound focused on the stomach or digestive system, so Gastroenterology may be appropriate.',
      generalMessage: 'For a simple short-lived stomach issue, General Medicine is usually enough to start.',
      keywords: [/\bstomach\b/, /\babdominal\b/, /\bvomit/, /\bdiarr/, /\bnausea\b/, /\bconstipation\b/, /\bacid\b/],
      specialistTriggers: [/\bsevere abdominal pain\b/, /\bblood in stool\b/, /\bpersistent vomiting\b/, /\bblack stool\b/, /\bweight loss\b/],
      emergencyTriggers: [/\bvomiting blood\b/, /\bblack stool\b/, /\bsevere abdominal pain\b/],
      questions: [
        'Where exactly is the stomach or abdominal discomfort, and is it cramping, burning, bloating, or sharp pain?',
        'Are you having nausea, vomiting, diarrhea, constipation, acidity, or pain after eating?',
        'Have you noticed fever, blood in vomit or stool, dark stool, or dehydration?',
        'Did it begin after outside food, spicy food, alcohol, a new medicine, or has it been recurring?',
      ],
    },
    {
      id: 'ent',
      department: 'ENT',
      emoji: '\uD83D\uDC42',
      specialistMessage: 'Because the symptoms are focused on the ear, nose, or throat, ENT is the better specialty.',
      generalMessage: 'For a mild sore throat or common cold, General Medicine is usually enough to start.',
      keywords: [/\bear\b/, /\bthroat\b/, /\bsore throat\b/, /\bsinus\b/, /\bnose\b/, /\bvoice\b/, /\bhearing\b/],
      specialistTriggers: [/\bear discharge\b/, /\bhearing loss\b/, /\bsevere ear pain\b/, /\btonsil\b/, /\bsinus pain\b/],
      emergencyTriggers: [/\bcannot swallow\b/, /\bdrooling\b/, /\btrouble breathing\b/],
      questions: [
        'Is the main issue ear pain, blocked nose, sore throat, voice change, or trouble hearing?',
        'Do you have fever, ear discharge, swollen glands, facial pain, or difficulty swallowing?',
        'Is one side worse than the other, and has the pain been getting worse over the last few days?',
        'Did this start after a cold, allergy flare, water entering the ear, or repeated throat infection?',
      ],
    },
    {
      id: 'skin',
      department: 'Dermatology',
      emoji: '\u2728',
      specialistMessage: 'The symptoms seem skin related, so Dermatology is likely the best fit.',
      generalMessage: 'If the rash or irritation is mild and recent, General Medicine can be the first step.',
      keywords: [/\brash\b/, /\bitch/, /\bskin\b/, /\bredness\b/, /\bpimple\b/, /\bblister\b/, /\bswelling\b/],
      specialistTriggers: [/\bspreading rash\b/, /\bblister\b/, /\bpus\b/, /\bsevere itching\b/, /\bskin infection\b/],
      emergencyTriggers: [/\bface swelling\b/, /\blip swelling\b/, /\btongue swelling\b/, /\bbreathing difficulty\b/],
      questions: [
        'What does the skin problem look like: rash, bumps, blisters, redness, peeling, or swelling?',
        'Where on the body is it, and is it spreading, painful, itchy, or warm to touch?',
        'Did it start after a new food, soap, medicine, insect bite, or outdoor exposure?',
        'Do you also have fever, discharge, swelling of the face, or trouble breathing?',
      ],
    },
    {
      id: 'eye',
      department: 'Ophthalmology',
      emoji: '\uD83D\uDC41\uFE0F',
      specialistMessage: 'Because the complaint is centered on the eyes or vision, Ophthalmology is more appropriate.',
      generalMessage: 'For mild eye irritation with no vision change, General Medicine can still be a reasonable first step.',
      keywords: [/\beye\b/, /\bvision\b/, /\bblurred\b/, /\bred eye\b/, /\bwatering\b/, /\blight sensitivity\b/],
      specialistTriggers: [/\bvision change\b/, /\bblurred\b/, /\beye pain\b/, /\blight sensitivity\b/, /\bdouble vision\b/],
      emergencyTriggers: [/\bsudden vision loss\b/, /\bcannot see\b/, /\bchemical splash\b/],
      questions: [
        'Is the problem pain, redness, watering, discharge, swelling, or blurred vision?',
        'Is one eye involved or both, and did it start suddenly or gradually?',
        'Do you have light sensitivity, headache, eye injury, or trouble seeing clearly?',
        'Did this begin after dust, screen strain, contact lens use, allergy, or infection exposure?',
      ],
    },
    {
      id: 'ortho',
      department: 'Orthopedics',
      emoji: '\uD83E\uDDB4',
      specialistMessage: 'Because the symptoms sound musculoskeletal, Orthopedics is the better fit.',
      generalMessage: 'For mild body pain, strain, or early joint pain, General Medicine is often the right first step.',
      keywords: [/\bback\b/, /\bjoint\b/, /\bknee\b/, /\bshoulder\b/, /\bneck\b/, /\bsprain\b/, /\bbone\b/],
      specialistTriggers: [/\bcannot walk\b/, /\bswollen joint\b/, /\binjury\b/, /\bback pain radiating\b/, /\bnumbness\b/, /\bfall\b/],
      emergencyTriggers: [/\bdeformity\b/, /\bcannot move\b/, /\bloss of bladder\b/],
      questions: [
        'Which joint, bone, muscle, or part of the back is affected, and did it start after strain or injury?',
        'Is the pain sharp, aching, radiating, or associated with stiffness, swelling, or reduced movement?',
        'Can you walk and use the area normally, or is movement limited?',
        'Does the pain go into the arm or leg, or come with numbness, weakness, or swelling?',
      ],
    },
    {
      id: 'pediatric',
      department: 'Pediatrics',
      emoji: '\uD83D\uDC76',
      specialistMessage: 'Because the patient is a child or baby, Pediatrics is the right department.',
      generalMessage: 'General Medicine can help only if Pediatrics is not available, but Pediatrics is preferred.',
      keywords: [/\bchild\b/, /\bbaby\b/, /\binfant\b/, /\btoddler\b/],
      specialistTriggers: [/\bchild\b/, /\bbaby\b/, /\binfant\b/, /\btoddler\b/],
      emergencyTriggers: [/\bnot feeding\b/, /\bvery sleepy\b/, /\bseizure\b/],
      questions: [
        'How old is the child, and what is the main symptom worrying you most right now?',
        'Is there fever, vomiting, breathing difficulty, reduced feeding, or unusual sleepiness?',
        'When did this start, and is the child active, drinking fluids, and passing urine normally?',
        'Has the child had similar episodes before or any recent infection exposure?',
      ],
    },
  ];

  const matchedProfile = profiles.find((profile) => hasAny(text, profile.keywords));
  if (matchedProfile) return matchedProfile;

  if (hasAny(text, [/\bfever\b/, /\bcold\b/, /\bcough\b/, /\bsore throat\b/, /\bbody ache\b/, /\btired\b/, /\bweakness\b/])) {
    return {
      id: 'general-viral',
      department: 'General Medicine',
      emoji: '\uD83C\uDF21\uFE0F',
      specialistMessage: 'This sounds more like a common viral or general medical illness, so General Medicine is the right place to start.',
      generalMessage: 'This sounds more like a common viral or general medical illness, so General Medicine is the right place to start.',
      specialistTriggers: [],
      emergencyTriggers: [/\bcannot breathe\b/, /\bsevere dehydration\b/, /\bconfusion\b/],
      questions: [
        'Which symptoms started first, and when did they begin?',
        'Do you have fever, cough, sore throat, runny nose, body pain, vomiting, or loose stools?',
        'Have the symptoms been mild and improving, or are they getting worse day by day?',
        'Are you able to eat, drink fluids, and do normal activities, or feeling too weak to manage?',
      ],
    };
  }

  return {
    id: 'general',
    department: 'General Medicine',
    emoji: '\uD83E\uDE7A',
    specialistMessage: 'General Medicine is the best first step for a broad symptom review.',
    generalMessage: 'General Medicine is the best first step for a broad symptom review.',
    specialistTriggers: [],
    emergencyTriggers: [],
    questions: [
      `What is the main symptom bothering you the most about "${symptoms}"?`,
      'When did it start, and is it improving, staying the same, or getting worse?',
      'How severe is it from 1 to 10, and what daily activities is it affecting?',
      'Do you have any other associated symptoms, past medical issues, or medicines related to this?',
    ],
  };
}

function determineSeverity(symptoms, answers = '', profile = null) {
  const text = buildPatientText(symptoms, answers);
  const targetProfile = profile || pickSymptomProfile(symptoms, answers);
  const emergency = hasAny(text, targetProfile.emergencyTriggers || []);
  const severeWords = hasAny(text, [
    /\bsevere\b/, /\bunbearable\b/, /\bworst\b/, /\bcannot\b/, /\bunable\b/, /\bfainted?\b/,
    /\bconfusion\b/, /\bbleeding\b/, /\bpersistent\b/, /\bgetting worse\b/, /\bhigh fever\b/,
  ]);
  const durationConcern = hasAny(text, [/\b\d+\s*(day|days|week|weeks)\b/, /\bmore than 3 days\b/, /\bfor a week\b/]);
  const specialistFlag = hasAny(text, targetProfile.specialistTriggers || []);
  const mildWords = hasAny(text, [/\bmild\b/, /\blight\b/, /\bcommon cold\b/, /\bslight\b/, /\bsimple\b/]);

  return {
    emergency,
    specialist: emergency || specialistFlag || (severeWords && !mildWords) || (durationConcern && specialistFlag),
    mild: mildWords && !severeWords && !emergency,
  };
}

function buildQuestionSet(symptoms) {
  const profile = pickSymptomProfile(symptoms);
  return profile.questions.slice(0, 4);
}

function localTriage(symptoms, answers = '') {
  const profile = pickSymptomProfile(symptoms, answers);
  const severity = determineSeverity(symptoms, answers, profile);

  if (severity.emergency) {
    return {
      department: profile.department,
      emoji: profile.emoji,
      message: 'Your symptoms include warning signs that need urgent medical evaluation. Please seek immediate care and go to the most relevant department now.',
      isEmergency: true,
    };
  }

  if (profile.department !== 'General Medicine' && severity.specialist && !severity.mild) {
    return {
      department: profile.department,
      emoji: profile.emoji,
      message: profile.specialistMessage,
      isEmergency: false,
    };
  }

  return {
    department: 'General Medicine',
    emoji: '\uD83E\uDE7A',
    message: profile.generalMessage || 'Your symptoms sound common or non-specific, so General Medicine is the right first step.',
    isEmergency: false,
  };
}

async function generateQuestions(symptoms) {
  const prompt = `You are an expert medical assistant.
Generate 4 personalized follow-up questions for a patient with these symptoms: "${symptoms}".
The questions must be directly tailored to the mentioned symptoms, not generic placeholders.
Ask about likely causes, red flags, severity, location, timing, and associated symptoms that are specific to this complaint.
Respond ONLY with valid JSON using this exact structure:
{
  "questions": ["Question 1?", "Question 2?", "Question 3?", "Question 4?"]
}`;

  try {
    const responseText = await generateWithGemini(prompt, 'questions');

    let cleanJson = responseText
      .replace(/```json\n?/g, '')
      .replace(/```\n?/g, '')
      .trim();

    const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      cleanJson = jsonMatch[0];
    }

    const parsed = JSON.parse(cleanJson);
    if (Array.isArray(parsed.questions) && parsed.questions.length > 0) {
      return parsed.questions.slice(0, 4);
    }
  } catch (error) {
    console.warn('[AI] Gemini questions failed:', error.message);
  }

  return buildQuestionSet(symptoms);
}
router.post('/questions', async (req, res) => {
  try {
    const { symptoms } = req.body;
    if (!symptoms) return res.status(400).json({ message: 'Symptoms are required' });

    const questions = await generateQuestions(symptoms);
    if (questions.length === 0) {
      return res.status(500).json({ error: 'Unable to generate questions' });
    }
    return res.json({ questions });
  } catch (error) {
    console.error('❌ Questions generation error:', error.message);
    res.status(500).json({ error: 'Failed to generate questions' });
  }
});

router.post('/triage', async (req, res) => {
  try {
    const { symptoms, answers } = req.body;
    if (!symptoms) return res.status(400).json({ message: 'Symptoms are required' });

    const availableDepartments = await getAvailableDepartments();
    const departmentOptions = availableDepartments.length
      ? availableDepartments.join(', ')
      : 'General Medicine, Cardiology, Neurology, ENT, Pediatrics';

    try {
      // Improved prompt for better JSON output
      let prompt = `You are an expert hospital triage AI.
Analyze the following patient symptoms: "${symptoms}"`;

      if (answers) {
        prompt += `\n\nAdditional patient information:\n${answers}`;
      }

      prompt += `

The hospital has these departments: ${departmentOptions}.
PRIORITY ANALYSIS RULES (in order):

1. **Infectious/Viral Pattern**: If fever, cold, sore throat, cough are present → "General Medicine" (fever-related headache/body pain are part of viral illness)
2. **Emergency Symptoms**: Chest pain, severe shortness of breath, stroke signs → "Cardiology" or appropriate emergency
3. **Neurological Specialist Needed**: ONLY if headache is:
   - Severe/persistent (>3 days) AND no fever/cold
   - WITH neurological symptoms (dizziness, numbness, vision changes, balance issues, seizures)
   - Different from patient's normal headaches
4. **ENT Issues**: Ear pain, discharge, pressure, hearing loss specifically → "ENT"
5. **Pediatric**: Patient is clearly a child or baby → "Pediatrics"
6. **Multiple Unrelated Systems**: Route to "General Medicine"
7. **Short-term mild symptoms**: Recent onset (<2 days), no fever → "General Medicine"

CRITICAL: A headache with fever/cold/cough is a **viral infection**, NOT neurology. Route to General Medicine.
IMPORTANT: Use the follow-up answers to decide whether the issue is mild/common or severe/specialist-level.
If the complaint is mild, recent, non-specific, or without red flags, choose "General Medicine".
Only choose a specialty when the symptoms and answers clearly point to that system or include warning signs.

Respond ONLY with a valid JSON object (no markdown, no backticks, no extra text) using this exact structure:
{
  "department": "Choose ONE of the available departments above",
  "emoji": "A single relevant emoji (e.g., 🩺, ❤️, 🧠, 👂)",
  "message": "A friendly, 1-2 sentence recommendation explaining why they need this department.",
  "isEmergency": true/false (true if symptoms like severe chest pain, stroke signs, or severe bleeding)
}`;

      const responseText = await generateWithGemini(prompt, 'triage');
      
      // Clean response of any markdown formatting
      let cleanJson = responseText
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      
      // Try to extract JSON if it's embedded in text
      const jsonMatch = cleanJson.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        cleanJson = jsonMatch[0];
      }
      
      const triageResult = JSON.parse(cleanJson);
      
      // Validate and normalize the response
      if (triageResult.department && triageResult.emoji && triageResult.message !== undefined) {
        const matchedDepartment = findMatchingDepartment(triageResult.department, availableDepartments)
          || findMatchingDepartment(canonicalDepartmentName(triageResult.department), availableDepartments)
          || findMatchingDepartment('General Medicine', availableDepartments)
          || 'General Medicine';

        triageResult.department = matchedDepartment;
        console.log('✅ Gemini triage success - mapped dept:', triageResult.department);
        return res.json(triageResult);
      } else {
        throw new Error('Invalid response structure from Gemini');
      }
    } catch (geminiError) {
      console.warn('⚠️  Gemini API failed, using local triage:', geminiError.message);
      // Fallback to local triage mapping
      const localResult = localTriage(symptoms, answers);
      localResult.department = findMatchingDepartment(localResult.department, availableDepartments)
        || findMatchingDepartment('General Medicine', availableDepartments)
        || 'General Medicine';
      console.log('✅ Local triage fallback - dept:', localResult.department);
      return res.json(localResult);
    }
  } catch (error) {
    console.error('❌ Triage error:', error.message);
    // Final fallback
    res.json({
      department: 'General',
      emoji: '🩺',
      message: 'Unable to analyze symptoms. Please consult with a general physician.',
      isEmergency: false
    });
  }
});

module.exports = router;
