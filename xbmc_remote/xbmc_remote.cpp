#include "stdlib.h"
#include "SDL/SDL.h"
#include "../../lib/c++/xbmcclient.h"

void SendKey(SDL_KeyboardEvent *key, int KeyState, int sockfd, CAddress &Addr)
{
  //Print out text corresponding to the key in question
  printf( "%s\n", SDL_GetKeyName(key->keysym.sym));
  CPacketBUTTON btn(SDL_GetKeyName(key->keysym.sym), "KB", KeyState);
  btn.Send(sockfd, Addr);
}


int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    printf("Usage: %s IP port", argv[0]);
    return -1;
  }
  CAddress my_addr(argv[1], atoi(argv[2])); // Address => localhost on 9777
  int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd < 0)
  {
    printf("Error creating socket\n");
    return -1;
  }

  my_addr.Bind(sockfd);

	SDL_Surface *screen;
	SDL_Event event;
	int running = 1;

	//We must first initialize the SDL video component, and check for success
	if (SDL_Init(SDL_INIT_VIDEO) != 0) {
		printf("Unable to initialize SDL: %s\n", SDL_GetError());
		return 1;
	}
  
	
	//When this program exits, SDL_Quit must be called
	atexit(SDL_Quit);
	
	//Set the video mode to anything, just need a window
	screen = SDL_SetVideoMode(320, 240, 0, SDL_ANYFORMAT);
	if (screen == NULL) {
		printf("Unable to set video mode: %s\n", SDL_GetError());
		return 1;
	}
	
	//Keep looping until the user closes the SDL window
	while(running) {
		//Get the next event from the stack
		while(SDL_PollEvent(&event)) {
			//What kind of event has occurred?
			switch(event.type){
                case SDL_KEYDOWN:	//A key has been pressed
                    SendKey(&event.key, BTN_DOWN, sockfd, my_addr);
                break;
				case SDL_KEYUP:		//A key has been released
                    SendKey(&event.key, BTN_UP, sockfd, my_addr);
                break;
				case SDL_QUIT:		//The user has closed the SDL window
					running = 0;
                break;
			}
		}
        // sleep 100ms
        usleep(100 * 1000);
	}
		
	//Return success!
	return 0;
}