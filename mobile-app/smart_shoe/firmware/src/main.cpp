#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include "MAX30105.h"
#include "config.h"
#include "gyro.h"

MAX30105 particleSensor;
WebServer server(80);

const float SPO2_SMOOTHING_ALPHA = 0.18f;

// Circular buffers for IR and RED signals
int32_t irBuffer[BUFFER_SIZE];
int32_t redBuffer[BUFFER_SIZE];
float irFiltered[BUFFER_SIZE];
float redFiltered[BUFFER_SIZE];
int bufferIndex = 0;

// SpO2 calculation
float spo2 = 0.0f;
bool spo2Initialized = false;

// Latest values exposed over WiFi
uint32_t latestTime = 0;
int32_t latestIr = 0;
MotionData latestMotion = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};

// IIR Low-pass filter implementation
float iirFilter(float newValue, float prevFiltered) {
    return FILTER_ALPHA * newValue + (1.0f - FILTER_ALPHA) * prevFiltered;
}

// Calculate SpO2 using ratio of AC/DC components
void calculateSpO2() {
    float irAC = 0, irDC = 0, redAC = 0, redDC = 0;

    for (int i = 0; i < BUFFER_SIZE; i++) {
        irDC += irFiltered[i];
        redDC += redFiltered[i];
    }
    irDC /= BUFFER_SIZE;
    redDC /= BUFFER_SIZE;

    if (irDC <= 0.0f || redDC <= 0.0f) {
        return;
    }

    for (int i = 0; i < BUFFER_SIZE; i++) {
        irAC += (irFiltered[i] - irDC) * (irFiltered[i] - irDC);
        redAC += (redFiltered[i] - redDC) * (redFiltered[i] - redDC);
    }

    if (irAC <= 0.0f) {
        return;
    }

    float ratio = (redAC / redDC) / (irAC / irDC);
    float rawSpO2 = 110.0f - 25.0f * ratio;  // Empirical formula
    rawSpO2 = constrain(rawSpO2, 70.0f, 100.0f);  // Clamp to valid range

    if (!spo2Initialized) {
        spo2 = rawSpO2;
        spo2Initialized = true;
    } else {
        spo2 = (SPO2_SMOOTHING_ALPHA * rawSpO2) + ((1.0f - SPO2_SMOOTHING_ALPHA) * spo2);
    }
}

String buildJsonData() {
    String json = "{";
    json += "\"time_ms\":" + String(latestTime);
    json += ",\"spo2\":" + String(spo2, 1);
    json += ",\"ir\":" + String(latestIr);
    json += ",\"motion_level\":" + String(latestMotion.motionLevel, 1);
    json += "}";
    return json;
}

void handleDataRequest() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", buildJsonData());
}

void handleRootRequest() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "text/plain", "Smart Shoe sensor server. Use /data for JSON.");
}

void setupWiFi() {
    WiFi.disconnect(true, true);
    delay(500);
    WiFi.mode(WIFI_AP);
    WiFi.setSleep(false);
    WiFi.setTxPower(WIFI_POWER_8_5dBm);

#if WIFI_ENABLE_AP
    IPAddress apIp(WIFI_AP_IP);
    IPAddress apGateway(WIFI_AP_GATEWAY);
    IPAddress apSubnet(WIFI_AP_SUBNET);

    WiFi.softAPConfig(apIp, apGateway, apSubnet);

    if (WiFi.softAP(WIFI_AP_SSID, WIFI_AP_PASSWORD)) {
        Serial.print("AP SSID: ");
        Serial.println(WIFI_AP_SSID);
        Serial.print("API: http://");
        Serial.print(WiFi.softAPIP());
        Serial.println("/data");
    } else {
        Serial.println("ERROR: WiFi AP failed");
    }
#endif

    server.on("/", HTTP_GET, handleRootRequest);
    server.on("/data", HTTP_GET, handleDataRequest);
    server.begin();
}

void setup() {
    Serial.begin(115200);
    delay(1000);

    setupWiFi();

    Wire.begin(8, 9);  // SDA=8, SCL=9 for Seeed XIAO ESP32-C3
    delay(1000);

    if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
        Serial.println("ERROR: MAX30102 not found!");
        while (1);
    }

    particleSensor.setup();
    // Toe placement needs more light than a fingertip, but too much saturates the ADC.
    // Try 0x3F first; lower to 0x2F if IR still saturates, raise to 0x4F if signal is weak.
    particleSensor.setPulseAmplitudeRed(0x3F);
    particleSensor.setPulseAmplitudeIR(0x3F);

    gyroBegin();

    Serial.println("Time(ms),SpO2(%),IR,MotionLevel(0-100)");
}

void loop() {
    static uint32_t lastPrintTime = 0;
    static int sampleCount = 0;

    server.handleClient();

    // Read raw values from sensor
    int32_t irValue = particleSensor.getIR();
    int32_t redValue = particleSensor.getRed();

    // Store in circular buffer
    irBuffer[bufferIndex] = irValue;
    redBuffer[bufferIndex] = redValue;

    // Apply IIR low-pass filter
    static float lastIrFiltered = irValue;
    static float lastRedFiltered = redValue;
    irFiltered[bufferIndex] = iirFilter((float)irValue, lastIrFiltered);
    redFiltered[bufferIndex] = iirFilter((float)redValue, lastRedFiltered);
    lastIrFiltered = irFiltered[bufferIndex];
    lastRedFiltered = redFiltered[bufferIndex];

    gyroUpdate();
    latestTime = millis();
    latestIr = irValue;
    latestMotion = gyroGetMotion();

    // Calculate SpO2 when buffer is full
    if (sampleCount >= BUFFER_SIZE) {
        calculateSpO2();
    }

    // Move to next buffer position
    bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
    sampleCount++;

    // Output data at the configured interval.
    uint32_t currentTime = millis();
    if (currentTime - lastPrintTime >= OUTPUT_INTERVAL) {
        lastPrintTime = currentTime;

        Serial.print(currentTime);
        Serial.print(",");
        Serial.print(spo2, 1);
        Serial.print(",");
        Serial.print(irValue);
        Serial.print(",");
        Serial.println(latestMotion.motionLevel, 1);
    }

    delay(20);
}
