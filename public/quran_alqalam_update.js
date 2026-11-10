// Loads public/quran_alqalam_text.json into the ayah collection's textArabic.
//
// The text is the IndoPak text encoded for AlQalam Quran Majeed (the app's
// Quran font), with its spacing errors fixed; no letters differ from the
// source. Run from the project root with mongosh, against the database the
// API reads from:
//
//   mongosh "<connection string>" public/quran_alqalam_update.js
//
// Set COLLECTION to the ayah collection's name first. Ayahs are matched by
// surahNumber + ayahNumber, the fields GET /quran/surahs/{n}/ayahs returns;
// rename them below if the collection stores them differently. Every update
// is checked: the script stops before writing if any ayah has no match.

const COLLECTION = 'quranayahs';

const fs = require('fs');
const rows = JSON.parse(fs.readFileSync('public/quran_alqalam_text.json', 'utf8'));
const ayahs = db.getCollection(COLLECTION);

const counts = {};
ayahs
  .aggregate([{ $group: { _id: { s: '$surahNumber', a: '$ayahNumber' }, n: { $sum: 1 } } }])
  .forEach((g) => (counts[`${g._id.s}:${g._id.a}`] = g.n));
const unmatched = rows.filter((r) => counts[`${r.surahNumber}:${r.ayahNumber}`] !== 1);
if (unmatched.length > 0) {
  print(`${unmatched.length} ayahs have no single match, e.g. ${unmatched[0].verseKey}; nothing written.`);
  quit(1);
}

const result = ayahs.bulkWrite(
  rows.map((r) => ({
    updateOne: {
      filter: { surahNumber: r.surahNumber, ayahNumber: r.ayahNumber },
      update: { $set: { textArabic: r.textArabic } },
    },
  })),
);
print(`matched ${result.matchedCount}, updated ${result.modifiedCount} of ${rows.length} ayahs`);
