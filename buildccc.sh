echo "assembling code"
lwasm --6809 --format=raw wumpusccc.asm --list=wumpusccc.list --output=wumpus.ccc

cp wumpus.ccc ../../Mame64_old

