#!/bin/sh

CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
GPU_TEMP=$(/opt/vc/bin/vcgencmd measure_temp | cut -d= -f2)

echo "--"
echo "Model: $(cat /sys/firmware/devicetree/base/model)"
echo "--"
echo "GPU temperature: $GPU_TEMP"
echo "CPU temperature: $(echo "scale=1;$CPU_TEMP / 1000" | bc -l)'C"
echo "--"
