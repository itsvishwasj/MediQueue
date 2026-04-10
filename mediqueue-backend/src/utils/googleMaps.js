function normalizeGoogleMapsLink(value) {
  return typeof value === 'string' ? value.trim() : '';
}

async function resolveGoogleMapsUrl(link) {
  const normalized = normalizeGoogleMapsLink(link);
  if (!normalized) return '';

  if (!/maps\.app\.goo\.gl|goo\.gl/i.test(normalized)) {
    return normalized;
  }

  try {
    const response = await fetch(normalized, { redirect: 'follow' });
    return response.url || normalized;
  } catch (_) {
    return normalized;
  }
}

function parseCoordinatesFromUrl(url) {
  const patterns = [
    /@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/,
    /!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)/,
    /[?&]q=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/,
    /[?&]query=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/,
    /[?&]ll=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)/,
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) {
      return {
        latitude: parseFloat(match[1]),
        longitude: parseFloat(match[2]),
      };
    }
  }

  return null;
}

async function extractCoordinatesFromGoogleMapsLink(link) {
  const normalized = normalizeGoogleMapsLink(link);
  if (!normalized) {
    return { mapsLink: '', location: null };
  }

  const resolvedUrl = await resolveGoogleMapsUrl(normalized);
  const location = parseCoordinatesFromUrl(resolvedUrl);

  return {
    mapsLink: normalized,
    location,
  };
}

module.exports = {
  extractCoordinatesFromGoogleMapsLink,
  normalizeGoogleMapsLink,
};
