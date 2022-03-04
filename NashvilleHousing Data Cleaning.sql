------------------------// Change data type //--------------------------------------------------------------------

--- SaleDate shows: YYYY-MM-DD 00:00:00 --> time component is not needed
--- We need to change SaleDate's datatype from datetime to date

alter table nashvillehousing
alter column saledate date

------ alternative solution
--alter table NashvilleHousing
--add SaleDateConverted Date;

--update NashvilleHousing
--set SaleDateConverted = CONVERT(Date,SaleDate) 


------------------------// Populate Property Address Data //---------------------------------------------------------

-- Some rows show null PropertyAdress value 
-- By looking through the table, we can see that each ParcelID has a PropertyAddress correspondingly
--> Use ParcelID to populate PropertyAddress data

update a
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from dbo.NashvilleHousing a join dbo.NashvilleHousing b
on a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
and a.PropertyAddress is NULL


------------------------// Break Address to Address, City, State //--------------------------------------------------------

-- 1.PropertyAddress
------ Use separator ',' to get what we need

alter table nashvillehousing
add PropertyAddress_ nvarchar(255)

update NashvilleHousing
set PropertyAddress_ = SUBSTRING(PropertyAddress,-1, CHARINDEX(',', PropertyAddress))

alter table nashvillehousing
add PropertyCity nvarchar(255)

update NashvilleHousing
set PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress)-CHARINDEX(',', PropertyAddress))

------ remove PropertyAddress column as we don't need it anymore
alter table nashvillehousing
drop column PropertyAddress

------ rename column PropertyAddress_ to PropertyAddress
exec sp_rename 'NashvilleHousing.PropertyAddress_', 'PropertyAddress', 'COLUMN'


-- 2.OwnerAddress
------ In this case, We will use PARSENAME(), which parses a string to periods (using '.'). So we need to replace ',' by '.' to make the function work properly

alter table nashvillehousing
add OwnerAddress_ nvarchar(255)
update NashvilleHousing
set OwnerAddress_ = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

alter table nashvillehousing
add OwnerCity nvarchar(255)
update NashvilleHousing
set OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

alter table nashvillehousing
add OwnerState nvarchar(255)
update NashvilleHousing
set OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

------ remove OwnerAddress column as we don't need it anymore
alter table nashvillehousing
drop column OwnerAddress

------ rename column OwnerAddress_ to OwnerAddress
exec sp_rename 'NashvilleHousing.OwnerAddress_', 'OwnerAddress', 'COLUMN'


------------------------// Unify data value //--------------------------------------------------------------------

-- SoldAsVacant has 4 values: N, No, Y and Yes --> 2 values are enough: No and Yes

update NashvilleHousing
set SoldAsVacant = 'No'
where SoldAsVacant = 'N'

update NashvilleHousing
set SoldAsVacant = 'Yes'
where SoldAsVacant = 'Y'

-- Alternative way
--select SoldAsVacant, 
--case when SoldAsVacant = 'Y' then 'Yes'
--	 when SoldAsVacant = 'N' then 'No'
--	 else SoldAsVacant
--	 end
--from NashvilleHousing


------------------------// Delete Unused Columns //--------------------------------------------------------------------

-- We'd already removed property and owner address in previous step where we split them out. 
-- SaleDate is kept in case customers want to know the price history of the house they are concerning to buy
-- 
alter table NashvilleHousing
drop column TaxDistrict


------------------------// Remove Duplicates //--------------------------------------------------------------------

-- We will remove any rows that have the same parcel id, property address,...

with CTE_RemoveDuplicates as (
	select *, ROW_NUMBER() over (partition by ParcelID, PropertyAddress, PropertyCity, SalePrice, SaleDate, LegalReference  order by UniqueID) as row_num
	from NashvilleHousing
)
delete
from CTE_RemoveDuplicates
where row_num > 1
-- 104 rows deleted

-- Result after the cleaning process ^3^
select*
from NashvilleHousing