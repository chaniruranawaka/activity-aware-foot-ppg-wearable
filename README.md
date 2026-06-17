# Activity-Aware Foot-Based PPG Wearable

## Overview

This project presents an experimental wearable sensing platform that investigates activity-aware physiological monitoring using foot-based photoplethysmography (PPG) and inertial sensing.

Conventional pulse oximeters primarily rely on finger-based sensing to measure physiological parameters such as heart rate and blood oxygen saturation (SpO₂). However, wearable technologies often require sensing modalities that can be seamlessly integrated into daily-use accessories. This project explores the feasibility of relocating physiological sensing to a shoe-based platform, enabling unobtrusive monitoring during real-world activities.

The system integrates a MAX30102 optical PPG sensor within a footwear prototype to acquire physiological signals from the foot, while an MPU6050 inertial measurement unit (IMU) provides motion information for activity-aware analysis. Sensor data is processed by an ESP32-C3 microcontroller and transmitted wirelessly to a Flutter-based mobile application for real-time visualization.

The primary objective of this project is not to develop a medical device, but to investigate the opportunities and challenges associated with foot-based physiological sensing under dynamic movement conditions.

---

## Research Motivation

Most commercially available physiological monitoring systems rely on finger, wrist, or chest-based sensing locations. These locations may not always be practical for continuous monitoring during daily activities.

This project explores whether footwear can serve as an alternative sensing platform by answering the following research question:

**Can meaningful physiological trends be observed from foot-based PPG signals during real-world activities while simultaneously accounting for user movement through inertial sensing?**

The project investigates signal quality, motion sensitivity, sensor placement considerations, and the integration of physiological and motion-related data streams within a wearable platform.

---

## Objectives

* Investigate the feasibility of foot-based PPG sensing.
* Measure physiological trends using an optical sensor embedded in footwear.
* Monitor user motion using inertial sensing.
* Develop a portable embedded sensing platform.
* Create a mobile application for real-time data visualization.
* Evaluate sensor performance under walking and jogging conditions.
* Explore activity-aware physiological monitoring concepts.

---

## System Architecture

```text
MAX30102 PPG Sensor
          │
          ▼
    ESP32-C3 Controller
          │
          ├──────────────► WiFi Communication
          │
          ▼
      Flutter Mobile App
          │
          ▼
   Real-Time Visualization

MPU6050 IMU
      │
      └──────────────► Activity Level Estimation
```

---

## Hardware Design

### ESP32-C3 Super Mini

The ESP32-C3 serves as the central processing unit of the wearable platform. It is responsible for:

* Reading sensor measurements.
* Performing data preprocessing.
* Managing communication protocols.
* Transmitting physiological and motion data to the mobile application.

### MAX30102 Optical Sensor

The MAX30102 sensor is used to acquire photoplethysmographic signals from the foot. The sensor contains red and infrared LEDs along with a photodetector capable of measuring variations in reflected light caused by blood volume changes.

Applications within this project:

* Heart rate estimation.
* SpO₂ trend observation.
* PPG signal acquisition.

### MPU6050 IMU

The MPU6050 provides:

* Three-axis acceleration measurements.
* Three-axis gyroscope measurements.

These measurements are used to estimate user activity levels and provide context for physiological observations.

---

## Mobile Application

A Flutter-based mobile application was developed to:

* Receive live sensor data.
* Display physiological trends.
* Display motion-level information.
* Provide a portable user interface for testing.

The application serves as a visualization platform rather than a medical monitoring system.

---

## Prototype Development Process

### Stage 1 – Breadboard Validation

Initial testing focused on:

* Sensor communication verification.
* Power management validation.
* Data acquisition testing.
* Signal quality assessment.

### Stage 2 – Sensor Integration

The MAX30102 and MPU6050 sensors were integrated with the ESP32-C3 using I²C communication.

### Stage 3 – Wearable Prototype

The sensing hardware was incorporated into a footwear prototype for real-world testing.

### Stage 4 – Mobile Integration

Real-time wireless communication was established between the embedded system and the Flutter application.

---

## Experimental Testing

Testing was conducted under several conditions:

### Stationary Testing

The user remained stationary while physiological signals were collected to verify baseline sensor operation.

### Walking Trials

The wearable platform was tested during walking activities to observe the effects of moderate movement.

### Jogging Trials

The prototype was evaluated during jogging sessions while the mobile application displayed live physiological and motion data.

Video evidence of the jogging experiments was recorded for documentation and analysis.

---

## Key Observations

The following observations were made during testing:

* Foot-based PPG sensing is achievable under controlled conditions.
* Motion significantly influences signal quality.
* Sensor placement strongly affects measurement stability.
* Inertial sensing provides useful contextual information regarding user activity.
* Real-time physiological trend visualization can be achieved using low-cost hardware.

---

## Challenges Encountered

Several engineering challenges were identified:

* Motion artifacts during jogging.
* Maintaining stable sensor-to-skin contact.
* Optical interference from ambient light.
* Variations caused by footwear fit and user movement.
* Signal quality degradation during high-intensity activities.

These challenges highlight important considerations for future wearable footwear-based sensing systems.

---

## Future Work

Potential future improvements include:

* Advanced motion artifact removal algorithms.
* Sensor enclosure optimization.
* Improved optical isolation techniques.
* BLE-based communication architecture.
* Data logging and long-term monitoring.
* Machine learning-based activity classification.
* Activity-aware physiological trend prediction.
* Signal quality assessment models.

---

## Repository Contents

* Embedded firmware source code.
* Flutter mobile application.
* Hardware implementation photographs.
* Experimental testing documentation.
* System architecture diagrams.
* Demonstration media.

---

## Disclaimer

This project is an experimental engineering and research prototype intended for educational and investigative purposes only.

The system is not a certified medical device, and the physiological measurements displayed by the prototype should not be used for diagnosis, treatment, or clinical decision-making.

---

## Author

R.A.C.D. Ranawaka

Electronic and Telecommunication Engineering Undergraduate

University of Moratuwa, Sri Lanka
