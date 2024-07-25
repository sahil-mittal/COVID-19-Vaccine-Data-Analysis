-- Active: 1713036883713@@127.0.0.1@5432@coviddb@public#covid_data
-- Active: 1713036883713@@127.0.0.1@5432@coviddb@public
-- CREATE TABLE covid_deaths (
--     iso_code VARCHAR(300),
--     continent VARCHAR(50),
--     location VARCHAR(100),
--     date DATE,
--     population BIGINT,
--     total_cases BIGINT,
--     new_cases BIGINT,
--     new_cases_smoothed DECIMAL(10,2),
--     total_deaths BIGINT,
--     new_deaths BIGINT,
--     new_deaths_smoothed DECIMAL(10,2),
--     total_cases_per_million DECIMAL(15,2),
--     new_cases_per_million DECIMAL(15,2),
--     new_cases_smoothed_per_million DECIMAL(15,2),
--     total_deaths_per_million DECIMAL(15,2),
--     new_deaths_per_million DECIMAL(15,2),
--     new_deaths_smoothed_per_million DECIMAL(15,2),
--     reproduction_rate DECIMAL(5,2),
--     icu_patients BIGINT,
--     icu_patients_per_million DECIMAL(15,2),
--     hosp_patients BIGINT,
--     hosp_patients_per_million DECIMAL(15,2),
--     weekly_icu_admissions BIGINT,
--     weekly_icu_admissions_per_million DECIMAL(15,2),
--     weekly_hosp_admissions BIGINT,
--     weekly_hosp_admissions_per_million DECIMAL(15,2)
-- );

-- CREATE TABLE covid_vaccine (
--     iso_code VARCHAR(300),
--     continent VARCHAR(50),
--     location VARCHAR(100),
--     date DATE,
--     new_tests BIGINT,
--     total_tests_per_thousand DECIMAL(10,2),
--     new_tests_per_thousand DECIMAL(10,2),
--     new_tests_smoothed DECIMAL(10,2),
--     new_tests_smoothed_per_thousand DECIMAL(10,2),
--     positive_rate DECIMAL(5,2),
--     tests_per_case DECIMAL(10,2),
--     tests_units VARCHAR(50),
--     total_vaccinations BIGINT,
--     people_vaccinated BIGINT,
--     people_fully_vaccinated BIGINT,
--     total_boosters BIGINT,
--     new_vaccinations BIGINT,
--     new_vaccinations_smoothed DECIMAL(10,2),
--     total_vaccinations_per_hundred DECIMAL(10,2),
--     people_vaccinated_per_hundred DECIMAL(10,2),
--     people_fully_vaccinated_per_hundred DECIMAL(10,2),
--     total_boosters_per_hundred DECIMAL(10,2),
--     new_vaccinations_smoothed_per_million DECIMAL(15,2),
--     new_people_vaccinated_smoothed BIGINT,
--     new_people_vaccinated_smoothed_per_hundred DECIMAL(10,2),
--     stringency_index DECIMAL(5,2),
--     population_density DECIMAL(15,2),
--     median_age DECIMAL(5,2),
--     aged_65_older DECIMAL(5,2),
--     aged_70_older DECIMAL(5,2),
--     gdp_per_capita DECIMAL(15,2),
--     extreme_poverty DECIMAL(5,2),
--     cardiovasc_death_rate DECIMAL(15,2),
--     diabetes_prevalence DECIMAL(5,2),
--     female_smokers DECIMAL(5,2),
--     male_smokers DECIMAL(5,2),
--     handwashing_facilities DECIMAL(5,2),
--     hospital_beds_per_thousand DECIMAL(5,2),
--     life_expectancy DECIMAL(5,2),
--     human_development_index DECIMAL(5,2),
--     population BIGINT,
--     excess_mortality_cumulative_absolute BIGINT,
--     excess_mortality_cumulative BIGINT,
--     excess_mortality DECIMAL(10,2),
--     excess_mortality_cumulative_per_million DECIMAL(15,2)
-- );

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM covid_deaths
WHERE continent is NOT NULL
ORDER BY 1,2

--Total deaths v/s total cases
--shows the likelyhood of dying if you contract covid in your country
SELECT location,date,total_cases,total_deaths,(total_deaths::FLOAT/total_cases)*100 AS "deathPercent"
FROM covid_deaths
WHERE continent is NOT NULL
WHERE location ILIKE '%states%'
ORDER BY 1,2

--Total cases v/s Population
SELECT location, date, total_cases, population, (total_cases::FLOAT/population)*100 AS "deathPercent"
FROM covid_deaths
WHERE continent is NOT NULL
WHERE location ILIKE '%states%'
ORDER BY 1,2

--Countries with highest infection rate
SELECT LOCATION,population,Max(total_cases) as HighestInfection,MAX((total_cases::FLOAT/population)*100) AS highestInfectionPercent
FROM covid_deaths
WHERE continent is NOT NULL
GROUP BY location,population
ORDER BY highestInfectionPercent DESC

--Countries with highest deaths
SELECT LOCATION,Max(total_deaths) as HighestDeaths
FROM covid_deaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestDeaths DESC

--Continents with deaths
SELECT location,Max(total_deaths) as HighestDeaths
FROM covid_deaths
WHERE continent is NULL
GROUP BY location
ORDER BY HighestDeaths DESC

--Global numbers
SELECT date, SUM(new_cases) as Total_New, SUM(new_deaths) as Deaths,
CASE 
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE SUM(new_deaths) / SUM(new_cases)
END AS DeathPercent
FROM covid_deaths
WHERE continent is not NULL 
GROUP BY date 
ORDER BY date, Total_New

--covid vaccine
SELECT *
FROM covid_vaccine

SELECT dea.location, SUM(vac.new_vaccinations) as new_Vac, dea.population, (SUM(vac.new_vaccinations)/dea.population)*100 as Percentage
FROM covid_deaths dea
JOIN covid_vaccine vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is NOT NULL
AND vac.new_vaccinations is NOT NULL
GROUP BY dea.location,dea.population
ORDER BY 2 DESC


SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) as  rollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccine vac
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent is not NULL
AND vac.new_vaccinations is not Null
ORDER BY 1,2,3

--with CTE
With PopVSvac(continent,location,date,population,new_vaccinations,rollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) as  rollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccine vac
ON dea.location=vac.location
AND dea.date=vac.date
WHERE dea.continent is not NULL
AND vac.new_vaccinations is not Null
ORDER BY 1,2,3)
SELECT *, (rollingPeopleVaccinated/population)*100
FROM PopVSvac


SELECT date, continent, location, new_vaccinations
FROM covid_vaccine
WHERE new_vaccinations is not NULL