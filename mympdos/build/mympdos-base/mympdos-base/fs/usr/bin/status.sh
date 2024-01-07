#!/bin/sh

# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2024 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos

TEMP=$(vcgencmd measure_temp | cut -d= -f2)
VOLTS_CORE=$(vcgencmd measure_volts core | cut -d= -f2 | sed 's/V/ V/')
CLOCK_CORE=$(vcgencmd measure_clock arm | cut -d= -f2)
THROTTLED_MASK=$(vcgencmd get_throttled | cut -d= -f2)

echo "myMPDos:      $(cat /boot/myMPDos.version)"
echo "Model:        $(cat /sys/firmware/devicetree/base/model)"
echo "Temperature:  $TEMP"
echo "Core voltage: $VOLTS_CORE"
echo "Core clock:   $(echo "scale=0;$CLOCK_CORE / 1000000" | bc -l) MHz"
if [ "$THROTTLED_MASK" != "0x0" ]
then
  echo ""
  echo "WARNING"
  [ $(( $THROTTLED_MASK & 0x80000 )) = $(( 0x80000 )) ] && echo "Soft temperature limit has occurred"
  [ $(( $THROTTLED_MASK & 0x40000 )) = $(( 0x40000 )) ] && echo "Throttling has occurred"
  [ $(( $THROTTLED_MASK & 0x20000 )) = $(( 0x20000 )) ] && echo "Arm frequency capping has occurred"
  [ $(( $THROTTLED_MASK & 0x10000 )) = $(( 0x10000 )) ] && echo "Under-voltage has occurred"
  [ $(( $THROTTLED_MASK & 0x8 )) = $(( 0x8 )) ] && echo "Soft temperature limit active"
  [ $(( $THROTTLED_MASK & 0x4 )) = $(( 0x4 )) ] && echo "Currently throttled"
  [ $(( $THROTTLED_MASK & 0x2 )) = $(( 0x2 )) ] && echo "Arm frequency capped"
  [ $(( $THROTTLED_MASK & 0x1 )) = $(( 0x1 )) ] && echo "Under-voltage detected"
fi
