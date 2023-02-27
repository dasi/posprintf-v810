/*

posprintf - a condensed version of sprintf for Thumb, esp. GBA
Written in 2003 by Dan Posluns
http://www.danposluns.com/gbadev/posprintf/

Ported to V810 in 2008 by Derek da Silva

No rights reserved.
https://creativecommons.org/publicdomain/zero/1.0/


INSTRUCTIONS:

To call: posprintf(char *dest, const char *src[, param1[, param2[, ... paramN]]]);

- src must be a valid zero-terminated C string.
- dest must point to a sufficiently large block of memory to contain the result string.

The following format specifiers are valid:

%% - print a '%' symbol
%s - print a string; parameter must point to a valid zero-terminated C string
%d - print a 16-bit (short) integer; must be within [-65,535 .. 65,535]
%l - print a 29-bit integer; approximate range [-500,000,000 .. 500,000,000]
%x - print a hexadecimal number (lowercase digits)
%X - print a hexadecimal number (uppercase digits)

The specifiers %d, %l, %x and %X may be modified as follows:

- Digits 1 through 9 indicate number of leading spaces to print, eg.
	%5d would print the number 123 as "  123"
	%5d would print the number 123456 as "123456" (no leading spaces)
- When above digit is prefixed with 0, leading zeros are printed instead of spaces
	%05d would print the number 123 as "00123"
	%04d would print the number 12345 as "12345" (no leading zeros)
- Negative sign consumes a leading space, eg.
	%05d would print the number -123 as "-0123"
	(Hexadecimal numbers are considered unsigned)
*/

#ifndef _PSPRINTF_HEADER_
#define _PSPRINTF_HEADER_

extern void posprintf(char *, const char *, ...);

#endif
