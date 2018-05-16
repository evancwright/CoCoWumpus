echo "assembling code"
lwasm --6809 wumpus.asm --list=wumpus.list --output=wumpus.bin
echo "copying file to disk image"
cp EVAN.DSK WUMPUS.DSK
writecocofile   -b WUMPUS.DSK wumpus.bin  

