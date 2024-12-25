# Retroshield 6803
 Some simple routines, nothing too complex but helpful to get things going.
 Code is not very optimised so feel free to tinker.
 It took me a long time to get serial i/o working so there are various serial routines.
 "simple_serial_io_test.asm" seems to be the best working example at the moment.
 
## k6803_serial_echo_backspace a.k.a. 'a cry for help'

 This code led me down a bit of a rabbit hole of debugging. I still fail to get the EXIT message working without a hack.
 I spent some time developing the Arduino code to look at potential 'hardware' related problems, so this .ino has some serialDEBUG options as well as some additional TDRE checks.
 After all that, I still couldnt fix it.
 
 If anyone cares to take a look, then it would be great to know where I am going wrong.
 
 The issue is that the string output routine misses the leading 'E' of the message. All other messages and routines seem to work ok.
 
## MONITOR ROMS
 There are a number of existing ROMs available such as MIKBUG, MINIBUG but not offering much over the BILLBUG rom. I may create a custom monitor at some point but thats a longer term plan.
## COOKBOOK routines
 I have made a start on collating more useful routines from the book 6800_Software_Gourmet_Guide_and_Cookbook_1976_Robert_Findley.
 These are currently roughly transcribed from OCR so contain some errors. 

