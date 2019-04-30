#ifndef __TMWTYPES__
#define __TMWTYPES__

/* Copyright (C) 1994,1995, The MathWorks, Inc.
 * All Rights Reserved.
 *
 * File    : tmwtypes.h
 * Abstract:
 *      Data types for use with MATLAB/SIMULINK and the Real-Time Workshop.
 *
 *      When compiling stand-alone model code, data types can be overridden
 *      via compiler switches.
 *
 */

/* $Revision: 1.9 $ */

#include <limits.h>

#ifndef __MWERKS__
# ifdef __STDC__
#  include <float.h>
# else
#  define FLT_MANT_DIG 24
#  define DBL_MANT_DIG 53
# endif
#endif


/*
 *      The following data types cannot be overridden when building MEX files.
 */
#ifdef MATLAB_MEX_FILE
# undef CHAR_T
# undef INT_T
# undef BOOLEAN_T
# undef REAL_T
# undef TIME_T
#endif


/*
 * The uchar_T, ushort_T and ulong_T types are needed for compilers which do 
 * not allow defines to be specified, at the command line, with spaces in them.
 */

typedef unsigned char  uchar_T;
typedef unsigned short ushort_T;
typedef unsigned long  ulong_T;



/*=======================================================================*
 * Fixed width word size data types:                                     *
 *   int8_T, int16_T, int32_T     - signed 8, 16, or 32 bit integers     *
 *   uint8_T, uint16_T, uint32_T  - unsigned 8, 16, or 32 bit integers   *
 *   real32_T, real64_T           - 32 and 64 bit floating point numbers *
 *=======================================================================*/

#ifndef INT8_T
# if CHAR_MIN == -128
#   define INT8_T char
# elif SCHAR_MIN == -128
#   define INT8_T signed char
# endif
#endif
#ifdef INT8_T
  typedef INT8_T int8_T;
# ifndef UINT8_T
#   define UINT8_T unsigned char
# endif
  typedef UINT8_T uint8_T;
#endif


#ifndef INT16_T
# if SHRT_MAX == 0x7FFF
#  define INT16_T short
# elif INT_MAX == 0x7FFF
#  define INT16_T int
# endif
#endif
#ifdef INT16_T
 typedef INT16_T int16_T;
#endif


#ifndef UINT16_T
# if SHRT_MAX == 0x7FFF    /* can't compare with USHRT_MAX on some platforms */
#  define UINT16_T unsigned short
# elif INT_MAX == 0x7FFF
#  define UINT16_T unsigned int
# endif
#endif
#ifdef UINT16_T
  typedef UINT16_T uint16_T;
#endif


#ifndef INT32_T
# if INT_MAX == 0x7FFFFFFF 
#  define INT32_T int
# elif LONG_MAX == 0x7FFFFFFF
#  define INT32_T long
# endif
#endif
#ifdef INT32_T
 typedef INT32_T int32_T;
#endif


#ifndef UINT32_T
# if INT_MAX == 0x7FFFFFFF 
#  define UINT32_T unsigned int
# elif LONG_MAX == 0x7FFFFFFF
#  define UINT32_T unsigned long
# endif
#endif
#ifdef UINT32_T
 typedef UINT32_T uint32_T;
#endif


#ifndef REAL32_T
# ifndef __MWERKS__
#  if FLT_MANT_DIG >= 23
#    define REAL32_T float
#  endif
# else
#    define REAL32_T float
# endif
#endif
#ifdef REAL32_T
typedef REAL32_T real32_T;
#endif

#ifndef REAL64_T
# ifndef __MWERKS__
#  if DBL_MANT_DIG >= 52
#    define REAL64_T double
#  endif
# else
#    define REAL64_T double
# endif
#endif
#ifdef REAL64_T
  typedef REAL64_T real64_T;
#endif

/*=======================================================================*
 * Fixed width word size data types: (alpha & sgi64)                     *
 *   int64_T                      - signed 64 bit integers               *
 *   uint64_T                     - unsigned 64 bit integers             *
 *=======================================================================*/

#if defined(__alpha) || (defined(_MIPS_SZLONG) && (_MIPS_SZLONG == 64))
#ifndef INT64_T
#  define INT64_T long
#endif
#ifdef INT64_T
 typedef INT64_T int64_T;
#endif

#ifndef UINT64_T
#  define UINT64_T unsigned long
#endif
#ifdef UINT64_T
 typedef UINT64_T uint64_T;
#endif
#endif

/*================================================================*
 *  Fixed-point data types:                                       *
 *     fixpoint_T     - 16 or 32-bit unsigned integers            *
 *     sgn_fixpoint_T - 16 or 32-bit signed integers              *
 *  Note, when building fixed-point applications, real_T is equal *
 *  to fixpoint_T and time_T is a 32-bit unsigned integer.        *
 *================================================================*/

#ifndef FIXPTWS
# define FIXPTWS 32
#endif
#if FIXPTWS != 16 && FIXPTWS != 32
  "--> fixed-point word size (FIXPTWS) must be 16 or 32 bits"
#endif

#if FIXPTWS == 16
  typedef uint16_T fixpoint_T;
  typedef int16_T  sgn_fixpoint_T;
#else
  typedef uint32_T fixpoint_T;
  typedef int32_T  sgn_fixpoint_T;
#endif

#ifdef FIXPT
# define REAL_T fixpoint_T
# define TIME_T uint32_T
#endif



/*===========================================================================*
 * General or logical data types where the word size is not guaranteed.      *
 *  real_T     - possible settings include real32_T, real64_T, or fixpoint_T *
 *  time_T     - possible settings include real64_T or uint32_T              *
 *  boolean_T                                                                *
 *  char_T                                                                   *
 *  int_T                                                                    *
 *  uint_T                                                                   *
 *  byte_T                                                                   *
 *===========================================================================*/

#ifndef REAL_T
# ifdef REAL64_T
#   define REAL_T real64_T
# else
#   ifdef REAL32_T
#     define REAL_T real32_T
#   endif
# endif
#endif
#ifdef REAL_T
  typedef REAL_T real_T;
#endif

#ifndef TIME_T
#  ifdef REAL_T
#    define TIME_T real_T
#  endif
#endif
#ifdef TIME_T
  typedef TIME_T time_T;
#endif

#ifndef BOOLEAN_T
#define BOOLEAN_T int
#endif
typedef BOOLEAN_T boolean_T;


#ifndef CHAR_T
#define CHAR_T char
#endif
typedef CHAR_T char_T;


#ifndef INT_T
#define INT_T int
#endif
typedef INT_T int_T;


#ifndef UINT_T
#define UINT_T unsigned
#endif
typedef UINT_T uint_T;


#ifndef BYTE_T
#define BYTE_T unsigned char
#endif
typedef BYTE_T byte_T;


#endif  /* __TMWTYPES__ */
