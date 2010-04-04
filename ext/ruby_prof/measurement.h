#ifndef MEASUREMENT
#define MEASUREMENT

#ifdef HAVE_LONG_LONG
typedef unsigned LONG_LONG prof_measure_t; // long long is 8 bytes on 32-bit
#else
typedef unsigned long prof_measure_t;
#endif

static prof_measure_t (*get_measurement)();
static double (*convert_measurement)(prof_measure_t);

#endif
