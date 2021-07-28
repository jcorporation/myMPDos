#!/bin/sh

CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
GPU_TEMP=$(/opt/vc/bin/vcgencmd measure_temp | cut -d= -f2)
VOLTS_CORE=$(/opt/vc/bin/vcgencmd measure_volts core | cut -d= -f2)
CLOCK_CORE=$(/opt/vc/bin/vcgencmd measure_clock arm | cut -d= -f2)
THROTTLED_MASK=$(/opt/vc/bin/vcgencmd get_throttled | cut -d= -f2)

echo "--"
echo "Model: $(cat /sys/firmware/devicetree/base/model)"
echo "--"
echo "GPU temperature: $GPU_TEMP"
echo "CPU temperature: $(echo "scale=1;$CPU_TEMP / 1000" | bc -l)'C"
echo "--"
echo "Core voltage: $VOLTS_CORE"
echo "Core clock: $(echo "scale=1;$CLOCK_CORE / 1000" | bc -l)Mhz"
echo "--"
[ $(( $THROTTLED_MASK & 0x80000 )) = $(( 0x80000 )) ] && echo "Soft temperature limit has occurred"
[ $(( $THROTTLED_MASK & 0x40000 )) = $(( 0x40000 )) ] && echo "Throttling has occurred"
[ $(( $THROTTLED_MASK & 0x20000 )) = $(( 0x20000 )) ] && echo "Arm frequency capping has occurred"
[ $(( $THROTTLED_MASK & 0x10000 )) = $(( 0x10000 )) ] && echo "Under-voltage has occurred"
[ $(( $THROTTLED_MASK & 0x8 )) = $(( 0x8 )) ] && echo "Soft temperature limit active"
[ $(( $THROTTLED_MASK & 0x4 )) = $(( 0x4 )) ] && echo "Currently throttled"
[ $(( $THROTTLED_MASK & 0x2 )) = $(( 0x2 )) ] && echo "Arm frequency capped"
[ $(( $THROTTLED_MASK & 0x1 )) = $(( 0x1 )) ] && echo "Under-voltage detected"
