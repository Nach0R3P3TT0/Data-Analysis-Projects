/* NASHVILLE HOUSING EXPLORATORY ANALYSIS */

select * from DataCleaning..NashvilleHousing;

-- split the data based on the year, month and day of sale. 
select 
YEAR(SaleDate) as SaleYear, COUNT(YEAR(SaleDate)) SalesCount
FROM DataCleaning..NashvilleHousing
GROUP BY YEAR(SaleDate)
ORDER BY YEAR(SaleDate)
;

select 
MONTH(SaleDate) as SalesMonth, COUNT(MONTH(SaleDate)) SalesCount
FROM DataCleaning..NashvilleHousing
GROUP BY MONTH(SaleDate)
ORDER BY MONTH(SaleDate)
;

select 
DAY(SaleDate) as SalesDay, COUNT(DAY(SaleDate)) SalesCount
FROM DataCleaning..NashvilleHousing
GROUP BY DAY(SaleDate)
ORDER BY DAY(SaleDate)
;

--count of sales and  sum of total amount per city, MAX MIN y AVG SalePrice. ¿A MIN SAle Price of 50 USD and a Max of 54M in nashville? 
SELECT City, COUNT(City) SalesCount, SUM(SalePrice) TotalSales, MIN(SalePrice) MIN_SalePrice, MAX(SalePrice) MAX_SalePrice, AVG(SalePrice) AVG_SalePrice
from DataCleaning..NashvilleHousing
Group by city
order by TotalSales desc
;

Select * 
from DataCleaning..NashvilleHousing
where SalePrice = (
Select MAX(SalePrice) from DataCleaning..NashvilleHousing
)
;
/*Theres 7 rows for this max price, 7 residential condos, same sale date, Legal Reference and owner as output of the query above. 
It seems that the sale includes every condo as an entry, but doesn't separate the cost of each individual condo.
*/

Select * 
from DataCleaning..NashvilleHousing
where SalePrice = (
Select MIN(SalePrice) from DataCleaning..NashvilleHousing
)
;

-- Land use counts 
Select Street_and_Number, LandUse, COUNT(LandUse) LandUse_Count
from DataCleaning..NashvilleHousing
Group by LandUse, Street_and_Number
Order By Street_and_Number, LandUse_Count DESC;

-- Mean sale price, land price, building price and Acreage over the years. (visualize this w barplots to better understand it)
Select YEAR(SaleDate) Sale_Year, AVG(SalePrice) AVG_SalePrice, AVG(LandValue) AVG_LandValue, AVG(BuildingValue) AVG_BuildingValue, AVG(Acreage) AVG_Acreage
From DataCleaning..NashvilleHousing
where YEAR(SaleDate) <> 2019
Group by YEAR(SaleDate)
Order by Sale_Year;

--what is that data from 2019 ?? should it be removed as it doesn't contribute to the analysis?
select * from DataCleaning..NashvilleHousing
where YEAR(SaleDate) = 2019;

--Separating mean sale prices by time of year (sale price by month), the results show that prices in january are significantly higher than in the other months of the year
--unexpected since the SalesCount in january are one of the lowest as seen in one of the first queries (Sales Count by month).
Select MONTH(SaleDate) Sale_Month, AVG(SalePrice) AVG_SalePrice
from DataCleaning..NashvilleHousing
where YEAR(SaleDate) <> 2019
Group By MONTH(SaleDate)
Order By MONTH(SaleDate)
;

--Splitting the data further to see sale price by month over the years. It appears to be some large sales in january 2015 that can skew the data.
Select MONTH(SaleDate) Sale_Month, YEar(SaleDate) SAle_Year, AVG(SalePrice) AVG_SalePrice
from DataCleaning..NashvilleHousing
where YEAR(SaleDate) <> 2019
Group By MONTH(SaleDate),YEar(SaleDate)
Order By MONTH(SaleDate), YEar(SaleDate)
;

--Sale price by day of the month 
Select DAY(SaleDate) Sale_DAY, AVG(SalePrice) AVG_SalePrice
from DataCleaning..NashvilleHousing
where YEAR(SaleDate) <> 2019
Group By DAY(SaleDate)
Order By DAY(SaleDate)
;

--SAle price by day over the years
Select DAY(SaleDate) Sale_DAY, YEAR(SaleDate) Sale_YEAR ,AVG(SalePrice) AVG_SalePrice
from DataCleaning..NashvilleHousing
where YEAR(SaleDate) <> 2019
Group By DAY(SaleDate), YEAR(SaleDate)
Order By DAY(SaleDate), YEAR(SaleDate)
;