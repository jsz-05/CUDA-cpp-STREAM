#!/bin/bash

# Define the list of array sizes (N) to test
declare -a N_ARRAY=(10000 100000 1000000 10000000 100000000 500000000 1000000000 2000000000)

# Define the models to test
declare -a MODELS=("" "-DHOST" "-DZERO_COPY")
declare -a MODEL_NAMES=("HBM" "ManagedHost" "LPDDR5NoMigrate")

# Define CSV file header, matching the full output
HEADER="N,Copy_Rate,Copy_AvgTime,Copy_MinTime,Copy_MaxTime,Scale_Rate,Scale_AvgTime,Scale_MinTime,Scale_MaxTime,Add_Rate,Add_AvgTime,Add_MinTime,Add_MaxTime,Triad_Rate,Triad_AvgTime,Triad_MinTime,Triad_MaxTime,ThreeAdd_Rate,ThreeAdd_AvgTime,ThreeAdd_MinTime,ThreeAdd_MaxTime,TwoCopy_Rate,TwoCopy_AvgTime,TwoCopy_MinTime,TwoCopy_MaxTime"

# Get the path to the directory containing the stream.cu file
STREAM_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")

# Loop through each model
for i in "${!MODELS[@]}"; do
    MODEL="${MODELS[$i]}"
    MODEL_NAME="${MODEL_NAMES[$i]}"

    echo "================================================="
    echo "Running benchmark for Model: $MODEL_NAME"
    echo "Compilation flags: $MODEL"
    echo "================================================="

    # Change to the stream directory to run make commands
    cd "$STREAM_DIR" || exit

    # Compile the CUDA code with the current model flag
    make clean
    make MODEL="$MODEL"

    # Change back to the tests directory to save the output
    cd - || exit

    # Define the output CSV file name
    OUTPUT_FILE="stream_${MODEL_NAME}.csv"
    echo "$HEADER" > "$OUTPUT_FILE"

    # Loop through each array size and run the benchmark
    for N in "${N_ARRAY[@]}"; do
        echo "Running with N = $N..."

        # Run the benchmark from the parent directory and parse ALL metrics
        "$STREAM_DIR"/stream -n "$N" -s -b 1024 | awk -v size="$N" '
        /Copy:/ {copy_rate=$2; copy_avg=$3; copy_min=$4; copy_max=$5}
        /Scale:/ {scale_rate=$2; scale_avg=$3; scale_min=$4; scale_max=$5}
        /Add:/ {add_rate=$2; add_avg=$3; add_min=$4; add_max=$5}
        /Triad:/ {triad_rate=$2; triad_avg=$3; triad_min=$4; triad_max=$5}
        /ThreeAdd:/ {threeadd_rate=$2; threeadd_avg=$3; threeadd_min=$4; threeadd_max=$5}
        /TwoCopy:/ {twocopy_rate=$2; twocopy_avg=$3; twocopy_min=$4; twocopy_max=$5}
        END {
            printf "%d,%.2f,%.8f,%.8f,%.8f,%.2f,%.8f,%.8f,%.8f,%.2f,%.8f,%.8f,%.8f,%.2f,%.8f,%.8f,%.8f,%.2f,%.8f,%.8f,%.8f,%.2f,%.8f,%.8f,%.8f\n",
                size,
                copy_rate, copy_avg, copy_min, copy_max,
                scale_rate, scale_avg, scale_min, scale_max,
                add_rate, add_avg, add_min, add_max,
                triad_rate, triad_avg, triad_min, triad_max,
                threeadd_rate, threeadd_avg, threeadd_min, threeadd_max,
                twocopy_rate, twocopy_avg, twocopy_min, twocopy_max
        }
        ' >> "$OUTPUT_FILE"
    done

    # Clean up the compiled executable before the next model
    make -C "$STREAM_DIR" clean
done

echo "Benchmark complete. Results saved in the tests directory."