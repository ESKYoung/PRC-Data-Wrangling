# PRC-Data-Wrangling

This repository contains a R script to import Excel-versions of the [Police recorded crime open data tables](https://www.gov.uk/government/statistics/police-recorded-crime-open-data-tables). It aggregates this data at the offence subgroup-level, and outputs both the processed dataset.

## Instructions

The following instructions only general ones &mdash; you may want to look at the comments in more detail at Step 6, and modify it accordingly instead.

1. Download each of the [Police recorded crime open data tables](https://www.gov.uk/government/statistics/police-recorded-crime-open-data-tables) at the Community Safety Partnership-level;
2. Open each file in Excel, and save as either a `.xlsx` or `.xls` file;
3. Move the files into a folder labelled `01 Raw Data`;
4. Open the `PRC-Data-Wrangling.Rproj` file;
5. Open the `PRC Data Wrangling.R` file; and 
6. Source the file.

## Code requirements

This code was written using R (3.4.1), and RStudio. The R script requires the following packages:
1. `data.table`;
2. `magrittr`;
3. `readxl`; and
4. `zoo`;

as well as all their dependencies.

It is assumed that the raw datasets have the following columns names, in the following order:
1. `Financial Year`;
2. `Financial Quarter`;
3. `Force Name`;
4. `CSP Name`;
5. `Offence Description`;
6. `Offence Group`;
7. `Offence Subgroup`;
8. `Offence Code`; and
9. `Number of Offences`.

## Licence

This code is supplied under the Apache License 2.0 licence.
