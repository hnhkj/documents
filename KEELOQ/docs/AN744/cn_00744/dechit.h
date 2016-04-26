//  Module DECHIT.h
//
//  include this file when using the HiTech C compiler
//
#define HITECH

#include <pic.h>
#include <string.h>

typedef unsigned char byte;
typedef signed char sbyte;
typedef signed int word;


#define TRUE    1
#define FALSE   0
#define ON      1
#define OFF     0

#define BIT_TEST( x, y) (( (x) & (1<<(y))) != 0)

// set config word
__CONFIG( UNPROTECT | (FOSC1 | FOSC0) | BODEN);  
__IDLOC(0x1234);                    // define ID locations 


