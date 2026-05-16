#include "gyro.h"

#include <Wire.h>
#include <math.h>

const uint8_t MPU6050_ADDR = 0x68;
const uint8_t WHO_AM_I = 0x75;
const uint8_t PWR_MGMT_1 = 0x6B;
const uint8_t ACCEL_XOUT_H = 0x3B;
const float GRAVITY_MS2 = 9.80665f;
const float GRAVITY_FILTER_ALPHA = 0.02f;
const float ACCEL_DEADBAND_MS2 = 0.12f;
const float MOTION_RISE_ALPHA = 0.85f;
const float MOTION_FALL_ALPHA = 0.9f;
const float MOTION_ZERO_THRESHOLD = 3.0f;

MotionData motion = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
float gravityX = 0.0f;
float gravityY = 0.0f;
float gravityZ = 0.0f;
uint32_t lastGyroUpdate = 0;
bool gyroReady = false;
bool gravityInitialized = false;

void gyroWriteRegister(uint8_t reg, uint8_t value) {
    Wire.beginTransmission(MPU6050_ADDR);
    Wire.write(reg);
    Wire.write(value);
    Wire.endTransmission();
}

bool gyroReadRegister(uint8_t reg, uint8_t &value) {
    Wire.beginTransmission(MPU6050_ADDR);
    Wire.write(reg);
    if (Wire.endTransmission(false) != 0) {
        return false;
    }

    if (Wire.requestFrom(MPU6050_ADDR, (uint8_t)1) != 1) {
        return false;
    }

    value = Wire.read();
    return true;
}

int16_t gyroReadWord() {
    int16_t highByte = Wire.read();
    int16_t lowByte = Wire.read();
    return (highByte << 8) | lowByte;
}

bool gyroReadRaw(
    int16_t &accelX,
    int16_t &accelY,
    int16_t &accelZ,
    int16_t &gyroX,
    int16_t &gyroY,
    int16_t &gyroZ
) {
    Wire.beginTransmission(MPU6050_ADDR);
    Wire.write(ACCEL_XOUT_H);
    if (Wire.endTransmission(false) != 0) {
        return false;
    }

    if (Wire.requestFrom(MPU6050_ADDR, (uint8_t)14) != 14) {
        return false;
    }

    accelX = gyroReadWord();
    accelY = gyroReadWord();
    accelZ = gyroReadWord();
    gyroReadWord(); // Temperature, unused.
    gyroX = gyroReadWord();
    gyroY = gyroReadWord();
    gyroZ = gyroReadWord();

    return true;
}

bool gyroBegin() {
    uint8_t whoAmI = 0;
    if (!gyroReadRegister(WHO_AM_I, whoAmI)) {
        gyroReady = false;
        return false;
    }

    if (whoAmI != 0x68) {
        gyroReady = false;
        return false;
    }

    gyroWriteRegister(PWR_MGMT_1, 0x00);
    delay(100);

    motion = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
    gravityX = 0.0f;
    gravityY = 0.0f;
    gravityZ = 0.0f;
    gravityInitialized = false;
    lastGyroUpdate = millis();
    gyroReady = true;
    return true;
}

bool gyroUpdate() {
    if (!gyroReady) {
        return false;
    }

    int16_t accelX, accelY, accelZ;
    int16_t gyroX, gyroY, gyroZ;

    if (!gyroReadRaw(accelX, accelY, accelZ, gyroX, gyroY, gyroZ)) {
        return false;
    }

    uint32_t now = millis();
    float dt = (now - lastGyroUpdate) / 1000.0f;
    lastGyroUpdate = now;

    if (dt <= 0.0f || dt > 1.0f) {
        return true;
    }

    float ax = (accelX / 16384.0f) * GRAVITY_MS2;
    float ay = (accelY / 16384.0f) * GRAVITY_MS2;
    float az = (accelZ / 16384.0f) * GRAVITY_MS2;

    if (!gravityInitialized) {
        gravityX = ax;
        gravityY = ay;
        gravityZ = az;
        gravityInitialized = true;
    }

    gravityX = ((1.0f - GRAVITY_FILTER_ALPHA) * gravityX) + (GRAVITY_FILTER_ALPHA * ax);
    gravityY = ((1.0f - GRAVITY_FILTER_ALPHA) * gravityY) + (GRAVITY_FILTER_ALPHA * ay);
    gravityZ = ((1.0f - GRAVITY_FILTER_ALPHA) * gravityZ) + (GRAVITY_FILTER_ALPHA * az);

    motion.accelX = ax - gravityX;
    motion.accelY = ay - gravityY;
    motion.accelZ = az - gravityZ;

    if (fabs(motion.accelX) < ACCEL_DEADBAND_MS2) motion.accelX = 0.0f;
    if (fabs(motion.accelY) < ACCEL_DEADBAND_MS2) motion.accelY = 0.0f;
    if (fabs(motion.accelZ) < ACCEL_DEADBAND_MS2) motion.accelZ = 0.0f;

    motion.velocityX += motion.accelX * dt;
    motion.velocityY += motion.accelY * dt;
    motion.velocityZ += motion.accelZ * dt;

    float linearAccelMagnitude = sqrt(
        (motion.accelX * motion.accelX) +
        (motion.accelY * motion.accelY) +
        (motion.accelZ * motion.accelZ)
    );
    float rawMotionLevel = (linearAccelMagnitude * 18.0f);
    rawMotionLevel = constrain(rawMotionLevel, 0.0f, 100.0f);

    if (rawMotionLevel < MOTION_ZERO_THRESHOLD) {
        motion.motionLevel = 0.0f;
    } else if (rawMotionLevel > motion.motionLevel) {
        motion.motionLevel = (MOTION_RISE_ALPHA * rawMotionLevel) +
                             ((1.0f - MOTION_RISE_ALPHA) * motion.motionLevel);
    } else {
        motion.motionLevel = (MOTION_FALL_ALPHA * rawMotionLevel) +
                             ((1.0f - MOTION_FALL_ALPHA) * motion.motionLevel);
    }

    float rawAccelMagnitude = sqrt((ax * ax) + (ay * ay) + (az * az));
    float gyroMagnitude = sqrt((gyroX * gyroX) + (gyroY * gyroY) + (gyroZ * gyroZ)) / 131.0f;
    bool isStationary = fabs(rawAccelMagnitude - GRAVITY_MS2) < 0.35f && gyroMagnitude < 4.0f;

    if (isStationary) {
        motion.velocityX = 0.0f;
        motion.velocityY = 0.0f;
        motion.velocityZ = 0.0f;
        motion.motionLevel = 0.0f;
    }

    return true;
}

MotionData gyroGetMotion() {
    return motion;
}
