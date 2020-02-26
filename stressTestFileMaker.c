/*--------------------------------------------------------------------*/
/* stressTestFileMaker.c                                                  */
/* Author: Isaac Wolfe                                                */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>

enum {MAXLINES = 1000};
enum {MAXCHARS = 10000};

int main(void)
{
	char c;
	int lineCount = 0;
	int charCount = 0;

	while (charCount < MAXCHARS)
	{
		c = rand();
		c = c % 11;
		charCount++;

		if (c == 0x09) putchar(c); 
		if (lineCount < MAXLINES) {
			if (c == 0x0A) {
				putchar(c);
				lineCount++;
			}
		} 
		/* if (c >= 0x21 && c<= 0x7E) putchar(c); */
	}
	return 0;
}