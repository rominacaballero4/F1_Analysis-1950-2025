# Formula 1 Race Winners Dashboard (1950-2025)

An interactive, multi-page Power BI dashboard that explores every Formula 1 race winner from 1950 to 2025: who won, for which team, where, and how the sport has changed over 75 years.


## Questions this dashboard answers

- Which drivers and teams have won the most races, and in which eras?
- How has the F1 calendar grown, and how has it spread across continents?
- Which countries and circuits have hosted the most races?
- How do the careers of the top drivers compare over time?

## Dashboard pages

| Page | What it shows |
|------|---------------|
| **Overview** | Key figures (total races, different winners, teams, circuits), wins per season and top winners. |
| **Driver analysis** | In-depth look at individual drivers: wins by year, team and circuit. |


## Data

- **File:** `data/winners_f1_1950_2025_v2.csv`
- **Source:** [(https://www.kaggle.com/datasets/julianbloise/winners-formula-1-1950-to-2025)]
- **Size:** 1,142 race wins (1,139 distinct races), 115 different winners, 77 circuits and 6 continents.
- **Columns:** `date`, `continent`, `grand_prix`, `circuit`, `winner_name`, `team`, `time`, `laps`, `year`

**Limitations:** the dataset only contains race winners. It has no grid positions, podiums, points or championship standings, so the dashboard does not cover those. The data ends on 3 August 2025, so the 2025 season is incomplete (14 races).

## Data preparation (Power Query)

Some issues in the raw data needed handling before analysis:

- **Grand prix names that are not countries.** Values such as Sakhir, San Marino, Styria and Abu Dhabi were mapped to a proper `country` column (Bahrain, Italy, Austria, United Arab Emirates) so they display correctly on maps. The original `grand_prix` column is kept.
- **Team names mix constructor and engine supplier** (e.g. "McLaren Mercedes", "McLaren Honda", "McLaren Ford"). A rule-based mapping creates a `constructor` column (37 constructors) and an `engine_supplier` column.
- **Shared drives.** Three races (France 1951, Argentina 1956, Great Britain 1957) have two rows because two drivers shared the winning car. They are valid records, so wins are counted per row and races are counted per distinct date.
- **Hidden characters.** Most `winner_name` values contained non-breaking spaces, which were replaced with normal spaces.
- **Race times.** Two shortened races were written as mm:ss (Malaysia 2009, Belgium 2021), so they are converted correctly to durations. Laps and race time are not used for cross-era comparisons because circuit lengths differ.
- A `race_no` column (chronological race number) supports the win streak calculation.
- Data types were set correctly (dates, whole numbers, durations).


## DAX measures

All measures live in a dedicated `_Measures` table (see `Measures.dax`). Examples:

```DAX
Total Races = DISTINCTCOUNT ( Races[date] )

Wins = COUNTROWS ( Races )

Selected Driver = SELECTEDVALUE ( Races\[winner\_name], "All drivers" )

Driver Win Streak =
VAR Nums = VALUES ( Races[race_no] )
VAR Starts = FILTER ( Nums, NOT ( ( Races[race_no] - 1 ) IN Nums ) )
VAR Lengths =
    ADDCOLUMNS (
        Starts,
        "@len",
            VAR s = Races[race_no]
            VAR e =
                MINX (
                    FILTER ( Nums, Races[race_no] >= s && NOT ( ( Races[race_no] + 1 ) IN Nums ) ),
                    Races[race_no]
                )
            RETURN e - s + 1
    )
RETURN MAXX ( Lengths, [@len] )
```

The streak measure finds the longest run of consecutive races won by the same driver (for example, Max Verstappen's 10 in a row in 2023).

## Key findings

- Lewis Hamilton leads all drivers with 105 wins, followed by Michael Schumacher (91) and Max Verstappen (65).
- Europe hosted about 60% of all races (686 of 1,142 win records), but the share of races in Asia and the Middle East has grown strongly in recent decades.
- Over the years the amount of races per season has been growing constanly. 

## Tools

- **Power BI Desktop** for modeling and visualization
- **Power Query** for data cleaning and transformation
- **DAX** for measures and calculations

## How to use this repository

1. Download the `.pbix` file from the `dashboard/` folder (Power Query script: `PowerQuery_Races.m`, DAX measures: `Measures.dax`).
2. Open it with [Power BI Desktop](https://www.microsoft.com/power-platform/products/power-bi/desktop) (free, Windows).
3. If the data source path breaks, go to **Home > Transform data > Data source settings** and point it to `data/winners_f1_1950_2025_v2.csv`.

## Repository structure

```
f1-dashboard/
├── dashboard/
│   └── f1_dashboard.pbix
├── data/
│   └── winners_f1_1950_2025_v2.csv
├── screenshots/
│   ├── 01_overview.png
│   ├── 02_driver_analysis.png
│   └── 03_geography.png
└── README.md
```

## Possible next steps

- Add pages for geography, constructors, eras/competitiveness and circuits.
- Add circuit coordinates for a point map.
- Extend the dataset with podiums and championship points.

## Author

**Romina Caballero**
Computer science student, Universidad de la Empresa
[GitHub][(https://github.com/rominacaballero4)] · caballeroromi4@gmail.com
