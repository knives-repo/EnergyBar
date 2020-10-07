/**
 * @file Log.h
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#ifndef LOG_H_INCLUDED
#define LOG_H_INCLUDED

#include <os/log.h>

extern os_log_t logger;
void init_logging(void);

//#define LOG(format, ...)                os_log(logger, "%s: " format, __func__, __VA_ARGS__)
#define LOG(format, ...)                os_log(logger, format, __VA_ARGS__)

#endif
