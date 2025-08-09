#!/bin/bash

# List of array sizes to test
N_ARRAY=(100000000 500000000 1000000000)

# Output CSV file
OUTPUT_FILE="cpu_stream_results.csv"

# CSV header: 4 kernels × (Rate, Avg, Min, Max) + N
HEADER="N,Copy_Rate,Copy_AvgTime,Copy_MinTime,Copy_MaxTime,Scale_Rate,Scale_AvgTime,Scale_MinTime,Scale_MaxTime,Add_Rate,Add_AvgTime,Add_MinTime,Add_MaxTime,Triad_Rate,Triad_AvgTime,Triad_MinTime,Triad_MaxTime"
echo "$HEADER" > "$OUTPUT_FILE"

# Loop through sizes
for N in "${N_ARRAY[@]}"; do
    echo "Running CPU STREAM with N = $N"

    # Run benchmark via Docker
    OUTPUT=$(sudo docker run --rm nvcr.io/nvidia/hpc-benchmarks:24.06 ./stream-cpu-test.sh --n "$N")

    # Parse all 4 kernels
    copy=$(echo "$OUTPUT" | grep "^Copy:" | awk '{printf "%.2f,%.8f,%.8f,%.8f", $2, $3, $4, $5}')
    scale=$(echo "$OUTPUT" | grep "^Scale:" | awk '{printf "%.2f,%.8f,%.8f,%.8f", $2, $3, $4, $5}')
    add=$(echo "$OUTPUT" | grep "^Add:" | awk '{printf "%.2f,%.8f,%.8f,%.8f", $2, $3, $4, $5}')
    triad=$(echo "$OUTPUT" | grep "^Triad:" | awk '{printf "%.2f,%.8f,%.8f,%.8f", $2, $3, $4, $5}')

    # Confirm all data present
    if [[ -n "$copy" && -n "$scale" && -n "$add" && -n "$triad" ]]; then
        echo "$N,$copy,$scale,$add,$triad" >> "$OUTPUT_FILE"
    else
        echo "Warning: Missing output for N=$N — skipping"
    fi
done

echo "CPU STREAM sweep complete. Results saved to: $OUTPUT_FILE"
