for S in /media/mmcblk0p2/scripts/*.sh
do
  A=$(basename $S .sh)
  alias $A="$S"
done
