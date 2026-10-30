IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TokoRetailDB')
BEGIN
    CREATE DATABASE TokoRetailDB;
END
GO

USE TokoRetailDB;
GO

IF OBJECT_ID('OrderDetails', 'U') IS NOT NULL DROP TABLE OrderDetails;
IF OBJECT_ID('Orders', 'U') IS NOT NULL DROP TABLE Orders;
IF OBJECT_ID('Products', 'U') IS NOT NULL DROP TABLE Products;
IF OBJECT_ID('Categories', 'U') IS NOT NULL DROP TABLE Categories;
IF OBJECT_ID('Customers', 'U') IS NOT NULL DROP TABLE Customers;
GO

CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL,
    Description VARCHAR(255)
);

CREATE TABLE Customers (
    CustomerID INT IDENTITY(1001,1) PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    City VARCHAR(50),
    IsActive BIT DEFAULT 1,
    RegisteredAt DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    CategoryID INT FOREIGN KEY REFERENCES Categories(CategoryID),
    Price DECIMAL(12,2) NOT NULL CHECK (Price >= 0),
    Stock INT NOT NULL DEFAULT 0 CHECK (Stock >= 0),
    UpdatedAt DATETIME2 DEFAULT SYSDATETIME()
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(50001,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    OrderDate DATETIME2 DEFAULT SYSDATETIME(),
    TotalAmount DECIMAL(14,2) DEFAULT 0,
    Status VARCHAR(20) DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Paid', 'Shipped', 'Cancelled'))
);

CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT FOREIGN KEY REFERENCES Orders(OrderID) ON DELETE CASCADE,
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(12,2) NOT NULL
);
GO

INSERT INTO Categories (CategoryName, Description) VALUES
('Elektronik', 'Peralatan elektronik & gadget'),
('Aksesoris', 'Aksesoris komputer dan gadget'),
('Pakaian', 'Fashion pria dan wanita');

INSERT INTO Customers (FullName, Email, Phone, City, IsActive) VALUES
('Budi Santoso', 'budi.santoso@email.com', '081234567890', 'Jakarta', 1),
('Siti Rahma', 'siti.rahma@email.com', '081298765432', 'Bandung', 1),
('Ahmad Fauzi', 'ahmad.fauzi@email.com', '081311223344', 'Surabaya', 1),
('Dewi Lestari', 'dewi.lestari@email.com', '081555667788', 'Yogyakarta', 0);

INSERT INTO Products (ProductName, CategoryID, Price, Stock) VALUES
('Laptop Pro 14', 1, 14500000.00, 15),
('Wireless Mouse', 2, 250000.00, 50),
('Mechanical Keyboard', 2, 850000.00, 25),
('Kaos Polos Cotton', 3, 75000.00, 100),
('Monitor 24 Inch', 1, 1850000.00, 8);

INSERT INTO Orders (CustomerID, OrderDate, TotalAmount, Status) VALUES
(1001, DATEADD(DAY, -5, SYSDATETIME()), 14750000.00, 'Paid'),
(1002, DATEADD(DAY, -2, SYSDATETIME()), 850000.00, 'Pending'),
(1003, DATEADD(DAY, -1, SYSDATETIME()), 150000.00, 'Shipped');

INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(50001, 1, 1, 14500000.00),
(50001, 2, 1, 250000.00),
(50002, 3, 1, 850000.00),
(50003, 4, 2, 75000.00);
GO

-- Cek apakah semua tabel sudah terisi:
SELECT * FROM Categories;
SELECT * FROM Products;
SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM OrderDetails;
GO

-- latihan 1 MULTI-ROW & OUTPUT ID
INSERT INTO Products (
    ProductName, CategoryID, Price, Stock
)
OUTPUT
    inserted.ProductID,
    inserted.ProductName,
    inserted.Price
VALUES
    ('Earphone TWS Pro', 2, 450000, 30),
    ('Smartwatch Active', 1, 1200000, 20);

-- Latihan 2 UPDATE sinkkronisasi total order
UPDATE o
SET o.TotalAmount = calc.ActualTotal
FROM Orders o
INNER JOIN (
    SELECT OrderID,
           SUM(Quantity * UnitPrice) AS ActualTotal
           FROM OrderDetails
           GROUP BY OrderID
) calc ON o.OrderID = calc.OrderID
WHERE o.OrderID = 50001;


--sofft delete
UPDATE customers
SET IsACtive=0
WHERE CustomerID not IN(
    SELECT DISTINCT CustomerID
    FROM Orders)

--Simulasi atomic checkout
BEGIN TRY
   BEGIN TRANSACTION;
   IF(SELECT Stock from Products WHERE ProductID =2)  < 2
       RAISERROR('Stok produk kurang', 16, 1);
    -- insert 1
    INSERT INTO orders (CustomerID, TotalAmount, Status)
    Values (1002, 500000, 'Paid');
    -- insert 2
    INSERT INTO OrderDetails VALUES (SCOPE_IDENTITY(), 2, 2, 250000);
    -- update
    UPDATE Products SET Stock = Stock - 2 WHERE ProductID = 2;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION ;
END CATCH

--1
insert into Products(
    ProductName, CategoryID, Price, Stock
)
output
    inserted.ProductID,
    inserted.ProductName,
    inserted.Price
values
    ('Webcam Full HD 144p', 2, 690000, 69);

--2
UPDATE p
SET p.Price = ROUND (p.Price * 1.05, 2),
    p.Stock = p.Stock - 1
OUTPUT
    inserted.ProductID,
    inserted.ProductName,
    inserted.Price AS HargaLama,
    inserted.Price AS HargaBaru,
    deleted.Stock AS StokLama,
    inserted.Stock AS StokBaru
FROM Products p
INNER JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE c.CategoryName='Elektronik'
AND p.Stock >= 1;





--3

UPDATE Orders
SET Status = 0 
WHERE Status = 'Cancelled' (
    SELECT *
    FROM Orders);




--4
CREATE TABLE ArchiveCustomer (
    CustomerID INT IDENTITY(1001,1) PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    City VARCHAR(50),
    IsActive BIT DEFAULT 1,
    RegisteredAt DATETIME2 DEFAULT SYSDATETIME()
    )

INSERT INTO ArchiveCustomer
SELECT * FROM Customers c
WHERE c.IsActive = 0