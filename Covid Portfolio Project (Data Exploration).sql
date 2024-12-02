--select *
-- from dbo.[Сovid-deaths]
-- order by 3, 4

 --select *
 --from dbo.[Сovid-vaccinations]
 --order by 3, 4

 select location, date, total_cases, new_cases, total_deaths, population
 from dbo.[Сovid-deaths]
 order by 1, 2

 -- Total Cases vs Total Deaths
 -- Shows likelihood of dying by Covid in a certain country

 select location, date, total_cases, total_deaths, cast((total_deaths/total_cases)*100 as decimal(10, 6)) as DeathPercentage
 from dbo.[Сovid-deaths]
 where total_cases != 0 and continent IS NOT NULL and location = 'Poland' -- insert any country or select all
 order by 1, 2

 -- Total Cases vs Population
 -- Shows percentage of population infected with Covid

 select location, date, population, total_cases, cast((total_cases/population)*100 as decimal(10,6)) as InfectedPercentage
 from dbo.[Сovid-deaths]
 where total_cases != 0 and continent IS NOT NULL
 order by 1, 2

 -- Countries with Highest Infection Rate compared to Population

 select location, population, MAX(total_cases) AS HighestInfectionCount, MAX(cast((total_cases/population)*100 as decimal(10,6))) as InfectedPercentage
 from dbo.[Сovid-deaths]
 where total_cases != 0 and continent IS NOT NULL
 GROUP BY location, population
 order by 4 DESC


  -- Countries with Highest Death Count by Country
  
 select location, MAX(total_deaths) AS HighestDeathCount
 from dbo.[Сovid-deaths]
 where continent IS NOT NULL
 group by location
 order by 2 DESC


   -- Countries with Highest Death Count by continent

 select location, MAX(total_deaths) AS HighestDeathCount
 from dbo.[Сovid-deaths]
 where continent IS NULL
 and location NOT IN ('High-income countries', 'Upper-middle-income countries', 'Lower-middle-income countries', 'Low-income countries', 'European Union (27)')
 group by location
 order by 2 DESC


 -- Countries with Highest Death Count per Population

 select location, population, MAX(total_deaths) AS HighestDeathCount, (cast((MAX(total_deaths)/population)*100 as decimal(10,6))) as DeathPercentage
 from dbo.[Сovid-deaths]
 where continent IS NOT NULL
 group by location, population
 order by 4 DESC

 -- Global Numbers 
 select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as DeathPercentage
 from dbo.[Сovid-deaths]
 where continent IS NOT NULL and new_cases!=0
 --group by date

 
 -- Population vs Vaccinations by using CTE

 with popvsvac (continent, location, date, population, new_vaccinations, PeopleVaccinated) as
 (
 select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location, d.date) as PeopleVaccinated
 from dbo.[Сovid-deaths] d
 join dbo.[Сovid-vaccinations] v
 on d.location=v.location and d.date=v.date
 where d.continent IS NOT NULL
 )
 select *, (PeopleVaccinated/Population)*100 as PercentagePeopleVaccinated
 from popvsvac
 order by 2, 3


 --creating view for later viz 

 Create View PercentagePopulationVaccinated as
  select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location, d.date) as PeopleVaccinated
 from dbo.[Сovid-deaths] d
 join dbo.[Сovid-vaccinations] v
 on d.location=v.location and d.date=v.date
 where d.continent IS NOT NULL
