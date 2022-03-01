-- DATA USED IN THIS PROJECT IS FROM 2020-01-22 TO 2022-02-24
------------------------------------------------------------------------------------------------------------------------------

-----------// DEATHS //-----------------

-- Total Cases vs Total Deaths each day
-- Shows likelihood of dying if you contract covid in your country
Select distinct Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From dbo.CovidDeaths
--Where location like 'Vietnam%' and 
where continent is not null 
order by 1,2
GO

-- Total Cases vs Population infected each day
-- Shows what percentage of population (in your country) infected with Covid
Select distinct Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From dbo.CovidDeaths
--Where location like 'Vietnams%'
order by 1,2
go

-- Countries with Highest Infection Rate compared to its Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  max((total_cases/population)*100) as PercentPopulationInfected
From dbo.CovidDeaths
--Where location like 'Vietnam%'
where continent is not null
Group by Location, Population
order by PercentPopulationInfected desc
go

-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc
go


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc
go


-- GLOBAL NUMBERS 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From dbo.CovidDeaths
where continent is not null 
order by 1,2
go

-- GLOBAL NUMBERS each day
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From dbo.CovidDeaths
where continent is not null 
Group By date
order by 1,2
go

-----------// VACCINATIONS //------------------

-- Total Population vs Vaccinations
-- Shows Percentage of Population (of a country) that has recieved at least one Covid Vaccine
-- misleading vaccination data --> working on solution...

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths dea JOIN dbo.CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
ORDER BY dea.location, dea.location, CONVERT(DATE,dea.date)



-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
go

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac
go


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
go

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeaths dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 