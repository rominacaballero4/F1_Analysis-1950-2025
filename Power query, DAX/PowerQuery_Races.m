// =====================================================================
// F1 race winners 1950-2025  |  Power Query (M) for query "Races"
//
// HOW TO USE
// 1. Home > Transform data
// 2. Select your existing query (winners_f1_1950_2025_v2 (2)) >
//    Home > Advanced Editor
// 3. Delete everything and paste this whole script
// 4. Change the file path in the "Source" step to where your CSV is
// 5. Click Done, then Close & Apply
// 6. Rename the table to "Races" (Model view or Data pane) and check
//    that your visuals still work
// =====================================================================
let
    // ---- 1. LOAD ---------------------------------------------------
    Source = Csv.Document(
        File.Contents("C:\Users\YOUR_USER\Documents\winners_f1_1950_2025_v2.csv"),
        [Delimiter = ",", Columns = 9, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // ---- 2. CLEAN TEXT ---------------------------------------------
    // winner_name contains non-breaking spaces (character 160) in most
    // rows. They look like normal spaces but break searching/matching.
    CleanText = (t as nullable text) as nullable text =>
        if t = null then null
        else Text.Trim(Text.Replace(t, Character.FromNumber(160), " ")),

    Cleaned = Table.TransformColumns(
        Promoted,
        {
            {"continent",   CleanText, type text},
            {"grand_prix",  CleanText, type text},
            {"circuit",     CleanText, type text},
            {"winner_name", CleanText, type text},
            {"team",        CleanText, type text}
        }
    ),

    // ---- 3. DATA TYPES ---------------------------------------------
    // Most times are hh:mm:ss, but two shortened races are written as
    // mm:ss ("55:30" Malaysia 2009, "3:27" Belgium 2021). Adding "00:"
    // in front stops them being read as hours:minutes.
    FixTime = Table.TransformColumns(
        Cleaned,
        {{
            "time",
            each
                let
                    colons = Text.Length(_) - Text.Length(Text.Replace(_, ":", ""))
                in
                    Duration.FromText(if colons = 1 then "00:" & _ else _),
            type duration
        }}
    ),

    // If the laps conversion shows an error, change Int64.Type to
    // type number for that column.
    Typed = Table.TransformColumnTypes(
        FixTime,
        {{"date", type date}, {"laps", Int64.Type}, {"year", Int64.Type}},
        "en-US"
    ),

    // ---- 4. RACE NUMBER --------------------------------------------
    // 1 = first race in 1950, increasing by date. Shared drives (two
    // winners on the same date) get the same number. Used for streaks.
    RaceDates = List.Buffer(List.Sort(List.Distinct(Table.Column(Typed, "date")))),
    AddRaceNo = Table.AddColumn(
        Typed,
        "race_no",
        each List.PositionOf(RaceDates, [date]) + 1,
        Int64.Type
    ),

    // ---- 5. COUNTRY (for maps) -------------------------------------
    // grand_prix is not always a country. Everything not listed below
    // keeps its grand_prix value.
    CountryMap = [
        #"Great Britain" = "United Kingdom",
        Sakhir           = "Bahrain",
        #"San Marino"    = "Italy",
        Styria           = "Austria",
        #"Abu Dhabi"     = "United Arab Emirates",
        Turkiye          = "Turkey"
    ],
    AddCountry = Table.AddColumn(
        AddRaceNo,
        "country",
        each Record.FieldOrDefault(CountryMap, [grand_prix], [grand_prix]),
        type text
    ),

    // ---- 6. CONSTRUCTOR + ENGINE SUPPLIER --------------------------
    // The team column mixes the constructor and the engine supplier
    // ("McLaren Mercedes", "McLaren Honda"...). Each row below is
    // {text the team name starts with, constructor name}.
    // ORDER MATTERS: the first match wins, so "Mercedes-Benz" must come
    // before "Mercedes".
    ConstructorMap = {
        {"Mercedes-Benz",   "Mercedes"},
        {"Mercedes",        "Mercedes"},
        {"Red Bull Racing", "Red Bull"},
        {"RBR",             "Red Bull"},
        {"STR",             "Toro Rosso"},
        {"AlphaTauri",      "AlphaTauri"},
        {"Alpine",          "Alpine"},
        {"Alfa Romeo",      "Alfa Romeo"},
        {"Benetton",        "Benetton"},
        {"BRM",             "BRM"},
        {"Brabham",         "Brabham"},
        {"Brawn",           "Brawn"},
        {"Cooper",          "Cooper"},
        {"Eagle",           "Eagle"},
        {"Epperly",         "Epperly"},
        {"Ferrari",         "Ferrari"},
        {"Hesketh",         "Hesketh"},
        {"Honda",           "Honda"},
        {"Jordan",          "Jordan"},
        {"Kurtis Kraft",    "Kurtis Kraft"},
        {"Kuzma",           "Kuzma"},
        {"Ligier",          "Ligier"},
        {"Lotus",           "Lotus"},
        {"March",           "March"},
        {"Maserati",        "Maserati"},
        {"Matra",           "Matra"},
        {"McLaren",         "McLaren"},
        {"Penske",          "Penske"},
        {"Porsche",         "Porsche"},
        {"Racing Point",    "Racing Point"},
        {"Renault",         "Renault"},
        {"Sauber",          "Sauber"},
        {"Shadow",          "Shadow"},
        {"Stewart",         "Stewart"},
        {"Tyrrell",         "Tyrrell"},
        {"Vanwall",         "Vanwall"},
        {"Watson",          "Watson"},
        {"Williams",        "Williams"},
        {"Wolf",            "Wolf"}
    },

    FindMatch = (team as text) =>
        List.First(
            List.Select(ConstructorMap, (m) => Text.StartsWith(team, m{0})),
            null
        ),

    AddMatch = Table.AddColumn(AddCountry, "ctor_match", each FindMatch([team])),

    // constructor: mapped name, or the original team name if no match
    AddConstructor = Table.AddColumn(
        AddMatch,
        "constructor",
        each let m = [ctor_match] in if m = null then [team] else m{1},
        type text
    ),

    // engine_supplier: whatever follows the constructor in the team name
    // ("McLaren Mercedes" -> "Mercedes"). Works teams such as "Ferrari"
    // have no supplier in the text, so they become "Not specified".
    AddEngine = Table.AddColumn(
        AddConstructor,
        "engine_supplier",
        each
            let
                m = [ctor_match],
                rest = if m = null then "" else Text.Trim(Text.Middle([team], Text.Length(m{0})))
            in
                if rest = "" then "Not specified" else rest,
        type text
    ),

    Result = Table.RemoveColumns(AddEngine, {"ctor_match"}),

    // ---- 7. SORT AND COLUMN ORDER ----------------------------------
    Ordered = Table.ReorderColumns(
        Result,
        {"race_no", "date", "year", "continent", "country", "grand_prix", "circuit",
         "winner_name", "constructor", "engine_supplier", "team", "laps", "time"}
    ),
    Sorted = Table.Sort(Ordered, {{"date", Order.Ascending}})
in
    Sorted
