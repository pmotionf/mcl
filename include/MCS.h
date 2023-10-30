#ifndef PMF_MCS_H
#define PMF_MCS_H
#ifdef __cplusplus
extern "C" {
#endif

/*** ======================== LEGAL NOTICE ======================== ***
 * Copyright (c) 2023 PMF, Inc. All rights reserved.
 * Distribution of this header or any accompanying materials (documentation,
 * compiled binaries or artifacts, licenses, keys, etc) must first be
 * permitted in writing directly by an authorized representative of PMF, Inc.
 *** ============================================================== ***/

/* PMF, Inc. MCS - Motion Control System - Library
 *
 * This C library offers convenient control of PMF, Inc. Motion products.
 *
 * WARNING: Windows OS only, single thread only. Do not use with other
 *          operating systems or multiple threads.
 *
 * Due to limitations in Mitsubishi's PC CC-Link capabilities, the MCS library
 * is only supported on Windows operating systems (Windows 10, 11), and the MCS
 * library is __not thread safe__. Do not initialize or use MCS library
 * functions from multiple threads; such implementations are not supported and
 * may cause unexpected and/or catastrophic failures.
 */

/* Connection kind used for target motion system driver:
 * CC-Link Ver.2 = 0
 */
typedef unsigned short McsConnectionKind;

struct McsDistance {
  short mm;
  short um;
};
typedef struct McsDistance McsDistance;

struct McsDriverConfig {
  int using_axis1;
  McsDistance axis1_position;
  int using_axis2;
  McsDistance axis2_position;
  int using_axis3;
  McsDistance axis3_position;
};
typedef struct McsDriverConfig McsDriverConfig;

struct McsConfig {
  McsConnectionKind connection_kind;
  unsigned long connection_min_polling_interval;
  unsigned long num_drivers;
  const McsDriverConfig* drivers;
};
typedef struct McsConfig McsConfig;

typedef short McsSliderId;
typedef short McsAxisId;
typedef short McsDriverId;
 


/** Initializes the MCS library.
 * Must be called once and only once, before any other MCS library function is
 * used.
 *
 * @param config the configuration of the motion system
 * @return 0 on success, non-zero error code on failure
 */

int mcsInit(const McsConfig* config);
void mcsDeinit(void);
int mcsConnect(void);
int mcsDisconnect(void);
const char* mcsErrorString(int error_code);
unsigned int mcsVersionMajor(void);
unsigned int mcsVersionMinor(void);
unsigned int mcsVersionPatch(void);
int mcsPoll(void);
int mcsAxisRecoverSlider(McsAxisId axis_id, McsSliderId new_slider_id);
void mcsAxisSlider(McsAxisId axis_id, McsSliderId* out_slider_id);
int mcsAxisServoRelease(McsAxisId axis_id);
void mcsAxisServoReleased(McsAxisId axis_id, int* out_released);
int mcsHome(void);
int mcsSliderPosMoveAxis(
  McsSliderId slider_id, 
  McsAxisId axis_id, 
  short speed_percentage, 
  short acceleration_percentage
);
int mcsSliderPosMoveLocation(
  McsSliderId slider_id,
  McsDistance location,
  short speed_percentage,
  short acceleration_percentage
);
int mcsSliderPosMoveDistance(
  McsSliderId slider_id,
  McsDistance distance,
  short speed_percentage,
  short acceleration_percentage
);
int mcsSliderPosMoveCompleted(McsSliderId slider_id, int* out_completed);
int mcsSliderLocation(McsSliderId slider_id, McsDistance* out_location);

#ifdef __cplusplus
}
#endif
#endif /* PMF_MCS_H */
