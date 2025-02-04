-- creazione vista per gruppo Unione Europea
CREATE VIEW europa AS
SELECT id_country, country
FROM countries
WHERE country IN (
    'Austria', 'Belgium', 'Bulgaria', 'Croatia', 'Cyprus', 'Czech Republic',
    'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary',
    'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta',
    'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia',
    'Spain', 'Sweden'
);

-- creazione vista per gruppo BRICS economie emergenti
CREATE VIEW brics AS
SELECT id_country, country
FROM countries
WHERE country IN (
   'Brazil', 'Russia', 'India','China', 'South Africa'
);

-- creazione vista per gruppo SSA Sub-Saharan Africa
CREATE VIEW ssa_countries AS
SELECT id_country, country
FROM countries
WHERE country IN (
    'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi', 'Cabo Verde',
    'Cameroon', 'Central African Republic', 'Chad', 'Comoros', 'Congo', 
    'Djibouti', 'Equatorial Guinea', 'Eritrea', 'Eswatini', 'Ethiopia',
    'Gabon', 'Gambia', 'Ghana', 'Guinea', 'Guinea-Bissau', 'Ivory Coast',
    'Kenya', 'Lesotho', 'Liberia', 'Madagascar', 'Malawi', 'Mali', 
    'Mauritania', 'Mozambique', 'Namibia', 'Niger', 'Nigeria', 'Rwanda',
    'Sao Tome and Principe', 'Senegal', 'Seychelles', 'Sierra Leone',
    'Somalia', 'South Sudan', 'Sudan', 'Tanzania', 'Togo', 'Uganda', 
    'Zambia', 'Zimbabwe'
);

-- creazione vista per gruppo MENA paesi del Medio Oriente e del Nord Africa.
CREATE VIEW mena_countries AS
SELECT id_country, country
FROM countries
WHERE country IN (
    'Algeria', 'Bahrain', 'Djibouti', 'Egypt', 'Iran', 'Iraq', 'Israel', 
    'Jordan', 'Kuwait', 'Lebanon', 'Libya', 'Mauritania', 'Morocco', 'Oman',
    'Palestine', 'Qatar', 'Saudi Arabia', 'Somalia', 'Sudan', 'Syria',
    'Tunisia', 'United Arab Emirates', 'Yemen'
);

-- creazione vista per gruppo LAC paesi dell'America Latina e i Caraibi.
CREATE VIEW lac_countries AS
SELECT id_country, country
FROM countries
WHERE country IN (
    'Argentina', 'Bahamas', 'Barbados', 'Belize', 'Bolivia', 'Brazil', 
    'Chile', 'Colombia', 'Costa Rica', 'Cuba', 'Dominica', 'Dominican Republic', 
    'Ecuador', 'El Salvador', 'Grenada', 'Guatemala', 'Guyana', 'Haiti', 
    'Honduras', 'Jamaica', 'Mexico', 'Nicaragua', 'Panama', 'Paraguay', 
    'Peru', 'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 
    'Suriname', 'Trinidad and Tobago', 'Uruguay', 'Venezuela'
);

-- creazione vista per gruppo ASEAN sud-est asiatico.
CREATE VIEW asean AS
SELECT id_country, country
FROM countries
WHERE country IN (
    'Brunei', 'Cambodia', 'Indonesia', 'Laos', 'Malaysia', 'Myanmar', 
    'Philippines', 'Singapore', 'Thailand', 'Vietnam'
);

-- creazione vista per gruppo ASIA esclusi quelli già definiti (ASEAN, BRICS, MENA).
CREATE VIEW asia AS
SELECT id_country, country
FROM countries
WHERE country IN (
    'Afghanistan', 'Armenia', 'Azerbaijan', 'Bangladesh', 'Bhutan', 'Georgia', 'Japan', 
    'Kazakhstan', 'Kyrgyzstan', 'Maldives', 'Mongolia', 'Nepal', 'Pakistan', 
    'South Korea', 'Sri Lanka', 'Tajikistan', 'Turkmenistan', 'Uzbekistan'
);

--------------------------------------------------------------------------------------------

/* 1.1 Con quest query cerco una correlazione fra GDP pro capite e aspettativa di vita, mi aspetto di notare un aumento dell'aspettativa di vita
al crescere della GDP pro capite*/
SELECT 
    countries.country AS country,
    global_energy_data.gdp_per_capita AS gdp_per_capita,
    demographics.life_expectancy AS life_expectancy,
    demographics.population AS population
FROM 
    countries
INNER JOIN global_energy_data ON global_energy_data.id_country = countries.id_country 
INNER JOIN demographics ON countries.id_country = demographics.id_country
WHERE 
    global_energy_data.gdp_per_capita IS NOT NULL AND
    demographics.life_expectancy IS NOT NULL AND
    global_energy_data.year = 2020

UNION ALL

-- Query per i gruppi aggregati con media ponderata
SELECT 
    group_name AS country, 
    CAST(SUM(global_energy_data.gdp_per_capita * demographics.population) / SUM(demographics.population) AS NUMERIC(10, 1)) AS gdp_per_capita,
    CAST(SUM(demographics.life_expectancy * demographics.population) / SUM(demographics.population) AS NUMERIC(10, 1)) AS life_expectancy,
    SUM(demographics.population) AS population 
FROM(   
	SELECT id_country, 'UE' AS group_name FROM europa
    UNION ALL
    SELECT id_country, 'LAC' AS group_name FROM lac
    UNION ALL
    SELECT id_country, 'ASIA' AS group_name FROM asia
    UNION ALL
    SELECT id_country, 'BRICS' AS group_name FROM brics
    UNION ALL
    SELECT id_country, 'SSA' AS group_name FROM ssa
    UNION ALL
	SELECT id_country, 'ASEAN' AS group_name FROM asean
    UNION ALL
	SELECT id_country, 'MENA' AS group_name FROM mena
) groups
INNER JOIN global_energy_data ON groups.id_country = global_energy_data.id_country
INNER JOIN demographics ON groups.id_country = demographics.id_country
WHERE 
    global_energy_data.gdp_per_capita IS NOT NULL AND
    demographics.life_expectancy IS NOT NULL AND
    global_energy_data.year = 2020
GROUP BY group_name

ORDER BY gdp_per_capita DESC, life_expectancy DESC;


----------------------------------------------------------------------------------------------------
/* 2.1 Analizzo la Produzione Elettrica in Terawattora per Tipologia relativa all'anno 2020, mi aspetto di notare un aumento delle 
fonti rinnovabili */

SELECT 
    countries.country AS country,
    global_energy_data.electricity_from_nuclear_twh AS electricity_from_nuclear_twh,
    global_energy_data.electricity_from_renewables_twh AS electricity_from_renewables_twh,
    global_energy_data.electricity_from_fossil_fuels_twh AS electricity_from_fossil_fuels_twh
FROM global_energy_data
INNER JOIN countries ON countries.id_country = global_energy_data.id_country
WHERE 
    global_energy_data.year = 2020 

UNION ALL

-- Query per i gruppi aggregati
SELECT 
    groups.group_name AS country, 
  
    SUM(global_energy_data.electricity_from_nuclear_twh) AS electricity_from_nuclear_twh,
    SUM(global_energy_data.electricity_from_renewables_twh) AS electricity_from_renewables_twh,
    SUM(global_energy_data.electricity_from_fossil_fuels_twh) AS electricity_from_fossil_fuels_twh
FROM (
    SELECT id_country, 'UE' AS group_name FROM europa
    UNION ALL
    SELECT id_country, 'LAC' AS group_name FROM lac
    UNION ALL
    SELECT id_country, 'ASIA' AS group_name FROM asia
    UNION ALL
    SELECT id_country, 'BRICS' AS group_name FROM brics
    UNION ALL
    SELECT id_country, 'SSA' AS group_name FROM ssa
    UNION ALL
    SELECT id_country, 'ASEAN' AS group_name FROM asean
    UNION ALL
    SELECT id_country, 'MENA' AS group_name FROM mena
) groups
INNER JOIN global_energy_data ON groups.id_country = global_energy_data.id_country
WHERE 
    global_energy_data.year = 2020
GROUP BY groups.group_name


ORDER BY 
    electricity_from_renewables_twh DESC,
    electricity_from_nuclear_twh DESC,
    electricity_from_fossil_fuels_twh DESC

LIMIT 20;

----------------------------------------------------------------------------------------------------
-- 2.1.2 Produzione Elettrica in Terawattora per Tipologia 2000

SELECT 
    countries.country AS country,
    global_energy_data.electricity_from_nuclear_twh AS electricity_from_nuclear_twh,
    global_energy_data.electricity_from_renewables_twh AS electricity_from_renewables_twh,
    global_energy_data.electricity_from_fossil_fuels_twh AS electricity_from_fossil_fuels_twh
FROM global_energy_data
INNER JOIN countries ON countries.id_country = global_energy_data.id_country
WHERE 
    global_energy_data.year = 2000 

UNION ALL

-- Query per i gruppi aggregati
SELECT 
    groups.group_name AS country, 
  
    SUM(global_energy_data.electricity_from_nuclear_twh) AS electricity_from_nuclear_twh,
    SUM(global_energy_data.electricity_from_renewables_twh) AS electricity_from_renewables_twh,
    SUM(global_energy_data.electricity_from_fossil_fuels_twh) AS electricity_from_fossil_fuels_twh
FROM (
    SELECT id_country, 'UE' AS group_name FROM europa
    UNION ALL
    SELECT id_country, 'LAC' AS group_name FROM lac
    UNION ALL
    SELECT id_country, 'ASIA' AS group_name FROM asia
    UNION ALL
    SELECT id_country, 'BRICS' AS group_name FROM brics
    UNION ALL
    SELECT id_country, 'SSA' AS group_name FROM ssa
    UNION ALL
    SELECT id_country, 'ASEAN' AS group_name FROM asean
    UNION ALL
    SELECT id_country, 'MENA' AS group_name FROM mena
) groups
INNER JOIN global_energy_data ON groups.id_country = global_energy_data.id_country
WHERE 
    global_energy_data.year = 2000
GROUP BY groups.group_name


ORDER BY 
    electricity_from_renewables_twh DESC,
    electricity_from_nuclear_twh DESC,
    electricity_from_fossil_fuels_twh DESC

LIMIT 20;

----------------------------------------------------------------------------------------------------------------
--2.2 Visualizzare un confronto sulle emissioni di co2 fra gli anni 2000 e anno 2023 per nazione, mi aspetto di notare un variazione 

SELECT country, value_co2_emissions_tons_by_country AS emissions_tons_co2_2000, 
emissions_tons_co2 AS emissions_tons_co2_2023,
  ROUND(
        CAST(
            ((emissions_tons_co2 - value_co2_emissions_tons_by_country) / 
            NULLIF(value_co2_emissions_tons_by_country, 0)) * 100 
            AS NUMERIC
        ), 
        2
    ) AS percentage_change
FROM global_energy_data
INNER JOIN countries ON countries.id_country = global_energy_data.id_country
INNER JOIN land ON land.id_country = countries.id_country

WHERE year = 2000
ORDER BY country ASC

-------------------------------------------------------------------------------------------------------------------
/*3.1 Rapporto fra istruzione terziaria e fertilità media per donna, mi aspetto una diminuzione della fertilità all'aumentare 
della partecipazione all'istruzione terziaria*/
SELECT 
    countries.country, 
    COALESCE(education.gross_tertiary_education_enrollment, 0) AS gross_tertiary_education_enrollment,
    fertility_rate, 
    (gdp_dollar / population) AS gdp_procapite
FROM education
INNER JOIN countries ON countries.id_country = education.id_country
INNER JOIN economy ON economy.id_country = countries.id_country
INNER JOIN demographics ON demographics.id_country = countries.id_country
WHERE 
    fertility_rate IS NOT NULL 
    AND population > 0  
    AND gdp_dollar IS NOT NULL  
ORDER BY 
    gross_tertiary_education_enrollment DESC;

---------------------------------------------------------------------------------------------------------------------
--4.1 visualizzare variabili sanitarie e ottenere una relazione fra numero di medici e mortalità infatile e materna
SELECT 
   country, 
   physicians_per_thousand, 
   COALESCE(out_of_pocket_health_expenditure_percent, 0) AS out_of_pocket_health_expenditure_percent,
   infant_mortality, 
   maternal_mortality_ratio
FROM countries
INNER JOIN demographics ON demographics.id_country = countries.id_country
INNER JOIN economy ON economy.id_country = countries.id_country
WHERE demographics.physicians_per_thousand IS NOT NULL AND maternal_mortality_ratio IS NOT NULL
ORDER BY demographics.physicians_per_thousand DESC, economy.out_of_pocket_health_expenditure_percent DESC

--------------------------------------------------------------------------------------------------------------------------
--5.1 Visualizzare le prime tre cause di morte suddivise per nazione, mi aspetto nette differenze fra nazioni avanzate e in via di sviluppo

WITH Unpivoted AS (
    SELECT 
        c.country, 
        cdw.year,
        unpvt.key AS cause_of_death,
        unpvt.value::INTEGER AS deaths
    FROM cause_of_death_world cdw
    INNER JOIN countries c ON cdw.id_country = c.id_country  
    CROSS JOIN LATERAL jsonb_each_text(to_jsonb(cdw) - 'id_country' - 'year') AS unpvt
)
SELECT country, cause_of_death, deaths
FROM (
    SELECT 
        country,
        
        cause_of_death,
        deaths,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY deaths DESC) AS rn
    FROM Unpivoted
    WHERE year = 2019  -- 🎯 Filtra solo il 2019
) ranked
WHERE rn <= 3
ORDER BY country, deaths DESC;

