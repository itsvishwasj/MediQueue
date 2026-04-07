const router = require('express').Router();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Hospital = require('../models/Hospital');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

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

// Functions to extract relevant keywords and do local triage
function localTriage(symptoms) {
  const lowerSymptoms = symptoms.toLowerCase();
  
  for (const [keyword, triageData] of Object.entries(triageMap)) {
    if (lowerSymptoms.includes(keyword)) {
      return {
        ...triageData,
        isEmergency: false
      };
    }
  }
  
  // Default fallback
  return {
    department: 'General',
    emoji: '🩺',
    message: 'Based on your symptoms, we recommend starting with a general physician for comprehensive evaluation.',
    isEmergency: false
  };
}

router.post('/triage', async (req, res) => {
  try {
    const { symptoms } = req.body;
    if (!symptoms) return res.status(400).json({ message: 'Symptoms are required' });

    const availableDepartments = await getAvailableDepartments();
    const departmentOptions = availableDepartments.length
      ? availableDepartments.join(', ')
      : 'General Medicine, Cardiology, Neurology, ENT, Pediatrics';

    try {
      // Use Gemini 1.5 Flash (Fastest model)
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      // Improved prompt for better JSON output
      const prompt = `You are an expert hospital triage AI.
Analyze the following patient symptoms: "${symptoms}"

The hospital has these departments: ${departmentOptions}.
RULES:
1. If the symptoms are highly specific to the nervous system (headache, dizziness, numbness, vision changes, seizures, balance issues), route them to "Neurology".
2. If the symptoms involve ear pain, ear discharge, ear pressure, hearing loss, or severe ear symptoms, route them to "ENT".
3. If the symptoms are mild, vague, common (mild fever, tiredness, minor cold), OR involve multiple unrelated systems, route them to "General Medicine".
4. Use "Cardiology" only for strong heart/chest symptoms.
5. Use "Pediatrics" only when the patient is clearly a child or baby.

Respond ONLY with a valid JSON object (no markdown, no backticks, no extra text) using this exact structure:
{
  "department": "Choose ONE of the available departments above",
  "emoji": "A single relevant emoji (e.g., 🩺, ❤️, 🧠, 👂)",
  "message": "A friendly, 1-2 sentence recommendation explaining why they need this department.",
  "isEmergency": true/false (true if symptoms like severe chest pain, stroke signs, or severe bleeding)
}`;

      const result = await model.generateContent(prompt);
      const responseText = result.response.text().trim();
      
      console.log('📨 Gemini raw response:', responseText);
      
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
      const localResult = localTriage(symptoms);
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