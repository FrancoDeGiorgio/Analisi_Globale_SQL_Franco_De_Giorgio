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

--------------- SECONDPA PARTE QUERY 1.1 PER CALCOLO STATISTICO ----------------
-- Calcolo della correlazione di Pearson e R² regressione lineare tra PIL pro capite e aspettativa di vita (anno 2020), solo per singoli paesi 
WITH gdp_life_stat AS (
    SELECT 
        countries.country AS country,
        global_energy_data.gdp_per_capita AS gdp_per_capita,
        demographics.life_expectancy AS life_expectancy,
        demographics.population AS population,
        countries.id_country
    FROM 
        countries
    INNER JOIN global_energy_data ON global_energy_data.id_country = countries.id_country
    INNER JOIN demographics ON demographics.id_country = countries.id_country
    WHERE 
        global_energy_data.year = 2020 AND
        global_energy_data.gdp_per_capita IS NOT NULL AND
        demographics.life_expectancy IS NOT NULL
)

-- Calcolo della correlazione e del coefficiente di determinazione sui dati dei singoli paesi
SELECT 
    corr(gdp_per_capita, life_expectancy) AS correlation_coefficient,
    regr_r2(life_expectancy, gdp_per_capita) AS r_squared
FROM 
    gdp_life_stat;


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
--2.3 Analisi delle emissioni di CO₂ per i principali paesi, con variazione annua, media mobile, ranking e quota cumulativa globale 
WITH yearly_emissions AS (
    SELECT 
        c.country,
        g.year,
        g.value_co2_emissions_tons_by_country as emissions,
        -- Calcola la variazione anno per anno
        (g.value_co2_emissions_tons_by_country - LAG(g.value_co2_emissions_tons_by_country) 
            OVER (PARTITION BY c.country ORDER BY g.year)) as yearly_change,
        -- Calcola la variazione percentuale anno per anno
        ROUND(
            ((g.value_co2_emissions_tons_by_country - LAG(g.value_co2_emissions_tons_by_country) 
            OVER (PARTITION BY c.country ORDER BY g.year)) / 
            NULLIF(LAG(g.value_co2_emissions_tons_by_country) 
            OVER (PARTITION BY c.country ORDER BY g.year), 0) * 100)::numeric, 
            2
        ) as yearly_pct_change,
        -- Calcola la media mobile su 5 anni
        AVG(g.value_co2_emissions_tons_by_country) 
            OVER (PARTITION BY c.country ORDER BY g.year 
                  ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as five_year_moving_avg,
        -- Calcola il rango del paese per emissioni nello specifico anno
        RANK() OVER (PARTITION BY g.year 
                     ORDER BY g.value_co2_emissions_tons_by_country DESC) as emissions_rank,
        -- Calcola la percentuale cumulativa delle emissioni globali
        SUM(g.value_co2_emissions_tons_by_country) 
            OVER (PARTITION BY g.year ORDER BY g.value_co2_emissions_tons_by_country DESC) /
        SUM(g.value_co2_emissions_tons_by_country) 
            OVER (PARTITION BY g.year) * 100 as cumulative_pct_of_global
    FROM 
        global_energy_data g
        INNER JOIN countries c ON c.id_country = g.id_country
    WHERE 
        g.value_co2_emissions_tons_by_country IS NOT NULL
)
SELECT 
    country,
    year,
    emissions,
    yearly_change,
    yearly_pct_change,
    five_year_moving_avg,
    emissions_rank,
    ROUND(cumulative_pct_of_global::numeric, 2) as cumulative_pct_of_global
FROM yearly_emissions
WHERE country IN ('China', 'United States', 'India', 'Germany', 'Japan')  -- esempio con i maggiori emettitori
ORDER BY year DESC, emissions DESC;

-------------------------------------------------------------------------------------------------------------------
/*3.1 Rapporto fra istruzione terziaria e fertilità media per donna, mi aspetto una diminuzione della fertilità all'aumentare 
della partecipazione all'istruzione terziaria*/
SELECT 
    countries.country, 
    COALESCE(education.gross_tertiary_education_enrollment, 0) AS gross_tertiary_education_enrollment,
    demographics.fertility_rate, 
    (economy.gdp_dollar / demographics.population) AS gdp_procapite
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

--------------- SECONDPA PARTE QUERY 3.1 PER CALCOLO STATISTICO ----------------
-- Calcolo della correlazione di Pearson e R² regressione lineare tra fertilità e istruzione terziaria 
WITH education_fertility_stat AS (
    SELECT 
        countries.country AS country,
        COALESCE(education.gross_tertiary_education_enrollment, 0) AS gross_tertiary_education_enrollment,
        demographics.fertility_rate, 
    	(economy.gdp_dollar / demographics.population) AS gdp_procapite
    FROM education
	INNER JOIN countries ON countries.id_country = education.id_country
	INNER JOIN economy ON economy.id_country = countries.id_country
	INNER JOIN demographics ON demographics.id_country = countries.id_country
	WHERE 
	    education.gross_tertiary_education_enrollment IS NOT NULL AND
        demographics.fertility_rate IS NOT NULL AND
        economy.gdp_dollar IS NOT NULL AND
        demographics.population > 0
)
-- Calcolo della correlazione e del coefficiente di determinazione 
	SELECT 
    -- Correlazione tra fertilità e istruzione terziaria
	corr(gross_tertiary_education_enrollment, fertility_rate) AS corr_education_fertility,
	regr_r2(fertility_rate, gross_tertiary_education_enrollment) AS r2_education_fertility,
	
	-- Correlazione tra fertilità e gdp pro capite 
	corr(gdp_procapite, fertility_rate) AS corr_gdp_fertility,
	regr_r2(fertility_rate, gdp_procapite) AS r2_gdpfertility
FROM 
    education_fertility_stat;
---------------------------------------------------------------------------------------------------------------------
--4.1 visualizzare variabili sanitarie e ottenere una relazione fra numero di medici e mortalità infatile e materna
SELECT 
   countries.country AS country,
   demographics.physicians_per_thousand AS physicians_per_thousand,
   COALESCE(economy.out_of_pocket_health_expenditure_percent, 0) AS out_of_pocket_health_expenditure_percent,
   demographics.infant_mortality AS infant_mortality,
   demographics.maternal_mortality_ratio AS maternal_mortality_ratio
FROM countries
INNER JOIN demographics ON demographics.id_country = countries.id_country
INNER JOIN economy ON economy.id_country = countries.id_country
WHERE demographics.physicians_per_thousand IS NOT NULL AND maternal_mortality_ratio IS NOT NULL
ORDER BY demographics.physicians_per_thousand DESC, economy.out_of_pocket_health_expenditure_percent DESC

--------------- SECONDPA PARTE QUERY 4.1 PER CALCOLO STATISTICO ----------------
-- Calcolo della correlazione di Pearson e R² regressione lineare tra numero di medici, emortalità infantile e materna
WITH mortality_stat AS (
    SELECT 
        countries.country AS country,
   		demographics.physicians_per_thousand AS physicians_per_thousand,
   		COALESCE(economy.out_of_pocket_health_expenditure_percent, 0) AS out_of_pocket_health_expenditure_percent,
   		demographics.infant_mortality AS infant_mortality,
   		demographics.maternal_mortality_ratio AS maternal_mortality_ratio
    FROM countries
    INNER JOIN demographics ON demographics.id_country = countries.id_country
    INNER JOIN economy ON economy.id_country = countries.id_country
    WHERE 
        demographics.physicians_per_thousand IS NOT NULL AND
        demographics.maternal_mortality_ratio IS NOT NULL AND
		demographics.infant_mortality IS NOT NULL
		
)

-- Calcolo della correlazione e del coefficiente di determinazione 
    SELECT 
    -- Correlazione tra medici e mortalità infantile
    corr(physicians_per_thousand, infant_mortality) AS corr_physicians_infant_mortality,
    regr_r2(infant_mortality, physicians_per_thousand) AS r2_physicians_infant_mortality,

    -- Correlazione tra medici e mortalità materna
    corr(physicians_per_thousand, maternal_mortality_ratio) AS corr_physicians_maternal_mortality,
    regr_r2(maternal_mortality_ratio, physicians_per_thousand) AS r2_physicians_maternal_mortality

FROM 
    mortality_stat;

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





















