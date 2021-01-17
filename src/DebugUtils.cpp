/*
 * DebugUtils.cpp
 * Utility functions to help debugging running code.
 * 
 * author: J.Schneider <https://github.com/brickpool/logo>
 * Copyright (c) 2020 J.Schneider
 * The Utilities are licensed under the GNU Lesser General Public License v3.0.
 *
 * However, these Utilities distributes and uses code from
 * other Open Source Projects that have their own licenses:
 *
 * - https://gr33nonline.wordpress.com/2018/06/26/debug/
 * - https://github.com/sigrokproject/libserialport/blob/master/libserialport_internal.h
 * - https://playground.arduino.cc/Main/Printf/
 *
 */

#include <Arduino.h>
#include <stdarg.h>
#include "DebugUtils.h"

const byte numChars = 128; // resulting string limited to 128 chars

void _default_debug_handler(const __FlashStringHelper *format, ...)
{
  static char buf[numChars];
  va_list args;
  va_start(args, format);
#ifdef __AVR__
    vsnprintf_P(buf, sizeof(buf), (const char *)format, args);  // progmem for AVR
#else
    vsnprintf(buf, sizeof(buf), (const char *)format, args);    // for the rest of the world
#endif
  va_end(args);
  if (Serial) Serial.print(buf);
}

void (*_debug_handler)(const __FlashStringHelper *format, ...) = _default_debug_handler;
