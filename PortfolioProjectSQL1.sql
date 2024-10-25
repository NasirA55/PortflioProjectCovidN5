--select * from CovidDeathsC
--WHERE continent IS NOT NULL
--order BY 3, 4

--select TOP 20 * from CovidVaccinationsC
--order BY 3, 4
-- Data for future use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeathsC
order by 1,2

-- Total cases VS total deaths % 
-- Likelihood of dying if someone is contracted with Covid

SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float) / cast(total_cases as float))*100
FROM CovidDeathsC
where total_cases <> 0 AND total_deaths <> 0 AND location LIKE 'INDIA'
order by 1,2

--Total cases vs population

SELECT location, date, total_cases, population, (cast(total_cases as float) / cast(population as float))*100
FROM CovidDeathsC
where total_cases <> 0 AND  location like '%States%'
order by 1,2, 3

-- Countries with highest infection rate

SELECT location, population, MAX(total_cases) AS MaxCase, MAX(cast(total_cases as float) / cast(population as float))*100 AS InfectionRate
FROM CovidDeathsC
--where total_cases <> 0 --AND  location like '%States%'
group by location, population
order by InfectionRate DESC

-- Countries with highest Death Count

SELECT location,  MAX(total_deaths) AS TotalDeaths
FROM CovidDeathsC
--where total_cases <> 0
where continent is not NULL
group by location
order by TotalDeaths desc

-- CONTINENTS with highest Death Count

SELECT continent,  MAX(total_deaths) AS TotalDeaths
FROM CovidDeathsC
where continent is not NULL
group by continent
order by TotalDeaths desc

-- CONTINENTS with highest Death count per population

SELECT date, SUM(new_cases), SUM(new_deaths), (CAST(SUM(new_deaths) AS FLOAT) / NULLIF(SUM(new_cases), 0))*100 AS DeathRate
FROM CovidDeathsC
WHERE new_deaths <> 0
group by date
order by 1, 2

-- Total Across the world

SELECT SUM(new_cases), SUM(new_deaths), (CAST(SUM(new_deaths) AS FLOAT) / NULLIF(SUM(new_cases), 0))*100 AS DeathRate
FROM CovidDeathsC
WHERE new_deaths <> 0
--group by date
order by 1, 2

-- CovidVaccination 

select TOP 20 *
from CovidVaccinationsC

-- Analysing Total Population VS Total Vccination-Part-1

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeathsC dea
JOIN CovidVaccinationsC vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Analysing Total Population VS Total Vccination-Final
--****** SUM(CAST vac.new_vaccinations AS int) OR SUM(CONVERT(INT, vac.new_vaccinations)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotVac
FROM CovidDeathsC dea
JOIN CovidVaccinationsC vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
--WHERE new_vaccinations IS NOT NULL
ORDER BY 2, 3

-- Use of CTE for calculating Population VS Vaccination

WITH PopVsVacc (Continent, location, date, population, new_vaccination, RollingTotVac) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotVac
FROM CovidDeathsC dea
JOIN CovidVaccinationsC vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
--WHERE new_vaccinations IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (CAST(RollingTotVac AS FLOAT) / CAST(population AS FLOAT)) * 100 AS VaccinationRatePercent
FROM PopVsVacc

--To find the total vaccination per Location USING TEMP TABLE
--DROP Table IF EXIST #PerPopVacc

Create Table #PerPopVacc (
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
new_vaccinations numeric, RollingTotVac numeric
)
-- Insert data in above table
INSERT INTO #PerPopVacc
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotVac
FROM CovidDeathsC dea
JOIN CovidVaccinationsC vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
--WHERE new_vaccinations IS NOT NULL
--ORDER BY 2, 3
SELECT * FROM #PerPopVacc
-- Additional Query
SELECT *, (CAST(RollingTotVac AS FLOAT) / CAST(population AS FLOAT)) * 100 AS VaccinationRatePercent
FROM #PerPopVacc
ORDER BY 2, 3

--Creating view to store data for later visualization

CREATE VIEW PerPopVaccinateds AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingTotVac
FROM CovidDeathsC dea
JOIN CovidVaccinationsC vac
	ON Dea.location = Vac.location AND Dea.date = Vac.date
--WHERE new_vaccinations IS NOT NULL
--ORDER BY 2, 3
SELECT * FROM PerPopVaccinateds