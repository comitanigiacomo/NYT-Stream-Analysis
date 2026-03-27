# Stream Analysis -- NYT Dataset

<a href="https://colab.research.google.com/github/comitanigiacomo/NYT-Stream-Analysis/blob/main/Stream_analysis.ipynb" target="_parent"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/></a>

## Overview
This repository contains the implementation and evaluation of two fundamental data streaming algorithms: **Flajolet-Martin** and **Bloom Filter**. The project focuses on analyzing a massive dataset of New York Times comments from 2020 within a strictly memory-constrained environment.

The main goal is to demonstrate how to efficiently process large data streams using $O(1)$ space complexity and linear time complexity $O(N)$, without loading the entire dataset into RAM.

## Implemented Algorithms

1. **Flajolet-Martin:** Used to estimate the total number of unique active users who commented on the NYT platform. The implementation utilizes bitwise operations to isolate trailing zeros and applies grouping/median techniques (with a correction factor) to mitigate variance and achieve an accurate estimate (relative error ~5%).
   
2. **Bloom Filter:** Used to efficiently isolate and count comments related specifically to "Science" articles. Parameters were chosen based on theoretical mathematical formulas to minimize the False Positive Rate (achieving a real FPR of ~0.3%).

## Dataset Handling
The project utilizes the **New York Times Comments (2020)** dataset. 
*All experimental results refer to the dataset version downloaded on March 20, 2026.*

To respect the constraints of data streaming and avoid memory overflow, the data is processed using **lazy evaluation** via Python's `yield` generator. This allows the algorithms to scan over 13 million lines of data step-by-step, maintaining an extremely low memory footprint.