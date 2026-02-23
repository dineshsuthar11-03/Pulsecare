const fs = require('fs');
const path = require('path');

let medicines = [];
let ingredientIndex = new Map();
let initialized = false;

function normalizeText(value) {
  return (value || '')
    .toString()
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function mapRowToMedicine(row) {
  const id = row.id != null ? String(row.id).trim() : '';
  const name = row.name != null ? String(row.name).trim() : '';
  const manufacturer = row.manufacturer_name != null
    ? String(row.manufacturer_name).trim()
    : null;
  const packSize = row.pack_size_label != null
    ? String(row.pack_size_label).trim()
    : null;

  const saltComposition = row.salt_composition != null
    ? String(row.salt_composition).trim()
    : '';

  const activeIngredients = saltComposition
    .split('+')
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

  const sideEffectsRaw = row.side_effects != null
    ? String(row.side_effects).trim()
    : '';

  const adverseReactions = sideEffectsRaw
    .split(',')
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

  const description = row.medicine_desc != null
    ? String(row.medicine_desc).trim()
    : '';

  let purpose = null;
  if (description) {
    const firstPeriodIndex = description.indexOf('.');
    if (firstPeriodIndex > 0 && firstPeriodIndex < 260) {
      purpose = description.slice(0, firstPeriodIndex + 1).trim();
    } else {
      purpose = description.length > 260
        ? description.slice(0, 257).trimEnd() + '...'
        : description;
    }
  }

  return {
    id,
    brandName: name,
    genericName: name,
    activeIngredients,
    dosageForm: packSize,
    route: null,
    purpose,
    warnings: [],
    adverseReactions,
    dosageAndAdministration: description || null,
    maximumDailyDose: null,
    manufacturer,
  };
}

function buildIndexes() {
  ingredientIndex = new Map();
  for (const med of medicines) {
    if (!Array.isArray(med.activeIngredients)) continue;
    for (const ingredient of med.activeIngredients) {
      const key = normalizeText(ingredient);
      if (!key) continue;
      if (!ingredientIndex.has(key)) {
        ingredientIndex.set(key, []);
      }
      ingredientIndex.get(key).push(med);
    }
  }
}

function loadMedicinesIfNeeded() {
  if (initialized) return;

  try {
    // Support multiple possible locations so this works both locally
    // and when deployed (e.g. Railway with different app roots).
    const candidatePaths = [];

    // 1) Env override if explicitly provided
    if (process.env.MEDICINE_CSV_PATH) {
      candidatePaths.push(process.env.MEDICINE_CSV_PATH);
    }

    // 2) Project root: ../../updated_indian_medicine_data.csv
    candidatePaths.push(
      path.join(__dirname, '..', '..', 'updated_indian_medicine_data.csv'),
    );

    // 3) Backend root: ../updated_indian_medicine_data.csv
    candidatePaths.push(
      path.join(__dirname, '..', 'updated_indian_medicine_data.csv'),
    );

    let csvPath = null;
    for (const candidate of candidatePaths) {
      try {
        if (candidate && fs.existsSync(candidate)) {
          csvPath = candidate;
          break;
        }
      } catch (_) {
        // ignore and try next
      }
    }

    if (!csvPath) {
      console.error(
        '[MedicineService] Could not locate updated_indian_medicine_data.csv. Checked paths:',
        candidatePaths,
      );
      medicines = [];
      ingredientIndex = new Map();
      initialized = true;
      return;
    }

    const fileContent = fs.readFileSync(csvPath, 'utf8');

    const lines = fileContent.split(/\r?\n/);
    const headerLine = lines.shift();

    if (!headerLine) {
      console.error('[MedicineService] CSV header is missing.');
      medicines = [];
      initialized = true;
      return;
    }

    const headers = headerLine.split(',').map((h) => h.trim());

    medicines = lines
      .filter((line) => line && line.trim().length > 0)
      .map((line) => {
        const columns = [];
        let current = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i += 1) {
          const char = line[i];

          if (char === '"') {
            const nextChar = line[i + 1];
            if (nextChar === '"') {
              current += '"';
              i += 1;
            } else {
              inQuotes = !inQuotes;
            }
          } else if (char === ',' && !inQuotes) {
            columns.push(current);
            current = '';
          } else {
            current += char;
          }
        }
        columns.push(current);

        const row = {};
        headers.forEach((header, index) => {
          row[header] = columns[index];
        });

        return mapRowToMedicine(row);
      });

    buildIndexes();
    initialized = true;
    console.log(`[MedicineService] Loaded ${medicines.length} medicines from CSV dataset.`);
  } catch (err) {
    console.error('[MedicineService] Failed to load medicines CSV:', err.message || err);
    medicines = [];
    ingredientIndex = new Map();
    initialized = true;
  }
}

function searchMedicines(query, limit = 20) {
  loadMedicinesIfNeeded();

  const normalizedQuery = normalizeText(query);
  if (!normalizedQuery) return [];

  const results = [];

  for (const med of medicines) {
    if (results.length >= limit) break;

    const name = normalizeText(med.brandName) || normalizeText(med.genericName);
    if (name.includes(normalizedQuery)) {
      results.push(med);
      continue;
    }

    if (Array.isArray(med.activeIngredients)) {
      const hasMatch = med.activeIngredients.some((ing) =>
        normalizeText(ing).includes(normalizedQuery),
      );
      if (hasMatch) {
        results.push(med);
      }
    }
  }

  return results;
}

function getAlternatives(activeIngredient, excludeId, limit = 5) {
  loadMedicinesIfNeeded();

  const key = normalizeText(activeIngredient);
  if (!key || !ingredientIndex.has(key)) return [];

  const all = ingredientIndex.get(key) || [];
  const normalizedExcludeId = excludeId != null ? String(excludeId).trim() : null;

  const results = [];
  for (const med of all) {
    if (results.length >= limit) break;
    if (normalizedExcludeId && med.id === normalizedExcludeId) continue;
    results.push(med);
  }

  return results;
}

module.exports = {
  searchMedicines,
  getAlternatives,
};
