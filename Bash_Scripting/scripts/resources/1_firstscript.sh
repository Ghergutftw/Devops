#!/bin/bash

### This script prints system info ###

echo "Welcome to bash script."
echo

#checking systemt uptime
echo "#####################################"
echo "The uptime of the system is: "
uptime
echo

# Memory Utilization
echo "#####################################"
echo "Memory Utilization"
free -m
echo

# Disk Utilization
echo "#####################################"
echo "Disk Utilization"
df -h

echo
# CPU Utilization
echo "#####################################"
echo "CPU Utilization"
top -b -n1 | grep "Cpu(s)"
echo

# System Information
echo "#####################################"
echo "System Information"
uname -a
echo
