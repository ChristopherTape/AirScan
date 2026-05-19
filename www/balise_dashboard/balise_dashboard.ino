/**
 * ============================================================
 *  BALISE AIRSCAN - ESP32 — DASHBOARD WEB LOCAL
 *  Capteurs : MQ7 (CO), MQ135 (CO2/NH3), NEO-6M (GPS), BMP180
 *
 *  UTILISATION :
 *    1. Flasher ce code sur l'ESP32
 *    2. Ouvrir le moniteur série (115200 baud)
 *    3. Récupérer l'IP affichée (ex: 192.168.1.42)
 *    4. Ouvrir http://192.168.1.42 dans un navigateur
 *    La page se rafraîchit automatiquement toutes les 5 secondes.
 *
 *  DÉPENDANCES (Arduino Library Manager) :
 *    - TinyGPSPlus              by Mikal Hart
 *    - Adafruit BMP085 Unified  (compatible BMP180)
 *    - Adafruit Unified Sensor
 *    - ArduinoJson              by Benoît Blanchon
 *    (WebServer est incluse dans l'ESP32 Arduino Core)
 *
 *  CÂBLAGE :
 *    MQ7   : AOUT → pont 10kΩ/10kΩ → GPIO34
 *    MQ135 : AOUT → pont 10kΩ/10kΩ → GPIO35
 *    NEO-6M: TX → GPIO16 (RX2), RX → GPIO17 (TX2)
 *    BMP180: SDA → GPIO21, SCL → GPIO22
 * ============================================================
 */

#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <TinyGPSPlus.h>
#include <HardwareSerial.h>
#include <Wire.h>
#include <Adafruit_BMP085.h>

// ─── CONFIGURATION RÉSEAU ───────────────────────────────────
const char* WIFI_SSID     = "Alienware";
const char* WIFI_PASSWORD = "Alien2026";

// ─── IDENTIFIANT ────────────────────────────────────────────
const char* BALISE_ID   = "BALISE_01";
const char* ZONE_CAMPUS = "Zone_A";

// ─── INTERVALLE DE MESURE ───────────────────────────────────
const unsigned long MESURE_INTERVAL_MS = 5000;  // 5 secondes

// ─── BROCHES ADC ────────────────────────────────────────────
#define PIN_MQ7    34
#define PIN_MQ135  35

// ─── GPS ────────────────────────────────────────────────────
#define GPS_BAUD 9600
HardwareSerial gpsSerial(2);
TinyGPSPlus    gps;

// ─── BMP180 ─────────────────────────────────────────────────
Adafruit_BMP085 bmp;
bool bmpOk = false;

// ─── SERVEUR WEB ────────────────────────────────────────────
WebServer server(80);

// ─── CALIBRATION MQ ─────────────────────────────────────────
const float MQ7_R0       = 10.0;
const float MQ7_RL       = 10.0;
const float MQ7_A        = 99.042;
const float MQ7_B        = -1.518;

const float MQ135_R0     = 76.63;
const float MQ135_RL     = 10.0;
const float MQ135_A_CO2  = 110.47;
const float MQ135_B_CO2  = -2.862;
const float MQ135_A_NH3  = 102.2;
const float MQ135_B_NH3  = -2.473;

// ─── ÉTAT GLOBAL (dernière mesure) ──────────────────────────
struct Mesure {
  int   rawMQ7;
  int   rawMQ135;
  float co_ppm;
  float co2_ppm;
  float nh3_ppm;
  float pression_hPa;
  float altitude_m;
  float latitude;
  float longitude;
  int   gps_satellites;
  bool  gps_valide;
  bool  bmp_ok;
  unsigned long timestamp_ms;   // millis() au moment de la mesure
} derniere;

unsigned long lastMesureTime = 0;
bool prechauffageOk = false;

// ══════════════════════════════════════════════════════════════
//  LECTURES CAPTEURS
// ══════════════════════════════════════════════════════════════

float mqReadResistance(int pin, float rl) {
  // Moyenne 5 lectures (ADC ESP32 est bruyant)
  long sum = 0;
  for (int i = 0; i < 5; i++) { sum += analogRead(pin); delay(2); }
  int raw = sum / 5;
  if (raw <= 0) raw = 1;

  // Tension sur ADC (apres pont diviseur 10k/10k -> Vadc = Vmq_aout / 2)
  float vadc = (float)raw * 3.3f / 4095.0f;
  float vmq  = vadc * 2.0f;   // tension reelle sortie capteur MQ (avant pont)

  // Rs = RL * (Vcc - Vmq) / Vmq  avec Vcc=5V
  if (vmq < 0.01f) vmq = 0.01f;
  return rl * (5.0f - vmq) / vmq;
}

float mqConvertPPM(float rs, float r0, float A, float B) {
  float ratio = rs / r0;
  if (ratio <= 0) return 0;
  return A * pow(ratio, B);
}

float readMQ7_CO() {
  float sum = 0;
  for (int i = 0; i < 10; i++) { sum += mqReadResistance(PIN_MQ7, MQ7_RL); delay(5); }
  return max(0.0f, mqConvertPPM(sum / 10.0f, MQ7_R0, MQ7_A, MQ7_B));
}

void readMQ135(float &co2, float &nh3) {
  float sum = 0;
  for (int i = 0; i < 10; i++) { sum += mqReadResistance(PIN_MQ135, MQ135_RL); delay(5); }
  float rs = sum / 10.0f;
  co2 = max(350.0f, mqConvertPPM(rs, MQ135_R0, MQ135_A_CO2, MQ135_B_CO2));
  nh3 = max(0.0f,   mqConvertPPM(rs, MQ135_R0, MQ135_A_NH3, MQ135_B_NH3));
}

void faireMesure() {
  // GPS
  unsigned long t = millis();
  while (millis() - t < 1000) {
    while (gpsSerial.available()) gps.encode(gpsSerial.read());
  }
  derniere.gps_valide    = gps.location.isValid() && gps.location.age() < 5000;
  derniere.latitude      = derniere.gps_valide ? gps.location.lat() : 0.0;
  derniere.longitude     = derniere.gps_valide ? gps.location.lng() : 0.0;
  derniere.gps_satellites = gps.satellites.isValid() ? gps.satellites.value() : 0;

  // MQ
  derniere.rawMQ7   = analogRead(PIN_MQ7);
  derniere.rawMQ135 = analogRead(PIN_MQ135);
  derniere.co_ppm   = readMQ7_CO();
  readMQ135(derniere.co2_ppm, derniere.nh3_ppm);

  // BMP180 — retenter init si premier echec
  if (!bmpOk) bmpOk = bmp.begin();
  derniere.bmp_ok = bmpOk;
  if (bmpOk) {
    derniere.pression_hPa = bmp.readPressure() / 100.0f;
    derniere.altitude_m   = bmp.readAltitude(1013.25f);
  } else {
    derniere.pression_hPa = -1;
    derniere.altitude_m   = -1;
  }

  derniere.timestamp_ms = millis();

  Serial.println("[Mesure] ─────────────────────────────");
  Serial.printf("  ADC bruts  : MQ7=%d  MQ135=%d\n", derniere.rawMQ7, derniere.rawMQ135);
  Serial.printf("  CO         = %.2f ppm\n", derniere.co_ppm);
  Serial.printf("  CO2        = %.1f ppm\n", derniere.co2_ppm);
  Serial.printf("  NH3        = %.2f ppm\n", derniere.nh3_ppm);
  if (derniere.bmp_ok)
    Serial.printf("  Pression   = %.2f hPa  Altitude = %.1f m\n", derniere.pression_hPa, derniere.altitude_m);
  else
    Serial.println("  BMP180     : non detecte");
  if (derniere.gps_valide)
    Serial.printf("  GPS        = %.6f, %.6f  (%d sats)\n", derniere.latitude, derniere.longitude, derniere.gps_satellites);
  else
    Serial.println("  GPS        : pas de fix");
}

// ══════════════════════════════════════════════════════════════
//  CALCUL AQI
// ══════════════════════════════════════════════════════════════
float calculeAQI() {
  auto si = [](float v, float s) { return min(100.0f, (v / s) * 100.0f); };
  return min(100.0f, si(derniere.co_ppm, 100.0f) * 0.5f
                   + si(derniere.co2_ppm, 2500.0f) * 0.3f
                   + si(derniere.nh3_ppm, 25.0f) * 0.2f);
}

const char* categorieAQI(float aqi) {
  if (aqi < 20) return "Bon";
  if (aqi < 40) return "Modere";
  if (aqi < 60) return "Mauvais";
  if (aqi < 80) return "Tres mauvais";
  return "Dangereux";
}

// ══════════════════════════════════════════════════════════════
//  PAGE HTML
// ══════════════════════════════════════════════════════════════

// La page HTML est stockée en mémoire flash (PROGMEM) pour économiser la RAM
const char PAGE_HTML[] PROGMEM = R"rawhtml(
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>AirScan Dashboard</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:system-ui,sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;padding:16px}
  h1{text-align:center;font-size:1.4rem;font-weight:600;color:#f8fafc;margin-bottom:4px}
  .subtitle{text-align:center;font-size:.8rem;color:#94a3b8;margin-bottom:20px}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px}
  .card{background:#1e293b;border-radius:14px;padding:18px;border:1px solid #334155}
  .card-title{font-size:.7rem;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:#94a3b8;margin-bottom:14px;display:flex;align-items:center;gap:8px}
  .dot{width:8px;height:8px;border-radius:50%;display:inline-block}
  .dot-ok{background:#22c55e} .dot-warn{background:#f59e0b} .dot-err{background:#ef4444} .dot-off{background:#475569}
  .metric{display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid #334155}
  .metric:last-child{border-bottom:none}
  .metric-label{font-size:.82rem;color:#94a3b8}
  .metric-val{font-size:1rem;font-weight:600;color:#f1f5f9}
  .metric-unit{font-size:.72rem;color:#64748b;margin-left:3px}
  .aqi-bar-wrap{margin-top:14px}
  .aqi-bar-bg{background:#0f172a;border-radius:99px;height:10px;overflow:hidden;border:1px solid #334155}
  .aqi-bar-fill{height:100%;border-radius:99px;transition:width .6s ease,background .6s}
  .aqi-label{display:flex;justify-content:space-between;margin-top:6px;font-size:.75rem;color:#94a3b8}
  .badge{display:inline-block;padding:2px 10px;border-radius:99px;font-size:.75rem;font-weight:600}
  .badge-ok{background:#14532d;color:#86efac}
  .badge-warn{background:#713f12;color:#fcd34d}
  .badge-err{background:#7f1d1d;color:#fca5a5}
  .badge-off{background:#1e293b;color:#64748b;border:1px solid #334155}
  .gps-coords{font-size:.78rem;font-family:monospace;color:#7dd3fc;word-break:break-all;margin-top:6px;line-height:1.6}
  .gps-link{display:block;margin-top:8px;font-size:.75rem;color:#38bdf8;text-decoration:none}
  .gps-link:hover{text-decoration:underline}
  .raw{font-size:.7rem;color:#475569;margin-top:4px}
  .status-bar{text-align:center;font-size:.72rem;color:#475569;margin-top:18px}
  #refresh-circle{display:inline-block;width:8px;height:8px;border-radius:50%;background:#22c55e;margin-right:5px;animation:pulse 2s infinite}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
</style>
</head>
<body>

<h1>&#x1F4E1; AirScan Dashboard</h1>
<div class="subtitle" id="balise-info">Chargement...</div>

<div class="grid">

  <!-- ── Qualité de l'air ── -->
  <div class="card">
    <div class="card-title"><span class="dot dot-ok" id="dot-air"></span>Qualité de l'air</div>
    <div class="metric">
      <span class="metric-label">CO (monoxyde de carbone)</span>
      <span><span class="metric-val" id="co">—</span><span class="metric-unit">ppm</span></span>
    </div>
    <div class="metric">
      <span class="metric-label">CO₂ (dioxyde de carbone)</span>
      <span><span class="metric-val" id="co2">—</span><span class="metric-unit">ppm</span></span>
    </div>
    <div class="metric">
      <span class="metric-label">NH₃ (ammoniac)</span>
      <span><span class="metric-val" id="nh3">—</span><span class="metric-unit">ppm</span></span>
    </div>
    <div class="aqi-bar-wrap">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px">
        <span style="font-size:.78rem;color:#94a3b8">AQI</span>
        <span><span class="metric-val" id="aqi-val">—</span><span class="metric-unit">/100</span>
        &nbsp;<span class="badge badge-off" id="aqi-cat">—</span></span>
      </div>
      <div class="aqi-bar-bg"><div class="aqi-bar-fill" id="aqi-bar" style="width:0%;background:#22c55e"></div></div>
      <div class="aqi-label"><span>Bon</span><span>Modéré</span><span>Mauvais</span><span>Dangereux</span></div>
    </div>
  </div>

  <!-- ── Capteurs MQ ── -->
  <div class="card">
    <div class="card-title"><span class="dot dot-off" id="dot-mq"></span>Capteurs MQ</div>
    <div class="metric">
      <span class="metric-label">MQ7 — État</span>
      <span class="badge badge-off" id="mq7-etat">—</span>
    </div>
    <div class="metric">
      <span class="metric-label">MQ7 — ADC brut</span>
      <span><span class="metric-val" id="mq7-raw">—</span><span class="metric-unit">/4095</span></span>
    </div>
    <div class="metric">
      <span class="metric-label">MQ135 — État</span>
      <span class="badge badge-off" id="mq135-etat">—</span>
    </div>
    <div class="metric">
      <span class="metric-label">MQ135 — ADC brut</span>
      <span><span class="metric-val" id="mq135-raw">—</span><span class="metric-unit">/4095</span></span>
    </div>
  </div>

  <!-- ── Pression / Altitude ── -->
  <div class="card">
    <div class="card-title"><span class="dot dot-off" id="dot-bmp"></span>Pression · Altitude</div>
    <div class="metric">
      <span class="metric-label">BMP180 — État</span>
      <span class="badge badge-off" id="bmp-etat">—</span>
    </div>
    <div class="metric">
      <span class="metric-label">Pression atmosphérique</span>
      <span><span class="metric-val" id="pression">—</span><span class="metric-unit">hPa</span></span>
    </div>
    <div class="metric">
      <span class="metric-label">Altitude estimée</span>
      <span><span class="metric-val" id="altitude">—</span><span class="metric-unit">m</span></span>
    </div>
  </div>

  <!-- ── GPS ── -->
  <div class="card">
    <div class="card-title"><span class="dot dot-off" id="dot-gps"></span>GPS — NEO-6M</div>
    <div class="metric">
      <span class="metric-label">Fix GPS</span>
      <span class="badge badge-off" id="gps-etat">—</span>
    </div>
    <div class="metric">
      <span class="metric-label">Satellites visibles</span>
      <span class="metric-val" id="gps-sat">—</span>
    </div>
    <div class="gps-coords" id="gps-coords">En attente de fix...</div>
    <a class="gps-link" id="gps-link" href="#" target="_blank" style="display:none">
      &#x1F5FA; Voir sur Google Maps
    </a>
  </div>

</div>

<div class="status-bar">
  <span id="refresh-circle"></span>
  Mise à jour toutes les 5s &nbsp;·&nbsp; Uptime : <span id="uptime">—</span>
  &nbsp;·&nbsp; Dernière mesure : <span id="last-update">—</span>
</div>

<script>
function aq(id){return document.getElementById(id)}

function fmtUptime(ms){
  let s=Math.floor(ms/1000), m=Math.floor(s/60), h=Math.floor(m/60);
  s%=60; m%=60;
  return h>0 ? h+'h '+m+'m' : m>0 ? m+'m '+s+'s' : s+'s';
}

function aqiColor(v){
  if(v<20) return '#22c55e';
  if(v<40) return '#84cc16';
  if(v<60) return '#f59e0b';
  if(v<80) return '#f97316';
  return '#ef4444';
}

function badgeClass(ok){return ok ? 'badge badge-ok' : 'badge badge-err';}

function dotColor(el, ok){
  el.className = 'dot ' + (ok ? 'dot-ok' : 'dot-err');
}

async function refresh(){
  try {
    const r = await fetch('/data');
    if(!r.ok) throw new Error('HTTP '+r.status);
    const d = await r.json();

    // En-tête
    aq('balise-info').textContent = d.balise_id + ' — ' + d.zone;

    // Qualité air
    aq('co').textContent   = d.co_ppm.toFixed(1);
    aq('co2').textContent  = d.co2_ppm.toFixed(0);
    aq('nh3').textContent  = d.nh3_ppm.toFixed(1);
    aq('aqi-val').textContent = d.aqi.toFixed(1);
    aq('aqi-cat').textContent = d.aqi_cat;
    aq('aqi-bar').style.width = d.aqi + '%';
    aq('aqi-bar').style.background = aqiColor(d.aqi);
    aq('aqi-cat').className = 'badge ' +
      (d.aqi<20?'badge-ok': d.aqi<60?'badge-warn':'badge-err');
    dotColor(aq('dot-air'), d.aqi < 60);

    // MQ7
    let mq7ok = d.mq7_raw > 100 && d.mq7_raw < 4090;
    aq('mq7-raw').textContent  = d.mq7_raw;
    aq('mq7-etat').textContent  = mq7ok ? 'OK' : (d.mq7_raw<=100 ? 'Court-circuit?' : 'Saturé?');
    aq('mq7-etat').className    = badgeClass(mq7ok);
    // MQ135
    let mq135ok = d.mq135_raw > 100 && d.mq135_raw < 4090;
    aq('mq135-raw').textContent = d.mq135_raw;
    aq('mq135-etat').textContent = mq135ok ? 'OK' : (d.mq135_raw<=100 ? 'Court-circuit?' : 'Saturé?');
    aq('mq135-etat').className   = badgeClass(mq135ok);
    dotColor(aq('dot-mq'), mq7ok && mq135ok);

    // BMP180
    aq('bmp-etat').textContent = d.bmp_ok ? 'Détecté' : 'Non détecté';
    aq('bmp-etat').className   = badgeClass(d.bmp_ok);
    dotColor(aq('dot-bmp'), d.bmp_ok);
    aq('pression').textContent = d.bmp_ok ? d.pression.toFixed(1) : '—';
    aq('altitude').textContent = d.bmp_ok ? d.altitude.toFixed(1) : '—';

    // GPS
    aq('gps-etat').textContent = d.gps_ok ? 'Fix acquis' : 'Pas de fix';
    aq('gps-etat').className   = badgeClass(d.gps_ok);
    dotColor(aq('dot-gps'), d.gps_ok);
    aq('gps-sat').textContent  = d.gps_sat;
    if(d.gps_ok){
      aq('gps-coords').innerHTML =
        'Latitude &nbsp;: <b>'+d.lat.toFixed(6)+'</b><br>' +
        'Longitude : <b>'+d.lon.toFixed(6)+'</b>';
      let link = aq('gps-link');
      link.href = 'https://www.google.com/maps?q='+d.lat+','+d.lon;
      link.style.display='block';
    } else {
      aq('gps-coords').textContent = 'En attente de fix...';
      aq('gps-link').style.display='none';
    }

    // Bas de page
    aq('uptime').textContent     = fmtUptime(d.uptime_ms);
    aq('last-update').textContent = new Date().toLocaleTimeString();

  } catch(e){
    aq('balise-info').textContent = 'Erreur de connexion à l\'ESP32';
    console.error(e);
  }
}

refresh();
setInterval(refresh, 5000);
</script>
</body>
</html>
)rawhtml";

// ══════════════════════════════════════════════════════════════
//  ROUTES WEB
// ══════════════════════════════════════════════════════════════

// GET /  → page HTML
void handleRoot() {
  server.send_P(200, "text/html", PAGE_HTML);
}

// GET /data  → JSON avec toutes les mesures (appelé par le JS toutes les 5s)
void handleData() {
  float aqi = calculeAQI();

  StaticJsonDocument<512> doc;
  doc["balise_id"]  = BALISE_ID;
  doc["zone"]       = ZONE_CAMPUS;
  doc["uptime_ms"]  = millis();

  // Qualité air
  doc["co_ppm"]     = round(derniere.co_ppm * 10) / 10.0;
  doc["co2_ppm"]    = round(derniere.co2_ppm);
  doc["nh3_ppm"]    = round(derniere.nh3_ppm * 10) / 10.0;
  doc["aqi"]        = round(aqi * 10) / 10.0;
  doc["aqi_cat"]    = categorieAQI(aqi);

  // MQ bruts
  doc["mq7_raw"]    = derniere.rawMQ7;
  doc["mq135_raw"]  = derniere.rawMQ135;

  // BMP180
  doc["bmp_ok"]     = derniere.bmp_ok;
  doc["pression"]   = round(derniere.pression_hPa * 10) / 10.0;
  doc["altitude"]   = round(derniere.altitude_m * 10) / 10.0;

  // GPS
  doc["gps_ok"]     = derniere.gps_valide;
  doc["gps_sat"]    = derniere.gps_satellites;
  doc["lat"]        = derniere.latitude;
  doc["lon"]        = derniere.longitude;

  String json;
  serializeJson(doc, json);
  server.send(200, "application/json", json);
}

// ══════════════════════════════════════════════════════════════
//  CONNEXION WIFI (avec retry infini jusqu'à connexion)
// ══════════════════════════════════════════════════════════════
void connectWiFi() {

  const char* ap_ssid = "AirScan_ESP32";
  const char* ap_password = "12345678"; // min 8 caracteres

  WiFi.mode(WIFI_AP);

  bool ok = WiFi.softAP(ap_ssid, ap_password);

  if (ok) {
    Serial.println("\n[WiFi] Point d'acces demarre !");
    Serial.printf("[WiFi] SSID : %s\n", ap_ssid);
    Serial.printf("[WiFi] Password : %s\n", ap_password);
    Serial.printf("[WiFi] Ouvre : http://%s\n",
                  WiFi.softAPIP().toString().c_str());
  } else {
    Serial.println("[WiFi] Echec creation point d'acces");
  }
}

// ══════════════════════════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(800);
  Serial.println("\n===== BALISE AIRSCAN — Dashboard Web =====");

  // ADC
  analogSetAttenuation(ADC_11db);
  analogSetWidth(12);

  // GPS
  gpsSerial.begin(GPS_BAUD, SERIAL_8N1, 16, 17);
  Serial.println("[GPS] UART2 init (RX=16, TX=17)");

  // BMP180 — scan I2C puis init
  Wire.begin(21, 22);
  delay(100);

  // Scan I2C pour diagnostic (BMP180 doit repondre a 0x77)
  Serial.println("[I2C] Scan du bus...");
  bool trouve = false;
  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      Serial.printf("[I2C] Peripherique trouve a 0x%02X", addr);
      if (addr == 0x77) trouve = true;
    }
  }
  if (!trouve) Serial.println("[I2C] BMP180 (0x77) NON trouve — verifie SDA=GPIO21 SCL=GPIO22");

  bmpOk = bmp.begin();
  Serial.println(bmpOk ? "[BMP180] Init OK" : "[BMP180] Init ECHEC");

  // WiFi
  connectWiFi();

  // Routes web
  server.on("/",     handleRoot);
  server.on("/data", handleData);
  server.begin();
  Serial.println("[Web] Serveur HTTP demarre sur port 80");

  // Préchauffage MQ
  Serial.println("[MQ] Prechauffage 30 secondes...");
  for (int i = 30; i > 0; i--) {
    // Continuer à lire le GPS pendant le préchauffage
    while (gpsSerial.available()) gps.encode(gpsSerial.read());
    server.handleClient();  // rester disponible sur le web
    Serial.printf("  %d s restantes\r", i);
    delay(1000);
  }
  Serial.println("\n[MQ] Prechauffage termine");
  prechauffageOk = true;

  // Première mesure immédiate
  faireMesure();

  Serial.println("===== Balise prete =====");
  Serial.printf(">>> Ouvre http://%s dans ton navigateur\n", WiFi.localIP().toString().c_str());
}

// ══════════════════════════════════════════════════════════════
//  LOOP
// ══════════════════════════════════════════════════════════════
void loop() {
  // Traiter les requêtes web en priorité
  server.handleClient();

  // GPS en continu (non-bloquant)
  while (gpsSerial.available()) {
    gps.encode(gpsSerial.read());
  }
  if (gps.location.isValid() && gps.location.age() < 5000) {
    derniere.gps_valide    = true;
    derniere.latitude      = gps.location.lat();
    derniere.longitude     = gps.location.lng();
    derniere.gps_satellites = gps.satellites.isValid() ? gps.satellites.value() : 0;
  }

  // Mesure périodique
  if (millis() - lastMesureTime >= MESURE_INTERVAL_MS) {
    lastMesureTime = millis();
    faireMesure();
  }
}
