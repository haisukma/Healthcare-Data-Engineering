# Healthcare Data Engineering Project

## Overview

This project demonstrates an end-to-end data engineering workflow, starting from raw operational data (OLTP) to analytical processing (OLAP). The goal is to transform healthcare-related data into meaningful insights through structured pipelines and optimized database design.

---

## Tech Stack

* SQL (PostgreSQL/MySQL)
* Data Cleaning & Transformation
* ETL Pipeline Design
* OLTP & OLAP Database Modeling

---

## Project Structure

```
.
├── sql/
│   ├── oltp/               # OLTP schema and queries
│   ├── olap/               # OLAP schema (star/snowflake)
│   ├── etl/                # ETL scripts
│   └── data_cleaning/      # Data cleaning queries
│
├── erd/
│   ├── erd_OLAP/                # ERD diagrams (OLAP)
│   └── erd_OLTP/                # ERD diagrams (OLTP)
│
├── results/
│   ├──  analytical_queries_OLAP/
│   ├──  analytical_queries_OLTP/
│   └── report/             # Final report (PDF)
│
└── README.md
```

---

## Data Pipeline

### 1. OLTP Database

* Designed normalized schema for transactional data
* Ensured data integrity using primary and foreign keys

### 2. Data Cleaning

* Handled missing values
* Standardized inconsistent formats
* Removed duplicates and anomalies

### 3. ETL Process

* Extracted data from OLTP tables
* Transformed into analytical format
* Loaded into OLAP schema

### 4. OLAP Database

* Designed dimensional model (fact & dimension tables)
* Optimized for analytical queries

---

## Key Analysis

* Diagnosis distribution by category
* Profit and loss analysis
* Average claim duration
* Most frequent diseases
* Drug selection patterns

---

## Highlights

* End-to-end data pipeline implementation
* OLTP to OLAP transformation
* Real-world healthcare dataset simulation
* Query optimization for analytical workloads

---

## Contact

If you have any questions or feedback, feel free to reach out.

---
