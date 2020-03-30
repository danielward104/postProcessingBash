#!/bin/bash
#
# Use the cwd
#$ -cwd
# Export variable 
#$ -V
# Request time
#$ -l h_rt=48:00:00
# Request memory/core
#$ -l h_vmem=4G
# Request number of processors
#$ -pe ib 1
# Send email when starting/finishing
# -m be
# Send to maths node.
#$ -P maths

python postProcess.py
