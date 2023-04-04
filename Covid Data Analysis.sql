/* 
COVID 19 Data Analysis 
Main skills used: Aggregate functions, Joins, CTE's, Window Functions, View's, Converting data types
*/

select *
from CovidData..CovidDeaths
where continent is not null
order by 3,4;

-- select relevant data
select location, date, total_cases, new_cases, total_deaths, population
from CovidData..CovidDeaths
order by 1,2;

select sum(cast(new_cases as numeric)) as total_cases, sum(cast(new_deaths as numeric)) as total_deaths, 
sum(cast(new_deaths as  numeric))/sum(cast(new_cases as numeric))*100 as LethalityRate
from CovidData..CovidDeaths
where continent is not null
--and location like '%Argentina%'
order by 1,2;

select location, date, cast(total_cases as numeric) as total_cases, cast(total_deaths as numeric) as total_deaths, 
(cast(total_deaths as  numeric)/(cast(total_cases as numeric)))*100 as LethalityRate
from CovidData..CovidDeaths
where continent is not null
--and location like '%Argentina%'
order by 1,2;

--Rate of total deaths vs total cases, this ratio is commonly known as lethality. 
select location, date, cast(total_cases as numeric) as total_cases, cast(total_deaths as numeric) as total_deaths, 
(cast(total_deaths as  numeric)/(cast(total_cases as numeric)))*100 as LethalityRate
from CovidData..CovidDeaths
where continent is not null
--and location like '%Argentina%'
order by 1,2;

--we can use it to calculate the general lethality of the virus for each specific location or continent.
With GeneralLethality (location, daily_cases, daily_deaths, DailyLethalityRate)
as (
select location, cast(new_cases as numeric) as daily_cases, cast(new_deaths as numeric) as daily_deaths, 
cast(new_deaths as numeric)/cast(new_cases as numeric)*100 as DailyLethalityRate
from CovidData..CovidDeaths
where continent is not null
)
select *, sum(DailyLethalityRate)/COUNT(date)
from GeneralLethality
;
/*We can calculate the moving-average case fatality rate (CFR fatality=lethality) ratio between 7 days average number of deaths and the 7
days average number of cases 10 days earlier. We usually use multiples of 7 for this average, because a week has 7 days so we include each day
the same number of times.*/
with CFR (location, date, total_cases, total_deaths, Deaths_7DaysAVG, Cases10_7DaysAVG) as 
(
SELECT
  location,
  date,
  CAST(total_cases AS float) AS total_cases,
  CAST(total_deaths AS float) AS total_deaths,
  AVG(CAST(total_deaths AS float)) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS deaths_7day_avg,
  AVG(CAST(total_cases AS float)) OVER (PARTITION BY location ORDER BY date ROWS BETWEEN 16 PRECEDING AND 10 PRECEDING) AS cases_10day_avg
from CovidData..CovidDeaths
where continent is not null
)
select *, Deaths_7DaysAVG/Cases10_7DaysAVG as Moving_CFRatio
from CFR;

--Looking at total cases vs population
select location, date, population, MAX(cast(total_cases as numeric)) HighestInfectionCount, 
ROUND(max(cast(total_cases as INT)/CAST(population AS float))*100,2,2) as PercentPopulationInfected
from CovidData..CovidDeaths
--where location like '%Argentina%'
where continent is not null
group by location, population,date
order by PercentPopulationInfected DESC
;

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
and location not in('World', 'European Union','International')
group by location
order by HighestDeathCount DESC;

--view for the global continent death count
create view ContinentDeathCount as
select location, max(cast(total_deaths as int)) as HighestDeathCount
from CovidData..CovidDeaths
where continent is null and location not like '%income%'
and location not in('World', 'European Union','International')
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

--Exploring countries on their total cases, total deaths, population, Percent of the population infected, percent of the population deceased
select location, population, sum(new_cases) as TotalCases, sum(cast(new_deaths as numeric)) as TotalDeaths, 
sum(new_cases)/population*100 as PercentPopulationInfected, sum(cast(new_deaths as numeric))/population*100 as PercentPopulationDeceased
from CovidData..CovidDeaths
where continent is not null
group by location, population
order by 3 DESC;

--Alternative way of exploring total cases, total deaths, population, Percent of the population infected, percent of the population deceased
--using the function max
select location, population, max(cast(total_cases as numeric)) as Max_Cases, max(cast(total_deaths as numeric)) as Max_Deaths, 
max(cast(total_cases as numeric))/population*100 as PercentPopulationInfected, max(cast(total_deaths as numeric))/population*100 as PercentPopulationDeceased
from CovidData..CovidDeaths
where continent is not null
group by location, population
order by 3 DESC;



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

