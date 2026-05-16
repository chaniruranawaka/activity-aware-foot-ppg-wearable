#ifndef CONFIG_H
#define CONFIG_H

// ===== Signal Processing Parameters =====

// IIR Low-Pass Filter
// Alpha controls filter aggressiveness (0.0-1.0)
// Lower values = more filtering/smoothing, slower response
// Higher values = less filtering, faster response
// Default: 0.6 (good balance)
#define FILTER_ALPHA 0.6f

// ===== Buffer Configuration =====

// Size of circular buffer for signal processing
// Larger = slower but more accurate calculations
// 100 samples at 100Hz = 1 second window
#define BUFFER_SIZE 100

// ===== SpO2 Calibration =====

// Empirical calibration constants
// These are based on typical MAX30102 behavior
// Adjust if SpO2 readings seem off by a consistent amount
#define SPO2_BASE 110.0f      // Base reference value
#define SPO2_SCALE 25.0f      // Scaling factor for ratio
#define SPO2_MIN 70.0f        // Minimum valid SpO2
#define SPO2_MAX 100.0f       // Maximum valid SpO2

// ===== Output Configuration =====

// Serial output interval (milliseconds)
#define OUTPUT_INTERVAL 500

// Sample rate (Hz)
#define SAMPLE_RATE 100

// ===== ESP32 Access Point Configuration =====
// Connect the tablet/app directly to this network for the most reliable setup.
#define WIFI_ENABLE_AP 1
#define WIFI_AP_SSID "SmartShoe_AP"
#define WIFI_AP_PASSWORD "change-me-123"
#define WIFI_AP_IP 192, 168, 4, 1
#define WIFI_AP_GATEWAY 192, 168, 4, 1
#define WIFI_AP_SUBNET 255, 255, 255, 0

#endif // CONFIG_H
