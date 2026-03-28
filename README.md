# NYT Stream Analysis

> [!NOTE]  
> This repository contains the final project for the _Algorithms for Massive Datasets_ course at Università degli Studi di Milano (2025/2026). You can find the notes for the course in this [repository](https://github.com/Favo02/algorithms-for-massive-datasets?tab=readme-ov-file).

## Overview

This project implements and evaluates two fundamental data streaming algorithms: **Flajolet-Martin** and **Bloom Filter**. The objective is to analyze a massive dataset of New York Times comments (from 2020) within a strictly memory-constrained environment. 

The main goal is to demonstrate how to efficiently process large data streams using $O(1)$ space complexity and linear $O(N)$ time complexity, completely avoiding loading the entire dataset into RAM.

## Implemented Algorithms

* **Flajolet-Martin:** Estimates the total number of unique active users who commented on the NYT platform. The implementation utilizes bitwise operations to isolate trailing zeros and applies grouping/median techniques (with a correction factor) to mitigate variance and achieve an accurate estimate (relative error ~5%).
   
* **Bloom Filter:** Efficiently isolates and counts comments related specifically to "Science" articles. Parameters were chosen based on theoretical mathematical formulas to minimize the False Positive Rate (achieving a real FPR of ~0.3%).

## Dataset

The project utilizes the **New York Times Comments (2020)** dataset.

> [!NOTE]
> *All experimental results refer to the dataset version downloaded on March 20, 2026.*

All the implementations can be found in the [`Stream_analysis.ipynb`](/Stream_analysis.ipynb) notebook. 

You can run the code directly in your browser using Google Colab:  
<a href="https://colab.research.google.com/github/comitanigiacomo/NYT-Stream-Analysis/blob/main/Stream_analysis.ipynb" target="_parent"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/></a>

## Full Report

To understand all the decisions and sources that led to the final implementations, please refer to the [report](/report/Report.pdf)