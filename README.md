Anyone who has used WorldEdit in the past should know what this program does. It [selects the two opposite corners in a 3d (or 2d) area]("http://wiki.sk89q.com/wiki/WorldEdit/Selection") and can use that selection to [fill, replace, or perform other operations on it.]("http://wiki.sk89q.com/wiki/WorldEdit/Region_operations")

This program requires [The Adventure Map Interface]("http://www.computercraft.info/forums2/index.php?/topic/3728-mc-164-cc-158-immibiss-peripherals/page__st__180__p__90273#entry90273") from [Immibis's Peripherals]("http://www.computercraft.info/forums2/index.php?/topic/3728-mc-164-cc-158-immibiss-peripherals/"), or a Command Computer.

This program has also been uploaded to the [CCSystems App Store]("http://www.computercraft.info/forums2/index.php?/topic/22133-ccsystems-app-store-version-20-release/") called "WorldEdit".

To use it, simply run the program, and type commands into chat, enter them on the computer, or download the rednet companion on a pocket computer, connect a wireless modem to the command computer and run the rednet companion (You will need to allow the ID on the computer itself first!) and type them on the pocket computer.

Some of the supported commands are: (from [WorldEdit/Reference]("http://wiki.sk89q.com/wiki/WorldEdit/Reference"))

## Commands
* hpos1 and hpos2 (select the block you're looking at, it's functionally identical to the wand)
* pos1 and pos2 (select the block you're standing on, not above like WorldEdit's)
* set (sets the block(s) in the selection to the block(s) specified.)
* replace (replaces the block(s) in the first argument with the block(s) in the second argument.)
* expand (expands the selection in the direction you're looking)
* contract (shrinks the selection in the direction you're looking)
* outset (expands the selection in all directions by the specified amount)
* inset (shrinks the selection in all directions by the specified amount)
* sel (clears selection)
* chunk (selects the chunk you're in)
* shift (shifts the selection in the direction you're looking)
* copy (copies the selection into your clipboard)
* rotate (rotates what's in your clipboard 90, 180, or 270 degrees on any axis)
* paste (puts your clipboard into the world)
* save (saves your clipboard to a file in WE/Schematics/[filename])
* load (loads a clipboard from WE/Schematics/[filename])
* move (moves your selection)
* stack (duplicates your selection in the direction you're looking in)
* help (lists commands and gives a description of each command)
* refresh (updates WE_Sel, WE_Clipboard, WE_Cuboid, and GeneralAPI)
* reboot (reboots the computer)
* terminate (ends the program)
* endchatspam (turns off command block output)
* distr (gets the distribution of the blocks in the selection)
* count (counts the instances of a block in the selection)
* size (prints the size of the selection)


How to install: pastebin run ku1FHyEW

Note:

Don't put "//" before the commands, just say them in chat or on the computer, or on a pocket computer. Saying "pos1" will select the first position at your feet, for example.

TODO:
* Add support for the schematic format (and Worldporter's format, if requested?)
* Make the region operations in sel work with concave polygons --IN PROGRESS
* Make polygonal selection use a greedier algorithm.

Program downloads:
[Installer]("http://pastebin.com/ku1FHyEW") Pastebin ID: ku1FHyEW  
[Core Program]("https://raw.githubusercontent.com/moomoomoo309/WorldEdit-CC/master/WE_Core.lua")  
[Cuboid Operations]("https://raw.githubusercontent.com/moomoomoo309/WorldEdit-CC/master/WE_Cuboid.lua")  
[Selection Operations]("https://raw.githubusercontent.com/moomoomoo309/WorldEdit-CC/master/WE_Sel.lua")  
[Clipboard Operations]("https://raw.githubusercontent.com/moomoomoo309/WorldEdit-CC/master/WE_Clipboard.lua")  
[GeneralAPI]("https://raw.githubusercontent.com/moomoomoo309/WorldEdit-CC/master/GeneralAPI.lua")  
[ConfigAPI]("https://raw.githubusercontent.com/moomoomoo309/WorldEdit-CC/master/ConfigAPI.lua")  
[Rednet Companion]("https://dl.dropboxusercontent.com/u/46304817/CC%20Programs/WorldEdit/CCWE%20Reqs/WE_Comms.lua") Pastebin ID: BEAfiM52

If anyone wants to help me in this program, PM me and I'll gladly collaborate. Any ideas or suggestions would be appreciated.

Special thanks to exlted for rewriting half of my messy code with me and doing most of the WIP work on polygon selection, to Lyqyd for lsh, Wergat for his amazing code to get the player's looking vector, and bwhodle for his config API.


## Changelog
(1.5.1) July 24th, 2016: Sped up all scanning of blocks, added list, rotate, exportVar, deepCopy, deepCut. Changed copy/cut to not include NBT data.  
(1.5) May 31st, 2016: Added NBT support to the command computer, implemented hpos on command computers. Sped up set and replace further.  
(1.4.1) May 29th, 2016: Added rednet and direct command input, removing chat box requirement, sped up set  
(1.4) December 31, 2015: Re-enabled NBT support for the Adventure Map Interface, Added configs. Paths can be changed for all files properly.  
(1.3.1) July 31, 2015: Added hacky support to change paths for other programs. Will be implemented better later.  
(1.3.0) July 15, 2015: Ported to command computers in a stable manner. hpos1 and hpos2 do not work on command computers. Requires some type of chat box.  
(1.2.1) June 29, 2015: Added help.  
(1.2.0) May 24, 2015: WE_Clipboard finally released. reboot, refresh, and terminate added. There is always hope.  
(1.1.2) May 18, 2015: Quality of life changes. No major changes. First release dependent upon GeneralAPI.  
(1.1.1) March 4, 2015: Program will wait until it finds an adventure map interface. First version uploaded to the app store.  
February 21, 2015: Did all the things. Fixed everything but WE_Clipboard, because it's a lost cause.  
May 30, 2014: Added //shift.  
May 30, 2014: Added chat feedback for all commands and implemented //chunk.  
May 29, 2014: Ninja edit 2 because I derped and made it say the coordinates for the first position when doing pos2.  
May 29, 2014: Ninja edit fixing replace because I forgot tonumber() (First completely functional release?)  
May 29, 2014: ~~ First completely functional release!~~  
