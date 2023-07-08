SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 3,4


SELECT *
FROM PortfolioProject.dbo.CovidVaccinations$
ORDER BY 3,4


-- Select data to use
SELECT Location, date, total_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1, 2

-- Looking at total cases vs total deaths
-- Shows the likelihood of dying if you contract Covid in your country
SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 3) AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at total cases vs the population
-- Shows percentage of population that got Covid
SELECT location, date, population, total_cases, ROUND((total_cases/population)*100, 3) AS PositivePercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, ROUND(MAX((total_cases/population))*100, 3) AS PercentInfected
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY PercentInfected DESC


-- Showing countries with highest death count per population
-- Have to convert total_deaths to int from nvarchar(255) because of type error
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
	-- If continent is null than the location is the continent
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Break things down by continent
-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


SELECT location, max(cast(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Global Numbers
-- Shows the sum of all new cases and deaths in the world by day
SELECT date, SUM(new_cases) AS total_cases, 
	SUM(cast(new_deaths AS int)) AS total_deaths, 
	ROUND(SUM(cast(new_deaths AS int))/SUM(New_Cases)*100, 3) AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Shows the total cases, deaths, and the percentage of infected people who died
SELECT SUM(new_cases) AS total_cases, 
	SUM(cast(new_deaths AS int)) AS total_deaths, 
	ROUND(SUM(cast(new_deaths AS int))/SUM(New_Cases)*100, 3) AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2



-- Vaccination table
SELECT * 
FROM PortfolioProject..CovidVaccinations$


-- Join vaccinations table with deaths table
SELECT *
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Using CTE to perform calculation on partition by in previous query
-- Looking at the daily vaccinations, a rolling count of vaccinations, and the percentage of the population vaccinated
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentagePopulationVaccinated
FROM PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query
IF EXISTS (SELECT * 
			FROM #PercentPopulationVaccinated)
	DROP Table #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations 
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS 
RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopulationVaccinated