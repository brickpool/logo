/*
 * DebugUtils.h
 * Utility functions to help debugging running code.
 * 
 * author: J.Schneider <https://github.com/brickpool/logo>
 * Copyright (c) 2020,2021 J.Schneider
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

#ifndef DEBUGUTILS_H
#define DEBUGUTILS_H

#ifdef _DEBUG
#include <Arduino.h>

extern void (*_debug_handler)(const __FlashStringHelper *format, ...);

/* Debug output macros. */
#define DEBUG_FMT(fmt, ...) do { \
	if (_debug_handler) \
		_debug_handler(F(fmt ".\n"), __VA_ARGS__); \
} while (0)
#define DEBUG(msg) DEBUG_FMT(msg, NULL)
#define DEBUG_ERROR(err, msg) DEBUG_FMT("%s returning " #err ": " msg, __func__)
#define RETURN() do { \
	DEBUG_FMT("%s returning", __func__); \
	return; \
} while (0)
#define RETURN_CODE(x) do { \
	DEBUG_FMT("%s returning " #x, __func__); \
	return x; \
} while (0)
#define RETURN_ERROR(err, msg) do { \
	DEBUG_ERROR(err, msg); \
	return err; \
} while (0)
#define RETURN_INT(x) do { \
	int _x = x; \
	DEBUG_FMT("%s returning %d", __func__, _x); \
	return _x; \
} while (0)
#define RETURN_STRING(x) do { \
	char *_x = x; \
	DEBUG_FMT("%s returning %s", __func__, _x); \
	return _x; \
} while (0)
#define SET_ERROR(val, err, msg) do { DEBUG_ERROR(err, msg); val = err; } while (0)
#define TRACE(fmt, ...) DEBUG_FMT("%s(" fmt ") called", __func__, __VA_ARGS__)
#define TRACE_VOID() DEBUG_FMT("%s() called", __func__)
#else
#define DEBUG_FMT(fmt, ...)
#define DEBUG(msg)
#define DEBUG_ERROR(err, msg)
#define RETURN() do { return; } while (0)
#define RETURN_CODE(x) do { return x; } while (0)
#define RETURN_ERROR(err, msg) do { return err; } while (0)
#define RETURN_INT(x) do { return x; } while (0)
#define RETURN_STRING(x) do { return x; } while (0)
#define SET_ERROR(val, err, msg) do { val = err; } while (0)
#define TRACE(fmt, ...)
#define TRACE_VOID()
#endif

#endif  // DEBUGUTILS_H
