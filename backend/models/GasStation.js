class GasStation {
  constructor(name, address, latitude, longitude, phone, agentId) {
    this.name = name;
    this.address = address;
    this.latitude = latitude;
    this.longitude = longitude;
    this.phone = phone; // ✅ Changed from "contact" to "phone"
    this.agentId = agentId; // ✅ Changed from "agent_id" to "agentId"
  }
}

module.exports = GasStation;
