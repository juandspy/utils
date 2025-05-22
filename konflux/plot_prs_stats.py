"""
This script plots the stats (time opened and number of comments) of the PRs in the CSV file.
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np


KONFLUX_ONBOARDING_DATE = pd.to_datetime("2024-08-30T07:32:49+00:00")
INPUT_CSV_FILE = "aggregator.csv"
TIMES_BINS = 50
COMMENTS_BINS = 20

df = pd.read_csv(INPUT_CSV_FILE)

# Filter out rows where time_opened_seconds is NaN
df = df.dropna(subset=["time_opened_seconds"])

# Filter for only dependabot and konflux authors
df = df[df["author"].str.contains("dependabot|konflux", case=False, na=False)]

# Convert time_opened_seconds to hours for better readability
df["time_opened_minutes"] = df["time_opened_seconds"] / 60

# Convert date_created to datetime so that we can split before and after the Konflux onboarding
df["date_created"] = pd.to_datetime(df["date_created"])

# Split data into before and after the split date
before_split = df[df["date_created"] < KONFLUX_ONBOARDING_DATE]
after_split = df[df["date_created"] >= KONFLUX_ONBOARDING_DATE]

# Filter out zeros for log binning
before_time = before_split["time_opened_minutes"][
    before_split["time_opened_minutes"] > 0
]
after_time = after_split["time_opened_minutes"][after_split["time_opened_minutes"] > 0]

# Compute log bins for time histogram
all_times = pd.concat([before_time, after_time])
if not all_times.empty:
    min_time = all_times.min()
    max_time = all_times.max()
    bins = np.logspace(np.log10(min_time), np.log10(max_time), TIMES_BINS)
else:
    bins = TIMES_BINS  # fallback

# Create figure with two subplots
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))

# Plot time histograms in first subplot with log bins
ax1.hist(
    before_time,
    alpha=0.5,
    label=f"Before {KONFLUX_ONBOARDING_DATE.strftime('%b %d, %Y')}",
    bins=bins,
    color="blue",
    density=True,
)
ax1.hist(
    after_time,
    alpha=0.5,
    label=f"After {KONFLUX_ONBOARDING_DATE.strftime('%b %d, %Y')}",
    bins=bins,
    color="red",
    density=True,
)

ax1.set_xscale("log")
ax1.set_xlabel("Time Opened (minutes)")
ax1.set_ylabel("Density")
ax1.set_title(
    "Distribution of the time a PR was opened Before and After onboarding Konflux"
)
ax1.legend()
ax1.grid(True, alpha=0.3)

# Plot comments histograms in second subplot
ax2.hist(
    before_split["comments"],
    alpha=0.5,
    label=f"Before {KONFLUX_ONBOARDING_DATE.strftime('%b %d, %Y')}",
    bins=COMMENTS_BINS,
    color="blue",
    density=True,
)
ax2.hist(
    after_split["comments"],
    alpha=0.5,
    label=f"After {KONFLUX_ONBOARDING_DATE.strftime('%b %d, %Y')}",
    bins=COMMENTS_BINS,
    color="red",
    density=True,
)

ax2.set_xlabel("Number of Comments")
ax2.set_ylabel("Density")
ax2.set_title("Distribution of Comments per PR Before and After onboarding Konflux")
ax2.legend()
ax2.grid(True, alpha=0.3)

# Adjust layout to prevent overlap
plt.tight_layout()

# Save the plot
plt.savefig("pr_histogram.png")
plt.close()
