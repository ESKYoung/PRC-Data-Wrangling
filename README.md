# PRC-Data-Wrangling

This repository contains a R script to import Excel-versions of the [Police recorded crime open data tables](https://www.gov.uk/government/statistics/police-recorded-crime-open-data-tables). It aggregates this data at the offence subgroup-level, and outputs both the combined raw, and processed datasets.

## Instructions

The following instructions only general ones &mdash; you may want to look at the comments in more detail at Step 6, and modify it accordingly instead.

1. Download each of the [Police recorded crime open data tables](https://www.gov.uk/government/statistics/police-recorded-crime-open-data-tables) at the Community Safety Partnership-level;
2. Open each file in Excel, and save as either a `.xlsx` or `.xls` file;
3. Create a new folder where you have saved the `.Rproj`, and `.R` file, labelled `01 Raw Data`;
4. Move the files into the `01 Raw Data` folder;
5. Open the [`PRC-Data-Wrangling.Rproj`](/PRC-Data-Wrangling.Rproj) file;
6. Open the [`PRC-Data-Wrangling.R`](/PRC-Data-Wrangling.R) file; and 
7. Source the file.

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

### Unifying names

There are some differences in spelling across the columns in the raw dataset. The R script is designed to resolve these differences, but the .csv files have **not** been included with this code for now.

The R script loads various name unification `.csv` files help to unify the names using the following code:

```r
list.uni <- lapply(file.path(dir.raw, kUniFileNames),
                   function (x) {
                     as.data.table(read.csv(x))
                   })
```

The names are then unified using near-identical code blocks; here's an example for the `Force Name` column:

```r
setkey(data.raw, "Force.Name")
setkey(list.uni$Force, "Force.Name")
data.raw[list.uni$Force, Force.Name := Unified.Force]
```

To use the R script without name unification, remove these two code blocks. To generate your own name unification `.csv` files, follow these example steps for the `Force Name` column:

1. Get all unique `Force Name`s from the entire raw dataset;
2. Put the data under a column labelled `Force Name`;
3. Create a second column labelled `Unified Force`;
4. Manually assign the unified force for each unique force name in the `Unified Force` column;
5. Save the file as a `.csv` file in the `01 Raw Data` folder; and
6. Enter the file name in this code block: `kUniForce <- "[file name].csv"`

Repeat the above six steps to unify all the names, looking in the R script for the required code in Steps 3, and 6.

### Merging CSP names

In the raw dataset, several Community Safety Partnerships (CSPs) have, over time, been merged together. To ensure continuity, a separate column is generated in the dataset labelled `Mapped CSP`. The `.csv` file to determine these mapped CSPs has **not** been included with this code for now.

The R script loads this `.csv` file using the following code block:

```r
data.mCSP <- read.csv(file = file.path(dir.raw, kMergedCSP))
```

The individual CSPs are then mapped using the following left-join code block:

```r
data.raw <- merge(data.raw, data.mCSP[, !(names(data.mCSP) %in% "Change")], 
                  by = "CSP.Name",
                  all.x = TRUE,
                  sort = FALSE)
```

An AQA step follows to ensure the left-join has not resulted in any `NA` values:

```r
stopifnot(all(!is.na(data.raw$Mapped.CSP)))
```

To use the R script without mapping merged CSPs, remove these three code blocks. To generate your own mapping `.csv` file, follow these steps:

1. Get all the `CSP Name`s from the dataset (ideally after [unifying names](/README.md#unifying-names));
2. Put the data under a column labelled `CSP Name`;
3. Create a second column labelled `Mapped CSP`;
4. Manually assign the merged CSP name for each unique CSP name in the `Mapped CSP` column;
5. Save the file as a `.csv` file in the `01 Raw Data` folder; and
6. Enter the file name in this code block: `kMergedCSP <- "[file name].csv"`

## Licence

This code is supplied under the Apache License 2.0 licence.
