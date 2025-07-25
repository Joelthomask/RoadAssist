const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const gasStations = require("./models/gasStationData");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const uploadGasStations = async () => {
  try {
    for (const station of gasStations) {
      if (!station.name || !station.phone || !station.agentId) {
        console.error("❌ Missing data: ", station);
        continue; // Skip invalid entries
      }

      const stationRef = db.collection("fuelStations").doc();
      await stationRef.set({
        name: station.name,
        pump_location: new admin.firestore.GeoPoint(station.latitude, station.longitude),
        phone: station.phone,
        isAvailable: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const agentRef = stationRef.collection("agents").doc(station.agentId);
      await agentRef.set({
        name: "Default Agent",
        phone: station.phone,
        lastKnownLocation: new admin.firestore.GeoPoint(station.latitude, station.longitude),
      });

      console.log(`✅ Uploaded: ${station.name}`);
    }
    console.log("🚀 All stations uploaded successfully!");
  } catch (error) {
    console.error("❌ Error uploading gas stations: ", error);
  }
};

uploadGasStations();
