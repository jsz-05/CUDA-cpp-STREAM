#!/bin/bash
OUTPUT="zerocopy.csv"
echo "N,Copy_Read,Copy_Write,Scale_Read,Scale_Write,Add_Read,Add_Write,Triad_Read,Triad_Write" > $OUTPUT

for n in 10000 100000 1000000 10000000 100000000 500000000 1000000000 2000000000
do
    echo "Running n=$n..."
    ../stream -n $n -s -b 1024 | awk '
        /Copy:/  {copy_r=$2; copy_w=$3}
        /Scale:/ {scale_r=$2; scale_w=$3}
        /Add:/   {add_r=$2; add_w=$3}
        /Triad:/ {triad_r=$2; triad_w=$3}
        END {
            printf "%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n",
                '"$n"',
                copy_r, copy_w,
                scale_r, scale_w,
                add_r, add_w,
                triad_r, triad_w
        }
    ' >> $OUTPUT
done
echo "Results saved to $OUTPUT"
