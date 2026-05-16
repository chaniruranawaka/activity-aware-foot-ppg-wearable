#ifndef GYRO_H
#define GYRO_H

#include <Arduino.h>

struct MotionData {
    float accelX;
    float accelY;
    float accelZ;
    float velocityX;
    float velocityY;
    float velocityZ;
    float motionLevel;
};

bool gyroBegin();
bool gyroUpdate();
MotionData gyroGetMotion();

#endif // GYRO_H
