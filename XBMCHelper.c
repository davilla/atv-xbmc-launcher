/*
*
* just a dummy process which is spawned if XBMCHelper form XBMC should not run
*
*/

#include <stdio.h>
#include <signal.h>
int main(int argc, char** argv){
	while(1) sleep(1000);
	return 0;
}
