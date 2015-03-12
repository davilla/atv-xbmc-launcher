# Introduction #

in [r306](https://code.google.com/p/atv-xbmc-launcher/source/detail?r=306) (right after Launcher 0.6 release) universal mode was added to XBMC/BoxeeLauncher. This allows XBMCLauncher (while still using FrontRows IR-event API) to map button sequences to actions. While the mapping of sequences to Actions was hardcoded in the old XBMCHelper, XBMCLauncher does send now normal AppleRemote buttons.

e.g. sending button sequence "menu\_hold, play, play" creates an AppleRemote Button 26 event. Those events can be mapped to Actions in [Keymap.xml](http://xbmc.org/wiki/?title=Keymap.xml) (in ~/Library/Application Support/XBMC/userdata/)

# How to test/use this #
Next step is to modify your Keymap.xml to make use of the new Buttons. Here's the AppleRemote part of Keymap.xml with some sequences already mapped, so this one should behave like universal mode on your mac.

```
   <joystick name="AppleRemote">
      <!-- plus       --> <button id="1">Up</button>
      <!-- minus      --> <button id="2">Down</button>
      <!-- left       --> <button id="3">Left</button>
      <!-- right      --> <button id="4">Right</button>
      <!-- play/pause --> <button id="5">Select</button>
      <!-- menu       --> <button id="6">PreviousMenu</button>

      <!-- hold play  --> <button id="7">Fullscreen</button>
      <!-- hold menu  --> <button id="8">ContextMenu</button>
      <!-- hold left  --> <button id="9">BigStepBack</button>
      <!-- hold right --> <button id="10">BigStepForward</button>
      
      <!--   UNIVERSAL COMMANDS -->
      <!-- hold menu, play--> <button id="20">BigStepForward</button>
      <!-- hold menu, right--> <button id="21">BigStepForward</button>
      <!-- hold menu, left--> <button id="22">BigStepForward</button>
      <!-- hold menu, up--> <button id="23">BigStepForward</button>
      <!-- hold menu, down--> <button id="24">Back</button>
      <!-- hold menu, menu--> <button id="25">BigStepForward</button>

      <!-- hold menu, play, play--> <button id="26">Display</button>
      <!-- hold menu, play, right--> <button id="27">Info</button>
      <!-- hold menu, play, left--> <button id="28">Title</button>
      <!-- hold menu, play, up--> <button id="29">PagePlus</button>
      <!-- hold menu, play, down--> <button id="30">PageMinus</button>
      <!-- hold menu, play, menu--> <button id="31">BigStepForward</button> 

      <!-- hold menu, up, play--> <button id="32">Stop</button>
      <!-- hold menu, up, right--> <button id="33">Zero</button>
      <!-- hold menu, up, left--> <button id="34">Power</button>
      <!-- hold menu, up, up--> <button id="35">Play</button>
      <!-- hold menu, up, down--> <button id="36">Pause</button>
      <!-- hold menu, up, menu--> <button id="37">BigStepForward</button> 

      <!-- hold menu, down, play--> <button id="38">BigStepForward</button>
      <!-- hold menu, down, right--> <button id="39">BigStepForward</button>
      <!-- hold menu, down, left--> <button id="40">BigStepForward</button>
      <!-- hold menu, down, up--> <button id="41">BigStepForward</button>
      <!-- hold menu, down, down--> <button id="42">BigStepForward</button>
      <!-- hold menu, down, menu--> <button id="43">BigStepForward</button> 

      <!-- hold menu, right, play--> <button id="44">BigStepForward</button>
      <!-- hold menu, right, right--> <button id="45">BigStepForward</button>
      <!-- hold menu, right, left--> <button id="46">BigStepForward</button>
      <!-- hold menu, right, up--> <button id="47">BigStepForward</button>
      <!-- hold menu, right, down--> <button id="48">BigStepForward</button>
      <!-- hold menu, right, menu--> <button id="49">BigStepForward</button> 

      <!-- hold menu, left, play--> <button id="50">BigStepForward</button>
      <!-- hold menu, left, right--> <button id="51">BigStepForward</button>
      <!-- hold menu, left, left--> <button id="52">BigStepForward</button>
      <!-- hold menu, left, up--> <button id="53">BigStepForward</button>
      <!-- hold menu, left, down--> <button id="54">BigStepForward</button>
      <!-- hold menu, left, menu--> <button id="55">BigStepForward</button> 
    </joystick>
```