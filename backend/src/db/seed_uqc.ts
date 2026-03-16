import { db } from "./db";
import { uqc } from "./schema";

const uqcData = [
  { uqcCode: "BAG", description: "BAGS" },
  { uqcCode: "BAL", description: "BALE" },
  { uqcCode: "BDL", description: "BUNDLES" },
  { uqcCode: "BKL", description: "BUCKLES" },
  { uqcCode: "BOU", description: "BILLIONS OF UNITS" },
  { uqcCode: "BOX", description: "BOX" },
  { uqcCode: "BTL", description: "BOTTLES" },
  { uqcCode: "BUN", description: "BUNCHES" },
  { uqcCode: "CAN", description: "CANS" },
  { uqcCode: "CBM", description: "CUBIC METER" },
  { uqcCode: "CCM", description: "CUBIC CENTIMETER" },
  { uqcCode: "CMS", description: "CENTIMETER" },
  { uqcCode: "CTN", description: "CARTONS" },
  { uqcCode: "DOZ", description: "DOZEN" },
  { uqcCode: "DRM", description: "DRUM" },
  { uqcCode: "GGR", description: "GREAT GROSS" },
  { uqcCode: "GMS", description: "GRAMS" },
  { uqcCode: "GRS", description: "GROSS" },
  { uqcCode: "GYD", description: "GROSS YARDS" },
  { uqcCode: "KGS", description: "KILOGRAMS" },
  { uqcCode: "KLR", description: "KILOLITRE" },
  { uqcCode: "KME", description: "KILOMETRE" },
  { uqcCode: "MLT", description: "MILLILITRE" },
  { uqcCode: "MTR", description: "METERS" },
  { uqcCode: "MTS", description: "METRIC TON" },
  { uqcCode: "NOS", description: "NUMBERS" },
  { uqcCode: "PAC", description: "PACKS" },
  { uqcCode: "PCS", description: "PIECES" },
  { uqcCode: "PRS", description: "PAIRS" },
  { uqcCode: "QTL", description: "QUINTAL" },
  { uqcCode: "ROL", description: "ROLLS" },
  { uqcCode: "SET", description: "SETS" },
  { uqcCode: "SQF", description: "SQUARE FEET" },
  { uqcCode: "SQM", description: "SQUARE METERS" },
  { uqcCode: "SQY", description: "SQUARE YARDS" },
  { uqcCode: "TBS", description: "TABLETS" },
  { uqcCode: "TGM", description: "TEN GRAMS" },
  { uqcCode: "THD", description: "THOUSANDS" },
  { uqcCode: "TON", description: "TONNES" },
  { uqcCode: "TUB", description: "TUBES" },
  { uqcCode: "UGS", description: "US GALLONS" },
  { uqcCode: "UNT", description: "UNITS" },
  { uqcCode: "YDS", description: "YARDS" },
  { uqcCode: "OTH", description: "OTHERS" },
];

async function seed() {
  console.log("Seeding UQC data...");
  try {
    for (const item of uqcData) {
      await db.insert(uqc).values(item).onConflictDoNothing();
    }
    console.log("UQC data seeded successfully!");
  } catch (error) {
    console.error("Error seeding UQC data:", error);
  } finally {
    process.exit(0);
  }
}

seed();
