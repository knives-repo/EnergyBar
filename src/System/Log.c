//
//  Log.c
//  EnergyBar
//
//  Created by Nicolas Bonamy on 10/7/20.
//  Copyright © 2020 Bill Zissimopoulos. All rights reserved.
//

#include "Log.h"

os_log_t logger;

void init_logging() {
    logger = os_log_create("fr.bonamy.energybar", "EnergyBar");
}
