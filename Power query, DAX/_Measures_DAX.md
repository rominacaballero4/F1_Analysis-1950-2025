// =====================================================================

// F1 race winners 1950-2025  |  DAX measures

//

// SETUP

// 1. Home > Enter data > leave it empty, name it "\_Measures", Load

//    (a table that only holds measures, so they are easy to find)

// 2. Select \_Measures > Modeling > New measure, and paste ONE measure at a

//    time (each block below starting with its name is one measure)

// 3. The table must be called "Races" and have the columns created by

//    PowerQuery\_Races.m (year, date, race\_no, winner\_name, constructor,

//    engine\_supplier, country, continent, circuit)

// 4. In the Data pane, set Races\[year] to "Don't summarize"

//

// NOTE: each row of Races is one WIN. Three races (1951 France, 1956

// Argentina, 1957 Great Britain) have two rows because the winning car was

// shared, so rows = 1,142 but distinct races = 1,139.

// =====================================================================





// ---------------------------------------------------------------------

// 1. BASICS (cards, totals)

// ---------------------------------------------------------------------



Total Races = DISTINCTCOUNT ( Races\[date] )



Wins = COUNTROWS ( Races )




Constructors = DISTINCTCOUNT ( Races\[constructor] )



Seasons = DISTINCTCOUNT ( Races\[year] )




Races per Season = DIVIDE ( \[Total Races], \[Seasons] )



/// ---------------------------------------------------------------------

// 2. DRIVER PAGE (react to the driver picker)

// ---------------------------------------------------------------------



// Page title: the selected driver, or "All drivers" if none/many selected

Selected Driver = SELECTEDVALUE ( Races\[winner\_name], "All drivers" )



// Years as TEXT so they never display as 2,023

First Win Year =

VAR Y = MIN ( Races\[year] )

RETURN

&#x20;   IF ( ISBLANK ( Y ), BLANK (), FORMAT ( Y, "0" ) )



Last Win Year =

VAR Y = MAX ( Races\[year] )

RETURN

&#x20;   IF ( ISBLANK ( Y ), BLANK (), FORMAT ( Y, "0" ) )



Years Between First and Last Win = IF ( ISBLANK ( \[First Win Year] ), BLANK (), \[Last Win Year] - \[First Win Year] + 1 )



// Card text: "1981 - 1993"

Active Years =

IF ( ISBLANK ( \[First Win Year] ), BLANK (), \[First Win Year] \& " - " \& \[Last Win Year] )



Best Season Wins = MAXX ( VALUES ( Races\[year] ), \[Wins] )



// Every season that reached the maximum, as text: "1984, 1988, 1993"

Best Season =

VAR T = ADDCOLUMNS ( VALUES ( Races\[year] ), "@w", \[Wins] )

VAR M = MAXX ( T, \[@w] )

RETURN

&#x20;   CONCATENATEX ( FILTER ( T, \[@w] = M ), FORMAT ( Races\[year], "0" ), ", ", Races\[year], ASC )



// Card text: "2023 (19 wins)"

Best Season Label =

IF ( ISBLANK ( \[Best Season Wins] ), BLANK (), \[Best Season] \& " (" \& \[Best Season Wins] \& " wins)" )



// ---------------------------------------------------------------------

// 3. WIN STREAKS (consecutive races won by the same driver)

//    Uses Races\[race\_no] from Power Query. Island method: a streak starts

//    at a race number whose previous number is not in the list, and ends

//    at the first number whose next number is not in the list.

// ---------------------------------------------------------------------



// Longest streak for ONE driver (filter context = that driver)

Driver Win Streak =

VAR Nums = VALUES ( Races\[race\_no] )

VAR Starts =

&#x20;   FILTER ( Nums, NOT ( ( Races\[race\_no] - 1 ) IN Nums ) )

VAR Lengths =

&#x20;   ADDCOLUMNS (

&#x20;       Starts,

&#x20;       "@len",

&#x20;           VAR s = Races\[race\_no]

&#x20;           VAR e =

&#x20;               MINX (

&#x20;                   FILTER (

&#x20;                       Nums,

&#x20;                       Races\[race\_no] >= s

&#x20;                           \&\& NOT ( ( Races\[race\_no] + 1 ) IN Nums )

&#x20;                   ),

&#x20;                   Races\[race\_no]

&#x20;               )

&#x20;           RETURN

&#x20;               e - s + 1

&#x20;   )

RETURN

&#x20;   MAXX ( Lengths, \[@len] )



// Use this one in visuals: works for one driver or for all of them

Longest Win Streak =

MAXX ( VALUES ( Races\[winner\_name] ), \[Driver Win Streak] )





// ---------------------------------------------------------------------

// 4. DYNAMIC TEXT (titles, subtitles, footnotes)

// ---------------------------------------------------------------------



// Ignores every filter, so it always shows the last date in the dataset

// (3 Aug 2025) on every page, and forces English month names.

Data Note =

"Race winners only. Data up to "

&#x20;   \& FORMAT ( CALCULATE ( MAX ( Races\[date] ), ALL ( Races ) ), "d mmm yyyy", "en-US" )

&#x20;   \& " (the 2025 season is incomplete)."

