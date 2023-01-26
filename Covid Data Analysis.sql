select *
from CovidData..CovidDeaths
where continent is not null
order by 3,4;

--select *
--from CovidData..CovidVaccinations
--order by 3,4;

-- select relevant data
select location, date, total_cases, new_cases, total_deaths, population
from CovidData..CovidDeaths
order by 1,2;

--Rate of total-cases vs total_deaths
select location, date, cast(total_cases as numeric) as total_cases, cast(total_deaths as numeric) as total_deaths, 
(cast(total_deaths as  numeric)/(cast(total_cases as numeric)))*100 as DeathPercentage
from CovidData..CovidDeaths
where continent is not null
--and location like '%Argentina%'
order by 1,2;

--Looking at total cases vs population
select location, date, total_cases, population, (cast(total_cases as numeric)/population)*100 as PercentPopulationInfected
from CovidData..CovidDeaths
--where location like '%Argentina%'
where continent is not null
order by 1,2;

--countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max(cast(total_cases as numeric)/population)*100 as PercentPopulationInfected
from CovidData..CovidDeaths
where continent is not null
--and location like '%Argentina%'
group by location, population
order by PercentPopulationInfected DESC;

--View Infection rate vs population
create view PercentPopulationInfected as 
select location, population, max(total_cases) as HighestInfectionCount, max(cast(total_cases as numeric)/population)*100 as PercentPopulationInfected
from CovidData..CovidDeaths
where continent is not null
--and location like '%Argentina%'
group by location, population
;
select * from PercentPopulationInfected;

--countries with the highest death count compared to its population
select location, cast(population as numeric) as population, max(cast(total_deaths as int)) as HighestDeathCount, 
max(cast(total_deaths as int))/cast(population as numeric)*100 as DeathRate
from CovidData..CovidDeaths
--where location like '%Argentina%'
where continent is not null
group by location, population
order by HighestDeathCount DESC;

--View for the death count vs population rate
create view DeathvsPopulationRate as
select location, cast(population as numeric) as population, max(cast(total_deaths as int)) as HighestDeathCount, 
max(cast(total_deaths as int))/cast(population as numeric)*100 as DeathRate
from CovidData..CovidDeaths
--where location like '%Argentina%'
where continent is not null
group by location, population
order by HighestDeathCount DESC;

--continents with highest death count, where location is the continent or region
select location, max(cast(total_deaths as int)) as HighestDeathCount
from CovidData..CovidDeaths
where continent is null and location not like '%income%'
group by location
order by HighestDeathCount DESC;

--view for the global continent death count
create view ContinentDeathCount as
select location, max(cast(total_deaths as int)) as HighestDeathCount
from CovidData..CovidDeaths
where continent is null and location not like '%income%'
group by location
;
select * from ContinentDeathCount;

--GLOBAL NUMBERS, the result was 0 when datatype was int or varchar for new_cases. It was converted into float and we
--obtained the correct result.
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths,
(sum(cast(new_deaths as int))/max(cast(population as float)))*100 as MortalityRate,
(sum(cast(new_deaths as int))/sum(new_cases))*100 as LethalityRate
from CovidData..CovidDeaths
where continent is not null
--group by date shows the data day by day rather than the total global value
order by 1,2;

--view of this global numbers
create view LethalityMortalityRate as
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths,
(sum(cast(new_deaths as int))/max(cast(population as float)))*100 as MortalityRate,
(sum(cast(new_deaths as int))/sum(new_cases))*100 as LethalityRate
from CovidData..CovidDeaths
where continent is not null
;
select * from LethalityMortalityRate;

-- looking at total population vs vaccinations, what is the total mamount of vaccinated people in the world. Notice that when we use 'over
--partition by...' we shouldn't use group by.
select distinct dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativePeopleVaccinated
from CovidData..CovidDeaths as dea
join CovidData..CovidVaccinations as vac
	on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
order by 3,2
;

select dea.date, dea.location, dea.continent, vac.new_vaccinations
from CovidData..CovidVaccinations as vac
join CovidData..CovidDeaths as dea on dea.location=vac.location and dea.date=vac.date
where dea.location='Afghanistan' and vac.new_vaccinations is not null
order by dea.date
;

-- looking at total population vs vaccinations, what is the total mamount of vaccinated people in the world. Notice that when we use 'over
--partition by...' we shouldn't use group by.
--Also be aware that  for location=afghanistan each date is duplicated so its added twice in CumulativePeopleVaccinated.
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativePeopleVaccinated
from CovidData..CovidDeaths as dea
join CovidData..CovidVaccinations as vac
	on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null 
--and dea.location ='Afghanistan'
;

-- vaccinations rate using max people vaccinated, note that there is more people vaccinated than population on some locations, why is that?
select dea.continent, dea.location, dea.population,
max(cast(vac.people_vaccinated as numeric)) as TotalPeopleVaccinated,
max(cast(vac.people_vaccinated as numeric))/cast(dea.population as numeric)*100 as VaccinationsRate
from CovidData..CovidDeaths as dea
join CovidData..CovidVaccinations as vac
	on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.population
order by VaccinationsRate DESC;


select location, sum(new_vaccinations) from CovidData..CovidVaccinations
where location='Nicaragua'
group by location
;

-- USE CommonTableExpression(CTE) which is a virtual table and further use it in a subsequent select statement to calculate 
--the rolling percent of the population vaccinated
With PopVsVacc (Continent, Location, date, population, new_vaccinations, CumulativePeopleVaccinated)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativePeopleVaccinated
from CovidData..CovidDeaths as dea
join CovidData..CovidVaccinations as vac
	on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null 
--order by 2,3
)
select *, (CumulativePeopleVaccinated/cast(population as numeric))*100 as PercentPopulationVacc
from PopVsVacc


--TEMP TABLE
Drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location varchar(255),
date datetime,
Population numeric,
NewVaccinations numeric,
CumulativePeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativePeopleVaccinated
from CovidData..CovidDeaths as dea
join CovidData..CovidVaccinations as vac
	on dea.location=vac.location and dea.date=vac.date
--where dea.continent is not null 
--order by 2,3
select *, (CumulativePeopleVaccinated/cast(population as numeric))*100 as RatePopulationVaccinated 
from #PercentPopulationVaccinated
;


--creating view for later visualizations in tableau or PowerBI
create view CumulativePopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as CumulativePeopleVaccinated
from CovidData..CovidDeaths as dea
join CovidData..CovidVaccinations as vac
	on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null 
;

select *
from CumulativePopulationVaccinated;
