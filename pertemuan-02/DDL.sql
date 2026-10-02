-- CREATE DATABASE DAN MANAGE MDF/LDF

CREATE DATABASE PraktikumSPBU
ON
(
    NAME = PraktikumSPBU,
    FILENAME = 'E:\PraktikumSPBU\PraktikumSPBU.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
LOG ON
(
    NAME = PraktikumSPBU_log,
    FILENAME = 'E:\PraktikumSPBU\PraktikumSPBU.ldf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 2MB
)


-- USING DATABASE
USE PraktikumSPBU;
GO


-- 1. TABLE Customers
CREATE TABLE customers(
    CustomerID INT PRIMARY KEY,
    Segment VARCHAR(255),
    Currency VARCHAR(255)
)

-- 2. TABLES GAS STATION
CREATE TABLE gasstation(
    GasStationID INT PRIMARY KEY,
    ChainID INT,
    Country VARCHAR(255),
    SegmentGasStation VARCHAR(255)
)

-- 3. TABLE PRODUCTS
CREATE TABLE products(
    ProductID INT PRIMARY KEY,
    Description VARCHAR(255)
)

-- 4. TABLE YEARMONTH
CREATE TABLE yearmonth(
    CustomerID INT,
    [Date] INT,
    Consumption DECIMAL(12,2),

    CONSTRAINT PK_yearmonth PRIMARY KEY(CustomerID, [Date]),
    CONSTRAINT PK_yearmonth_customers FOREIGN KEY(CustomerID) REFERENCES customers(CustomerID)
)

-- 5. TABLE TRANSACTION
CREATE TABLE transactions(
TransactionID INT IDENTITY(1,1),
[Date] DATE,
[Time] TIME,
CustomerID INT,
CardID INT,
GasStationID INT,
ProductID INT,
Amount INT,
Price DECIMAL(12,2),

CONSTRAINT FK_transaction_customers FOREIGN KEY(CustomerID) REFERENCES customers(CustomerID),
CONSTRAINT FK_transaction_gasstations FOREIGN KEY(GasStationID) REFERENCES gasstation(GasStationID),
CONSTRAINT FK_transaction_products FOREIGN KEY(ProductID) REFERENCES products(ProductID)
)

