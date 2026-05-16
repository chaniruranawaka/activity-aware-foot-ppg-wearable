# Activity-Aware Foot-Based PPG Wearable

An experimental wearable sensing platform that investigates activity-aware physiological monitoring using foot-based photoplethysmography and inertial sensing.

This project explores whether physiological trends can be monitored from the foot using a shoe-integrated wearable system. The prototype uses a MAX30102 pulse oximeter sensor for foot-based PPG sensing, an MPU6050 inertial measurement unit for motion-level detection, an ESP32-C3 microcontroller for sensor acquisition and wireless communication, and a Flutter mobile application for live visualization.

---

## Project Overview

The main goal of this project is to explore the feasibility and limitations of foot-based physiological sensing during physical activity.

Unlike typical pulse oximeter systems that use the finger, this project investigates the possibility of placing the PPG sensor inside a shoe and observing physiological trends while the user is moving. The system was tested during jogging, where the mobile app displayed live SpO₂ trend data and motion-level readings.

This project is designed as an experimental research prototype, not as a medical device.

---

## Research Focus

This project focuses on:

- Foot-based photoplethysmography sensing
- Activity-aware physiological trend monitoring
- Inertial sensing for movement detection
- Wearable system prototyping
- Real-time mobile app visualization
- Motion-related PPG signal behavior
- Feasibility testing under real-world movement conditions

---

## System Architecture

```text
MAX30102 PPG Sensor + MPU6050 IMU
                ↓
        ESP32-C3 Super Mini
                ↓
        WiFi Communication
                ↓
        Flutter Mobile Application
                ↓
 Live SpO₂ Trend + Motion Level Visualization
