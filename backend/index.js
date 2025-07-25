const express = require("express");
const mapbox = require("@mapbox/mapbox-sdk/services/directions");
const gasStations = require("./models/gasStationData"); // Import your gas station data

const app = express();
const PORT = 5001;

// Initialize Mapbox with your API key
const mapboxClient = mapbox({ accessToken: "pk.eyJ1Ijoiam9lbGsxMCIsImEiOiJjbTgwNTZzaGswcjd4MmxzYWQxems0cm51In0.DAjd-NBKKIMsbd-Qrvg1kg" });

app.get("/getStationsAlongRoute", async (req, res) => {
  const { originLat, originLng } = req.query;

  // Validate required coordinates
  if (!originLat || !originLng) {
    return res.status(400).json({ error: "Origin coordinates are required." });
  }

  try {
    // Filter valid fuel stations
    const validStations = gasStations.filter(
      (station) =>
        !isNaN(station.latitude) &&
        !isNaN(station.longitude) &&
        station.latitude >= -90 &&
        station.latitude <= 90 &&
        station.longitude >= -180 &&
        station.longitude <= 180
    );

    console.log("Valid Stations: ", validStations);

    const stationDistances = await Promise.all(
      validStations.map(async (station) => {
        // Calculate road distance for each station using Mapbox Directions API
        try {
          const routeResponse = await mapboxClient
            .getDirections({
              profile: "driving",
              waypoints: [
                { coordinates: [parseFloat(originLng), parseFloat(originLat)] },
                { coordinates: [station.longitude, station.latitude] },
              ],
              geometries: "geojson",
            })
            .send();

          const route = routeResponse.body.routes[0];
          const distance = route.distance / 1000; // Convert meters to km
          return { station, distance };
        } catch (error) {
          console.error(
            `Error calculating distance for station ${station.name}: `,
            error.message
          );
          return null; // Skip stations with errors
        }
      })
    );

    // Remove null entries and duplicate stations, then sort
    const filteredStations = stationDistances
      .filter((entry) => entry && entry.distance <= 10) // Remove nulls and keep within 10 km
      .reduce((unique, entry) => {
        // Add only unique stations based on name
        if (!unique.some((item) => item.station.name === entry.station.name)) {
          unique.push(entry);
        }
        return unique;
      }, [])
      .sort((a, b) => a.distance - b.distance) // Sort by ascending distance
      .slice(0, 10); // Limit to the closest 10 stations

    console.log(
      "Stations within 10 km (unique and sorted): ",
      filteredStations.map((entry) => ({
        name: entry.station.name,
        distance: entry.distance,
      }))
    );

    // Send unique, sorted stations to the frontend
    res.status(200).json(filteredStations.map((entry) => entry.station));
  } catch (error) {
    console.error("Error with Mapbox API: ", error.message);
    res.status(500).json({ error: "Failed to fetch stations." });
  }
});



// Default test route
app.get("/", (req, res) => {
  res.send("Fuel Station Finder Backend is running!");
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
