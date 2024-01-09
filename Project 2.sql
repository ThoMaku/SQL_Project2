--Standardize date format

ALTER TABLE Nashville_Housing
ADD SaleDateConverted date

UPDATE Nashville_Housing
SET SaleDateConverted = CONVERT(date, SaleDate)

------------------------------------------------------------------------------------------------------------------------------------------
--Populate Property Address Data

SELECT *--PropertyAddress
FROM Nashville_Housing
--WHERE PropertyAddress IS NULL
ORDER BY PropertyAddress

--The following SELECT query was used to chek if the ISNULL function does what it's supposed to do
SELECT nashville_1.ParcelID, nashville_1.PropertyAddress, nashville_2.ParcelID, nashville_2.PropertyAddress
,ISNULL(nashville_1.PropertyAddress,nashville_2.PropertyAddress) as UpdatedPropertyAddress--If the property address is null it will be populated with the data from nashville_2 property address
FROM Nashville_Housing AS nashville_1
JOIN Nashville_Housing AS nashville_2
	ON nashville_1.ParcelID = nashville_2.ParcelID
	AND nashville_1.UniqueID <> nashville_2.UniqueID
WHERE nashville_1.PropertyAddress IS NULL

UPDATE nashville_1
SET PropertyAddress = ISNULL(nashville_1.PropertyAddress,nashville_2.PropertyAddress)
FROM Nashville_Housing AS nashville_1
JOIN Nashville_Housing AS nashville_2
ON nashville_1.ParcelID = nashville_2.ParcelID
AND nashville_1.UniqueID <> nashville_2.UniqueID
WHERE nashville_1.PropertyAddress IS NULL

-----------------------------------------------------------------------------------------------------------------------------------------
--Breaking out Property Address into Individual Columns(Address, City)
SELECT PropertyAddress
FROM Nashville_Housing

SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 0, CHARINDEX(',',PropertyAddress)) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, CHARINDEX(',',PropertyAddress)) AS City
FROM Nashville_Housing

ALTER TABLE Nashville_Housing
ADD SplitPropertyAddress nvarchar(MAX)

UPDATE Nashville_Housing
SET SplitPropertyAddress = SUBSTRING(PropertyAddress, 0, CHARINDEX(',',PropertyAddress))

ALTER TABLE Nashville_Housing
ADD SplitPropertyCity nvarchar(MAX)

UPDATE Nashville_Housing
SET SplitPropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, CHARINDEX(',',PropertyAddress))

SELECT SplitPropertyAddress, SplitPropertyCity
FROM Nashville_Housing

----------------------------------------------------------------------------------------------------------------------------------------
--Breaking out Owner Address into Individual Columns(Address, City, State)

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),1),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
FROM Nashville_Housing

ALTER TABLE Nashville_Housing
ADD SplitOwnerAddress nvarchar(MAX), 
SplitOwnerCity nvarchar(MAX),
SplitOwnerState nvarchar(MAX)


UPDATE Nashville_Housing
SET SplitOwnerAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE Nashville_Housing
SET SplitOwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE Nashville_Housing
SET SplitOwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

SELECT OwnerAddress, SplitOwnerAddress, SplitOwnerCity, SplitOwnerState
FROM Nashville_Housing
-----------------------------------------------------------------------------------------------------------------------------------
--Clean the data on the 'Sold As Vacant' column

DELETE 
FROM Nashville_Housing
WHERE SoldAsVacant IS NULL

UPDATE Nashville_Housing
SET SoldAsVacant = 'No'
WHERE SoldAsVacant LIKE '%scenic view%'

UPDATE Nashville_Housing
SET SoldAsVacant = 'Yes'
WHERE SoldAsVacant LIKE '%pike%'
-----------------------------------------------------------------------------------------------------------------------------------
--Change Y and N to Yes and No in 'Sold as vacant' field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville_Housing
GROUP BY SoldAsVacant

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM Nashville_Housing

UPDATE Nashville_Housing
SET SoldAsVacant =
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM Nashville_Housing
-----------------------------------------------------------------------------------------------------------------------------------
--Remove duplicates
WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID) row_num
FROM Nashville_Housing
--ORDER BY SaleDate, SalePrice
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-----------------------------------------------------------------------------------------------------------------------------------
--Delete Unused Columns
ALTER TABLE Nashville_Housing 
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

SELECT * 
FROM Nashville_Housing