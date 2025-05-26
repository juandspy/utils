"""
This script plots a histogram showing the number of PRs created per week.
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Read the CSV file
INPUT_CSV_FILE = "aggregator.csv"
MOVING_AVERAGE_WINDOW = 12

df = pd.read_csv(INPUT_CSV_FILE)

# Convert date_created to datetime
df["date_created"] = pd.to_datetime(df["date_created"])

# Filter for only dependabot and konflux authors
df = df[df["author"].str.contains("dependabot|konflux", case=False, na=False)]

# Create a new column with the week number
df["week"] = df["date_created"].dt.isocalendar().week
df["year"] = df["date_created"].dt.isocalendar().year

# Create a combined year-week column for proper chronological ordering
df["year_week"] = df["year"].astype(str) + "-W" + df["week"].astype(str).str.zfill(2)

# Count PRs per week
weekly_counts = df.groupby("year_week").size()

# Calculate the average number of PRs per week
avg_prs = weekly_counts.mean()

# Calculate 4-week moving average
moving_avg = weekly_counts.rolling(window=MOVING_AVERAGE_WINDOW, min_periods=1).mean()

# Create the plot
plt.figure(figsize=(15, 6))
weekly_counts.plot(kind="bar", alpha=0.7, label="Weekly PRs")

# Add horizontal line for the overall average
plt.axhline(
    y=avg_prs,
    color="r",
    linestyle="--",
    label=f"Overall Average: {avg_prs:.1f} PRs/week",
)

# Add line for the moving average
plt.plot(
    moving_avg.index,
    moving_avg.values,
    "g-",
    linewidth=2,
    label=f"{MOVING_AVERAGE_WINDOW}-week Moving Average",
)

# Customize the plot
plt.title("Number of PRs Created per Week")
plt.xlabel("Week")
plt.ylabel("Number of PRs")

# Set x-ticks to show one tick every 4 weeks
ticks = weekly_counts.index[::4]  # Get every 4th week
plt.xticks(range(len(weekly_counts))[::4], ticks, rotation=45, ha="right")

plt.grid(True, alpha=0.3)
plt.legend()

# Adjust layout to prevent label cutoff
plt.tight_layout()

# Save the plot
plt.savefig("weekly_prs_histogram.png")
plt.close()
