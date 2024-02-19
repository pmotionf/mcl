#ifndef PMF_MCL_H
#define PMF_MCL_H
#ifdef __cplusplus
extern "C" {
#endif

/*** ======================== LEGAL NOTICE ======================== ***
 * Copyright (c) 2023-2024 PMF, Inc. All rights reserved.
 * Distribution of this header or any accompanying materials (documentation,
 * compiled binaries or artifacts, licenses, keys, etc) must first be
 * permitted in writing directly by an authorized representative of PMF, Inc.
 *** ============================================================== ***/

/* PMF, Inc. MCL - Motion Control Library
 *
 * This C library offers convenient control of PMF, Inc. Motion products.
 *
 * WARNING: Windows OS only, single thread only. Do not use with other
 *          operating systems or multiple threads.
 *
 * Due to limitations in Mitsubishi's PC CC-Link capabilities, MCL is only
 * supported on Windows operating systems (Windows 10, 11), and MCL is __not
 * thread safe__. Do not initialize or use MCL functions from multiple threads;
 * such implementations are not supported and may cause unexpected and/or
 * catastrophic failures.
 */

/* Connection kind used for target motion system driver:
 * CC-Link Ver.2 = 0
 */
typedef unsigned short MclConnectionKind;

struct MclDistance {
  short mm;
  short um;
};
typedef struct MclDistance MclDistance;

struct MclDriverConfig {
  int using_axis1;
  MclDistance axis1_position;
  int using_axis2;
  MclDistance axis2_position;
  int using_axis3;
  MclDistance axis3_position;
};
typedef struct MclDriverConfig MclDriverConfig;

struct MclConfig {
  MclConnectionKind connection_kind;
  unsigned long connection_min_polling_interval;
  unsigned long num_drivers;
  const MclDriverConfig* drivers;
};
typedef struct MclConfig MclConfig;

typedef short MclSliderId;
typedef short MclAxisId;
typedef short MclDriverId;
 


/** Initializes MCL.
 * Must be called once and only once, before any other MCL function is used.
 *
 * @param config the configuration of the motion system
 * @return 0 on success, non-zero error code on failure
 */

int mclInit(const MclConfig* config);
void mclDeinit(void);
int mclConnect(void);
int mclDisconnect(void);
const char* mclErrorString(int error_code);
unsigned int mclVersionMajor(void);
unsigned int mclVersionMinor(void);
unsigned int mclVersionPatch(void);
int mclPoll(void);
int mclAxisRecoverSlider(MclAxisId axis_id, MclSliderId new_slider_id);
void mclAxisSlider(MclAxisId axis_id, MclSliderId* out_slider_id);
int mclAxisServoRelease(MclAxisId axis_id);
void mclAxisServoReleased(MclAxisId axis_id, int* out_released);
int mclHome(void);
int mclSliderPosMoveAxis(
  MclSliderId slider_id, 
  MclAxisId axis_id, 
  short speed_percentage, 
  short acceleration_percentage
);
int mclSliderPosMoveLocation(
  MclSliderId slider_id,
  MclDistance location,
  short speed_percentage,
  short acceleration_percentage
);
int mclSliderPosMoveDistance(
  MclSliderId slider_id,
  MclDistance distance,
  short speed_percentage,
  short acceleration_percentage
);
int mclSliderPosMoveCompleted(MclSliderId slider_id, int* out_completed);
int mclSliderLocation(MclSliderId slider_id, MclDistance* out_location);

#ifdef __cplusplus
}
#endif
#endif /* PMF_MCL_H */
