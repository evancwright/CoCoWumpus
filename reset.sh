echo "assembling code"
lwasm --6809 reset.asm --list=reset.list --output=reset.bin
echo "copying file to disk image"
writecocofile   -b WUMPUS.DSK reset.bin  

