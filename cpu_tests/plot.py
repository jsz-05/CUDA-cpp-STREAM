import pandas as pd
import matplotlib.pyplot as plt

csv_file = "cpu_stream_results.csv"
kernels  = ["Copy", "Scale", "Add", "Triad"]

df = pd.read_csv(csv_file)

x = df["N"].to_numpy().flatten()            # 1-D for sure

for k in kernels:
    y_mb  = df[f"{k}_Rate"].to_numpy().flatten()   # MB/s to 1-D
    y_gb  = y_mb / 1024.0                         # convert to GB/s
    plt.plot(x, y_gb, marker="o", label=k)

# plt.xscale("log")
plt.xlabel("Array Size (N)")
plt.ylabel("Bandwidth (GB/s)")     # now in GB/s
plt.title("CPU STREAM – Bandwidth vs. Array Size")
plt.grid(True, which="both", ls="--", lw=0.6)
plt.legend()
plt.tight_layout()
plt.savefig("cpu_stream_bandwidth.png", dpi=300)
# plt.show()
