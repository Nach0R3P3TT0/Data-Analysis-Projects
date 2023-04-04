/* CLEANING DATA IN SQL QUERIES */

Select * from DataCleaning..NashvilleHousing;

/* 
standarize date format for the column SaleDate 
we don't need the timestamp in the date so we are going to take that out converting to 'date' from 'datetime'.
Easier way is to use the Alter table->column statement and change the data type, like in the commented query.
Another way is to use Alter Table to add 'SaleDate1' with data type date,then update the table setting the values into SaleDate1
*/

--Alter table DataCleaning..NashvilleHousing
--Alter column SaleDate Date;

Alter Table  DataCleaning..NashvilleHousing
ADD SaleDate1 Date;

Update DataCleaning..NashvilleHousing
set SaleDate1 = CONVERT(date,SaleDate);

select SaleDate, SaleDate1
from DataCleaning..NashvilleHousing;

/* POPULATE PROPERTY ADDRESS DATA
There are some null values in the PropertyAdress, we have to figure out how to fill them based on some referential point. In this case we can use the
ParcelID and assume that it's going to be the same Address for the same ParcelID.

First we do a self join to get each same parcellID with different uniqueID and null property address, mainly to visualize the data and better see the problem  
then we use part of this query to update the table filling the null propertyaddress values on the same ParcelID, then we re run the second query to check if the update
was correct
*/
Select *
from DataCleaning..NashvilleHousing
--where PropertyAddress is null 
order by ParcelID;

Select a.[UniqueID ], a.ParcelID, a.PropertyAddress, b.[UniqueID ], b.ParcelID, b.PropertyAddress, ISNULL(b.PropertyAddress,a.PropertyAddress) Address_NotNull
from DataCleaning..NashvilleHousing a
join DataCleaning..NashvilleHousing b
	on a.ParcelID=b.ParcelID and a.[UniqueID ]<>b.[UniqueID ]
where b.PropertyAddress is null;

update b
set PropertyAddress = ISNULL(b.PropertyAddress,a.PropertyAddress)
from DataCleaning..NashvilleHousing a
join DataCleaning..NashvilleHousing b
	on a.ParcelID=b.ParcelID and a.[UniqueID ]<>b.[UniqueID ]
where b.PropertyAddress is null;

/* BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ST & N°, CITY, STATE)

WE ARE GOING TO USE THE SUBSTRING FUNCTION AND CHARINDEX, THE SEPARATOR IN THIS CASE IS THE COMA ','

FOR THE ST&N°,THE STARTING POSITION IS THE FIRST CHARACTER, THEN WE USE THE -1 TO NOT INCLUDE THE ',' IN THE RESULT. WE DO IT THAT WAY SINCE THE CHARINDEX OUTPUT 
IS A NUMBER AND WE CAN DO THE OPERATION -1 TO AVOID THE COMA THAT IS THE LAST CHARACTER OF THE SPECIFIED LENGTH.
THE SECOND CASE IS SIMILAR, BUT THE STARTING POSITION IS GOING TO BE AFTER THE COMA, IN THIS CASE +2 CHARACTERS AFTER SINCE WE HAVE A BLANK SPACE AFTER THE COMA
AND WE DON'T WANT THAT IN THE RESULT(WE COULD USE THE FUNCTION TRIM ASWELL), THEN WE USE LEN BC THE LENGTH IS VARIABLE.
*/

Select 
	PropertyAddress, 
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Street_And_Number,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+2,LEN(PropertyAddress)) as City
From DataCleaning..NashvilleHousing

ALTER TABLE DataCleaning..NashvilleHousing
add Street_and_Number nvarchar(100),
	City nvarchar (100)
;
UPDATE DataCleaning..NashvilleHousing
SET Street_and_Number=SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
	City=SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+2,LEN(PropertyAddress))
;

/*DO THE SAME FOR OWNERADDRESS, USE THE FUNCTION PARSENAME THAT RETURNS THE SPECIFIED PART OF THE OBJECT NAME, 
REPLACE THE COMAS FOR PERIODS BC THE FUNCTION USES THAT AS SEPARATORS, AND TRIM THE BLANK SPACES IN THE OUTPUT*/
SELECT 
OwnerAddress,
TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),1)) Owner_State,
TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),2)) Owner_City,
TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),3)) Owner_Address
FROM DataCleaning..NashvilleHousing;

ALTER TABLE  DataCleaning..NashvilleHousing
ADD Owner_Address nvarchar(100),
	Owner_City nvarchar(100),
	Owner_State nvarchar(100)
	;
UPDATE DataCleaning..NashvilleHousing
SET Owner_Address=TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),3)),
	Owner_City=TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),2)),
	Owner_State=TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),1))
Where OwnerAddress is not null;


/* THE COLUMN SOLD AS VACANT HAS THE VALUES 'Y' 'YES' 'N' 'NO', WE NORMALIZE THIS IN JUST 'Y' AND 'N' USING CASE STATEMENT
*/

SELECT soldasvacant, Count(SoldAsVacant) 
FROM DataCleaning..NashvilleHousing
group by SoldAsVacant;

Select Soldasvacant,
CASE WHEN SoldAsVacant = 'Yes' THEN 'Y'
	 WHEN SoldAsVacant = 'No' THEN 'N'
	 ELSE SoldAsVacant
	 END Norm_SoldAsVacant
from DataCleaning..NashvilleHousing;

UPDATE DataCleaning..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Yes' THEN 'Y'
	 WHEN SoldAsVacant = 'No' THEN 'N'
	 ELSE SoldAsVacant
	 END
;


/* REMOVING DUPLICATES, WE ARE GOING TO DELETE DATA FROM THE DB, OUR PRIMARY DATA SOURCE, SOMETHING THAT IS NOT A VERY COMMON PRACTICE 
FOR THIS WE USE CTE AND THE FUNCTION ROWNUMBER, IT ADDS A UNIQUE SEQUENTIAL ROW NUMBER TO THE DUPLICATED ROW, WE PARTITION THE DATA OVER THE COLUMNS THAT WE WANT TO CHECK
IF THEY ARE DUPLICATED (WE ARE IGNORING THAT WE HAVE A UNIQUEID). IN THE OUTPUT, ANY ROW_NUM GREATER THAN 1 IS A DUPLICATED ROW
THEN REMOVE THE DUPLICATE ROWS USING THE CTE WITH THE DELETE FUNCTION*/

WITH RowNumCTE as(
Select *,
ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
	ORDER BY UniqueID
	) row_num
from DataCleaning..NashvilleHousing
--Order By ParcelID
)
--SELECT * FROM RowNumCTE -- THERE ARE 104 DUPLICATE ROWS, WE CAN SEE THEM AS THE OUTPUT OF THIS SELECT STATEMENT, WE USE THE FUNCTION DELETE TO ELIMINATE THE DUPLICATES
--Order by PropertyAddress; COMMENT THIS QUERY TO AVOID ERROR MSG
Delete 
From RowNumCTE
Where row_num>1

SELECT * from DataCleaning..NashvilleHousing;


/* DELETING UNUSED/USELESS COLUMNS, AGAIN WE DON'T NORMALLY DO THIS TO THE RAW DATA (BEST PRACTICES) IN THIS CASE WE ARE PRACTICING AND NOT MANIPULATING IMPORTANT DATA
FOR THIS WE WOULD NORMALLY CREATE A VIEW AND AVOID THE COLUMNS THAT WE DON'T WANT.
*/
ALTER TABLE DataCleaning..NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict;

SELECT * FROM DataCleaning..NashvilleHousing;

select UniqueID,
CASE WHEN OwnerName='Not Applicable' THEN NULL
	WHEN OwnerName='N/A' THEN NULL
	ELSE OwnerNAme
	END
from DataCleaning..NashvilleHousing;

Select OwnerName 
from DataCleaning..NashvilleHousing
where OwnerName is not null and OwnerName like '%N/A%' or OwnerName like '%Not App%'
;