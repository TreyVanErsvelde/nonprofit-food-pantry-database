-- Community Food Pantry — ISMG 3500 Part 2 (Trey Van Ersvelde)

/* 
 Before you begin, drop the tables in FK→PK order.
 Order matches relationships in the ERD.
 
   DROP PROCEDURE TopDonorsByQuantity_sp;
   DROP PROCEDURE RecipientPriority_sp;
   DROP PROCEDURE CategorySupplyDemand_sp;
   DROP PROCEDURE DonationsByDonor_sp;
   DROP PROCEDURE DistributionsByRecipient_sp;
   DROP PROCEDURE InventoryOnHand_sp;
   DROP PROCEDURE ItemsNearExpiry_sp;
   DROP PROCEDURE InsertDonation_sp;
   DROP PROCEDURE PeopleInSystem_sp;
   
   DROP VIEW DonationSummary_vw;
   DROP VIEW ActiveItems_vw;

   DROP TABLE DistributionItem;
   DROP TABLE Distribution;
   DROP TABLE DonationItem;
   DROP TABLE Donation;
   DROP TABLE Recipient;
   DROP TABLE Item;
   DROP TABLE Donor;
   DROP TABLE Category; 
   DROP TABLE Unit;

   ===========================================================
   1) CREATE TABLES  (columns first, constraints added later)
   =========================================================== */

-- Lookups
CREATE TABLE Category (
  CategoryID        INT           NOT NULL,
  CategoryName      VARCHAR2(60)  NOT NULL,
  LastModifiedDate  DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE Unit (
  UnitID            INT           NOT NULL,
  UnitName          VARCHAR2(30)  NOT NULL,
  LastModifiedDate  DATE          DEFAULT SYSDATE NOT NULL
);

-- Core
CREATE TABLE Donor (
  DonorID           INT           NOT NULL,
  DonorType         VARCHAR2(20)  NOT NULL,        -- Individual | Organization
  FirstName         VARCHAR2(40),
  LastName          VARCHAR2(40),
  OrganizationName  VARCHAR2(100),
  Email             VARCHAR2(120),
  Phone             VARCHAR2(25),
  Address           VARCHAR2(120),
  City              VARCHAR2(60),
  State             CHAR(2),
  Zip               VARCHAR2(10),
  IsActive          CHAR(1)       DEFAULT 'Y' NOT NULL, -- in ERD
  JoinDate          DATE          DEFAULT SYSDATE NOT NULL,
  LastModifiedDate  DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE Recipient (
  RecipientID       INT           NOT NULL,
  FirstName         VARCHAR2(40)  NOT NULL,
  LastName          VARCHAR2(40)  NOT NULL,
  HouseholdSize     INT           NOT NULL,
  Phone             VARCHAR2(25),
  Email             VARCHAR2(120),
  Address           VARCHAR2(120),
  City              VARCHAR2(60),
  State             CHAR(2),
  Zip               VARCHAR2(10),
  EligibilityStatus VARCHAR2(30)  DEFAULT 'Eligible' NOT NULL,
  EnrollmentDate    DATE          DEFAULT SYSDATE NOT NULL,
  LastModifiedDate  DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE Item (
  ItemID            INT            NOT NULL,
  ItemName          VARCHAR2(80)   NOT NULL,
  CategoryID        INT            NOT NULL,
  UnitID            INT            NOT NULL,
  PerishableFlag    CHAR(1)        DEFAULT 'N' NOT NULL,
  ShelfLifeDays     INT,
  IsActive          CHAR(1)        DEFAULT 'Y' NOT NULL,  -- in ERD
  LastModifiedDate  DATE           DEFAULT SYSDATE NOT NULL
);

-- Transactions
CREATE TABLE Donation (
  DonationID        INT            NOT NULL,
  DonorID           INT            NOT NULL,
  DonationDate      DATE           DEFAULT SYSDATE NOT NULL,
  IntakeMethod      VARCHAR2(30),
  ReceivedBy        VARCHAR2(60),
  Notes             VARCHAR2(400),
  LastModifiedDate  DATE           DEFAULT SYSDATE NOT NULL
);

CREATE TABLE DonationItem (
  DonationItemID     INT           NOT NULL,
  DonationID         INT           NOT NULL,
  ItemID             INT           NOT NULL,
  QuantityReceived   INT           NOT NULL,
  BatchDate          DATE          DEFAULT SYSDATE NOT NULL,
  ExpirationDate     DATE,
  LastModifiedDate   DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE Distribution (
  DistributionID     INT           NOT NULL,
  RecipientID        INT           NOT NULL,
  DistributionDate   DATE          DEFAULT SYSDATE NOT NULL,
  FulfilledBy        VARCHAR2(60),
  Notes              VARCHAR2(400),
  LastModifiedDate   DATE          DEFAULT SYSDATE NOT NULL
);

CREATE TABLE DistributionItem (
  DistributionItemID  INT          NOT NULL,
  DistributionID      INT          NOT NULL,
  ItemID              INT          NOT NULL,
  QuantityDistributed INT          NOT NULL,
  LastModifiedDate    DATE         DEFAULT SYSDATE NOT NULL
);
/*
==============================
  2) PRIMARY KEYS & UNIQUE
==============================
*/
ALTER TABLE Category         ADD CONSTRAINT PK_Category          PRIMARY KEY (CategoryID);
ALTER TABLE Unit             ADD CONSTRAINT PK_Unit              PRIMARY KEY (UnitID);
ALTER TABLE Donor            ADD CONSTRAINT PK_Donor             PRIMARY KEY (DonorID);
ALTER TABLE Recipient        ADD CONSTRAINT PK_Recipient         PRIMARY KEY (RecipientID);
ALTER TABLE Item             ADD CONSTRAINT PK_Item              PRIMARY KEY (ItemID);
ALTER TABLE Donation         ADD CONSTRAINT PK_Donation          PRIMARY KEY (DonationID);
ALTER TABLE DonationItem     ADD CONSTRAINT PK_DonationItem      PRIMARY KEY (DonationItemID);
ALTER TABLE Distribution     ADD CONSTRAINT PK_Distribution      PRIMARY KEY (DistributionID);
ALTER TABLE DistributionItem ADD CONSTRAINT PK_DistributionItem  PRIMARY KEY (DistributionItemID);

ALTER TABLE Category ADD CONSTRAINT UQ_CategoryName UNIQUE (CategoryName);
ALTER TABLE Unit     ADD CONSTRAINT UQ_UnitName     UNIQUE (UnitName);


/*
    ==============================
        3) FOREIGN KEYS & CHECKS
    ==============================
*/
ALTER TABLE Item             ADD CONSTRAINT FK_Item_Category          FOREIGN KEY (CategoryID)     REFERENCES Category(CategoryID);
ALTER TABLE Item             ADD CONSTRAINT FK_Item_Unit              FOREIGN KEY (UnitID)         REFERENCES Unit(UnitID);
ALTER TABLE Donation         ADD CONSTRAINT FK_Donation_Donor         FOREIGN KEY (DonorID)        REFERENCES Donor(DonorID);
ALTER TABLE DonationItem     ADD CONSTRAINT FK_DonItem_Donation       FOREIGN KEY (DonationID)     REFERENCES Donation(DonationID);
ALTER TABLE DonationItem     ADD CONSTRAINT FK_DonItem_Item           FOREIGN KEY (ItemID)         REFERENCES Item(ItemID);
ALTER TABLE Distribution     ADD CONSTRAINT FK_Distribution_Recipient FOREIGN KEY (RecipientID)    REFERENCES Recipient(RecipientID);
ALTER TABLE DistributionItem ADD CONSTRAINT FK_DistItem_Dist          FOREIGN KEY (DistributionID) REFERENCES Distribution(DistributionID);
ALTER TABLE DistributionItem ADD CONSTRAINT FK_DistItem_Item          FOREIGN KEY (ItemID)         REFERENCES Item(ItemID);

ALTER TABLE Donor            ADD CONSTRAINT CK_DonorType       CHECK (DonorType IN ('Individual','Organization'));
ALTER TABLE Donor            ADD CONSTRAINT CK_Donor_IsActive  CHECK (IsActive IN ('Y','N'));
ALTER TABLE Item             ADD CONSTRAINT CK_Item_Perishable CHECK (PerishableFlag IN ('Y','N'));
ALTER TABLE Item             ADD CONSTRAINT CK_Item_IsActive   CHECK (IsActive IN ('Y','N'));
ALTER TABLE DonationItem     ADD CONSTRAINT CK_DonItem_Qty     CHECK (QuantityReceived > 0);
ALTER TABLE DistributionItem ADD CONSTRAINT CK_DistItem_Qty    CHECK (QuantityDistributed > 0);
ALTER TABLE Recipient        ADD CONSTRAINT CK_HouseholdSize   CHECK (HouseholdSize >= 1);

/*
    ==============================
       4) SAMPLE DATA (≥10 each)
    ==============================
*/
-- Category (10)
INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (1, 'Canned Goods');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (2, 'Produce');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (3, 'Dairy');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (4, 'Bakery');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (5, 'Meat and Protein');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (6, 'Dry Goods');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (7, 'Beverages');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (8, 'Frozen');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (9, 'Baby and Care');

INSERT INTO Category
    (CategoryID, CategoryName)
VALUES
    (10, 'Household');


-- Unit (10)
INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (1, 'Each');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (2, 'Pound');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (3, 'Ounce');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (4, 'Gallon');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (5, 'Quart');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (6, 'Pint');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (7, 'Dozen');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (8, 'Pack');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (9, 'Bottle');

INSERT INTO Unit
    (UnitID, UnitName)
VALUES
    (10, 'Bag');

-- Donor (10)
INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (1, 'Individual', 'Alice', 'Nguyen', NULL, 'alice.nguyen@example.org', '303-555-1010', '101 Maple St', 'Denver', 'CO', '80202', 'Y', DATE '2025-01-02', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (2, 'Organization', NULL, NULL, 'Mile High Food Bank', 'foodbank@milehigh.org', '303-555-2020', '200 Relief Rd', 'Denver', 'CO', '80203', 'Y', DATE '2025-01-05', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (3, 'Individual', 'Brian', 'Lopez', NULL, 'brian.lopez@example.org', '303-555-3030', '303 Pine Ave', 'Aurora', 'CO', '80012', 'Y', DATE '2025-02-10', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (4, 'Organization', NULL, NULL, 'Downtown Grocers', NULL, '720-555-1111', '44 Market St', 'Denver', 'CO', '80205', 'Y', DATE '2025-02-20', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (5, 'Individual', 'Carmen', 'Diaz', NULL, 'carmen.diaz@example.org', '720-555-2222', '55 Elm Ct', 'Lakewood', 'CO', '80226', 'Y', DATE '2025-03-01', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (6, 'Individual', 'Diego', 'Martinez', NULL, 'diego.m@example.org', '720-555-3333', '12 Birch Ln', 'Arvada', 'CO', '80002', 'Y', DATE '2025-03-03', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (7, 'Individual', 'Elena', 'Rossi', NULL, 'elena.rossi@example.org', '720-555-4444', '888 Cedar St', 'Westminster', 'CO', '80031', 'Y', DATE '2025-03-05', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (8, 'Organization', NULL, NULL, 'Sunrise Church', 'donate@sunrise.org', '720-555-5555', '777 Hope Ave', 'Thornton', 'CO', '80229', 'Y', DATE '2025-03-08', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (9, 'Individual', 'Farah', 'Ali', NULL, 'farah.ali@example.org', '720-555-6666', '19 Aspen Dr', 'Broomfield', 'CO', '80020', 'Y', DATE '2025-03-09', SYSDATE);

INSERT INTO Donor
    (DonorID, DonorType, FirstName, LastName, OrganizationName, Email, Phone, Address, City, State, Zip, IsActive, JoinDate, LastModifiedDate)
VALUES
    (10, 'Organization', NULL, NULL, 'CU Denver Volunteers', 'cud-vols@ucdenver.edu', '720-555-7777', '1201 Speer Blvd', 'Denver', 'CO', '80204', 'Y', DATE '2025-03-10', SYSDATE);


-- Recipient (10)
INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (1, 'Jasmine', 'Cook', 3, '303-555-7001', NULL, '500 Oak St', 'Denver', 'CO', '80209', 'Eligible', DATE '2025-02-01', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (2, 'Marcus', 'Lee', 2, '303-555-7002', NULL, NULL, 'Aurora', 'CO', '80013', 'Eligible', DATE '2025-02-05', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (3, 'Priya', 'Patel', 4, '303-555-7003', NULL, '12 Ridge Rd', 'Lakewood', 'CO', '80226', 'Eligible', DATE '2025-02-08', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (4, 'Noah', 'Kim', 1, '303-555-7004', NULL, '99 Willow Way', 'Denver', 'CO', '80205', 'Eligible', DATE '2025-02-12', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (5, 'Olivia', 'Harris', 5, '303-555-7005', NULL, '10 Juniper Ct', 'Arvada', 'CO', '80003', 'Eligible', DATE '2025-02-14', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (6, 'Harper', 'Wright', 3, '303-555-7006', NULL, '18 Iris Ave', 'Westminster', 'CO', '80031', 'Eligible', DATE '2025-02-17', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (7, 'Mateo', 'Garcia', 2, '303-555-7007', NULL, '221 Spruce St', 'Thornton', 'CO', '80229', 'Eligible', DATE '2025-02-20', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (8, 'Sophia', 'Bennett', 6, '303-555-7008', NULL, '7 Lilac Dr', 'Denver', 'CO', '80211', 'Eligible', DATE '2025-02-22', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (9, 'Aiden', 'Rivera', 4, '303-555-7009', NULL, '66 Violet Ln', 'Aurora', 'CO', '80012', 'Eligible', DATE '2025-02-24', SYSDATE);

INSERT INTO Recipient
    (RecipientID, FirstName, LastName, HouseholdSize, Phone, Email, Address, City, State, Zip, EligibilityStatus, EnrollmentDate, LastModifiedDate)
VALUES
    (10, 'Emma', 'Sanchez', 3, '303-555-7010', NULL, '34 Garden Blvd', 'Lakewood', 'CO', '80227', 'Eligible', DATE '2025-02-26', SYSDATE);


-- Item (10)
INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (1, 'Canned Corn', 1, 1, 'N', NULL, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (2, 'Canned Beans', 1, 1, 'N', NULL, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (3, 'Rice (2 lb bag)', 6, 10, 'N', NULL, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (4, 'Pasta (1 lb)', 6, 10, 'N', NULL, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (5, 'Milk (1 gal)', 3, 4, 'Y', 10, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (6, 'Eggs (dozen)', 3, 7, 'Y', 21, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (7, 'Apples', 2, 2, 'Y', 14, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (8, 'Chicken Breast (lb)', 5, 2, 'Y', 5, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (9, 'Bread Loaf', 4, 1, 'Y', 5, 'Y');

INSERT INTO Item
    (ItemID, ItemName, CategoryID, UnitID, PerishableFlag, ShelfLifeDays, IsActive)
VALUES
    (10, 'Orange Juice (bottle)', 7, 9, 'Y', 12, 'Y');


-- Donation (10)
INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes)
VALUES
    (1, 1, DATE '2025-03-05', 'Dropoff', 'T. Van Ersvelde', 'Monthly donation');

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (2, 2, DATE '2025-03-06', 'Pickup', 'M. Patel', 'Truck route A', SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (3, 3, DATE '2025-03-07', 'Dropoff', 'K. Lewis', NULL, SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (4, 4, DATE '2025-03-07', 'Pickup', 'J. Ortiz', 'Grocery rescue', SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (5, 5, DATE '2025-03-08', 'Drive', 'A. Singh', 'Campus drive', SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (6, 6, DATE '2025-03-09', 'Dropoff', 'C. Chen', NULL, SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (7, 7, DATE '2025-03-10', 'Dropoff', 'B. Park', NULL, SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (8, 8, DATE '2025-03-10', 'Pickup', 'R. Allen', 'Church pantry', SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (9, 9, DATE '2025-03-11', 'Dropoff', 'S. Diaz', NULL, SYSDATE);

INSERT INTO Donation
    (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes, LastModifiedDate)
VALUES
    (10, 10, DATE '2025-03-11', 'Drive', 'J. Morales', 'Student org', SYSDATE);


-- DonationItem (≥12) 
INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate)
VALUES
    (1, 1, 1, 24, DATE '2025-03-05', NULL);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (2, 1, 2, 24, DATE '2025-03-05', NULL, SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (3, 2, 5, 6, DATE '2025-03-06', DATE '2025-03-16', SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (4, 2, 6, 10, DATE '2025-03-06', DATE '2025-03-27', SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (5, 3, 7, 30, DATE '2025-03-07', DATE '2025-03-21', SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (6, 4, 8, 20, DATE '2025-03-07', DATE '2025-03-12', SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (7, 5, 3, 15, DATE '2025-03-08', NULL, SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (8, 6, 4, 18, DATE '2025-03-09', NULL, SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (9, 7, 9, 12, DATE '2025-03-10', DATE '2025-03-15', SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (10, 8, 10, 10, DATE '2025-03-10', DATE '2025-03-22', SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (11, 9, 1, 12, DATE '2025-03-11', NULL, SYSDATE);

INSERT INTO DonationItem
    (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate, LastModifiedDate)
VALUES
    (12, 10, 2, 16, DATE '2025-03-11', NULL, SYSDATE);


-- Distribution (10)
INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes)
VALUES
    (1, 1, DATE '2025-03-12', 'T. Van Ersvelde', 'Weekly');

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (2, 2, DATE '2025-03-12', 'K. Lewis', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (3, 3, DATE '2025-03-13', 'A. Singh', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (4, 4, DATE '2025-03-13', 'R. Allen', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (5, 5, DATE '2025-03-14', 'J. Ortiz', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (6, 6, DATE '2025-03-14', 'C. Chen', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (7, 7, DATE '2025-03-15', 'B. Park', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (8, 8, DATE '2025-03-15', 'A. Garcia', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (9, 9, DATE '2025-03-16', 'M. Patel', NULL, SYSDATE);

INSERT INTO Distribution
    (DistributionID, RecipientID, DistributionDate, FulfilledBy, Notes, LastModifiedDate)
VALUES
    (10, 10, DATE '2025-03-16', 'S. Diaz', NULL, SYSDATE);

-- DistributionItem (≥12)  
INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (1, 1, 1, 4, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (2, 1, 3, 2, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (3, 2, 9, 1, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (4, 2, 5, 1, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (5, 3, 7, 6, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (6, 4, 8, 2, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (7, 5, 2, 4, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (8, 6, 4, 3, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (9, 7, 10, 2, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (10, 8, 6, 1, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (11, 9, 1, 2, SYSDATE);

INSERT INTO DistributionItem
    (DistributionItemID, DistributionID, ItemID, QuantityDistributed, LastModifiedDate)
VALUES
    (12, 10, 3, 2, SYSDATE);


COMMIT;








-- veiw 1

CREATE VIEW ActiveItems_vw

AS

/*-------------------------------------------------------------------------------------------------
CREATED: December 2, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns all active items with category and unit names. Helps staff quickly find all
             items currently available in the system.

 Example:
        SELECT ItemID, ItemName, CategoryName, UnitName
        FROM   ActiveItems_vw;

CHANGE HISTORY
Date            Modified By        Notes
12/02/2025      TVE                View Created
----------------------------------------------------------------------------------------------------*/

SELECT     I.ItemID, I.ItemName, C.CategoryName, U.UnitName, I.PerishableFlag,
           I.ShelfLifeDays, I.IsActive, I.LastModifiedDate
FROM       Item I
INNER JOIN Category C
ON         I.CategoryID = C.CategoryID
INNER JOIN Unit U
ON         I.UnitID = U.UnitID
WHERE      I.IsActive = 'Y';

COMMIT;
/




--veiw 2

CREATE VIEW DonationSummary_vw

AS

/*-------------------------------------------------------------------------------------------------
CREATED: December 2, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Summarizes each donation with total quantity received. Supports dashboards and donor
             analytics.

 Example:
        SELECT DonationID, DonationDate, TotalQuantity
        FROM   DonationSummary_vw;

CHANGE HISTORY
Date            Modified By        Notes
12/02/2025      TVE                View Created
----------------------------------------------------------------------------------------------------*/

SELECT    D.DonationID, D.DonationDate, D.DonorID,
          NVL(SUM(DI.QuantityReceived), 0) AS TotalQuantity
FROM      Donation D
LEFT JOIN DonationItem DI
ON        D.DonationID = DI.DonationID
GROUP BY  D.DonationID, D.DonationDate, D.DonorID;

COMMIT;
/



















--Stored Procedure 1

CREATE OR REPLACE PROCEDURE DonationsByDonor_sp

(
    p_donor_id    IN INT,
    p_start_date  IN DATE,
    p_end_date    IN DATE
)

AS DBD SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: November 14, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns all donations and items made by a specific donor within a date range.

 Example: DECLARE
            p_donor_id    INT;
            p_start_date  DATE;
            p_end_date    DATE;
          BEGIN
            DonationsByDonor_sp
                (1, DATE '2025-03-01', DATE '2025-03-31');
          END;

CHANGE HISTORY
Date            Modified By        Notes
11/14/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN DBD FOR

    SELECT     D.DonationID, D.DonationDate, I.ItemName, DI.QuantityReceived, DI.ExpirationDate
    FROM       Donation D
    INNER JOIN DonationItem DI 
    ON         D.DonationID = DI.DonationID
    INNER JOIN Item I 
    ON         DI.ItemID = I.ItemID
    WHERE      D.DonorID = p_donor_id
    AND        D.DonationDate BETWEEN p_start_date AND p_end_date
    ORDER BY   D.DonationDate;

DBMS_SQL.RETURN_RESULT(DBD);

END;
/



--Stored Procedure 2

CREATE OR REPLACE PROCEDURE DistributionsByRecipient_sp

(
    p_recipient_id IN INT,
    p_start_date   IN DATE,
    p_end_date     IN DATE
)

AS DBR SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: November 14, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns all distributions and items given to a specific recipient within a date range.

 Example: DECLARE
            p_recipient_id   INT;
            p_start_date     DATE;
            p_end_date       DATE;
          BEGIN
            DistributionsByRecipient_sp
                (2, DATE '2025-03-01', DATE '2025-03-31');
          END;

CHANGE HISTORY
Date            Modified By        Notes
11/14/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/
    
BEGIN

OPEN DBR FOR
    
    SELECT     DT.DistributionID, DT.DistributionDate, I.ItemName, DI.QuantityDistributed
    FROM       Distribution DT
    INNER JOIN DistributionItem DI 
    ON         DT.DistributionID = DI.DistributionID
    INNER JOIN Item I 
    ON         DI.ItemID = I.ItemID
    WHERE      DT.RecipientID = p_recipient_id
    AND        DT.DistributionDate BETWEEN p_start_date AND p_end_date
    ORDER BY   DT.DistributionDate;

DBMS_SQL.RETURN_RESULT(DBR);

END;
/



--Stored Procedure 3

CREATE OR REPLACE PROCEDURE InventoryOnHand_sp

(
    p_item_id IN INT
)

AS IOH SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: November 14, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns current stock level for a selected item using subqueries.

 Example: DECLARE
            p_item_id   INT;
          BEGIN
            InventoryOnHand_sp
                (5);
          END;
CHANGE HISTORY
Date            Modified By        Notes
11/14/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN IOH FOR

    SELECT I.ItemID, I.ItemName, NVL((SELECT SUM(DI.QuantityReceived) 
                                      FROM   DonationItem DI
                                      WHERE  DI.ItemID = p_item_id), 0) -
                                 NVL((SELECT SUM(DSI.QuantityDistributed) 
                                      FROM   DistributionItem DSI
                                      WHERE  DSI.ItemID = p_item_id), 0) AS InventoryOnHand
    FROM   Item I
    WHERE  I.ItemID = p_item_id;

DBMS_SQL.RETURN_RESULT(IOH);

END;
/


--Stored Procedure 4

CREATE OR REPLACE PROCEDURE ItemsNearExpiry_sp

AS INE SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: November 14, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Identifies donated item batches that expire within the next 7 days.

 Example:
        EXEC ItemsNearExpiry_sp;

CHANGE HISTORY
Date            Modified By        Notes
11/14/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN INE FOR

    SELECT     I.ItemName, DI.QuantityReceived, DI.ExpirationDate
    FROM       DonationItem DI
    INNER JOIN Item I 
    ON         DI.ItemID = I.ItemID
    WHERE      DI.ExpirationDate IS NOT NULL
    AND        DI.ExpirationDate <= SYSDATE + 7
    ORDER BY   DI.ExpirationDate;

DBMS_SQL.RETURN_RESULT(INE);

END;
/


--Stored Procedure 5

CREATE OR REPLACE PROCEDURE InsertDonation_sp

(
    p_donor_id          IN INT,
    p_item_id           IN INT,
    p_quantity_received IN INT,
    p_batch_date        IN DATE,
    p_expiration_date   IN DATE
)

AS vDonationID INT;

/*-------------------------------------------------------------------------------------------------
CREATED: November 14, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Inserts a new donation (one item per execution) as a controlled transaction.

 Example: DECLARE
            p_donor_id          INT;
            p_item_id           INT;
            p_quantity_received INT;
            p_batch_date        DATE;
            p_expiration_date   DATE;
          BEGIN
            InsertDonation_sp
                (3, 5, 10, DATE '2025-03-20', DATE '2025-03-30');
          END;

CHANGE HISTORY
Date            Modified By        Notes
11/14/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

    SELECT NVL(MAX(D.DonationID), 0) + 1 
    INTO   vDonationID 
    FROM   Donation D;

    INSERT INTO Donation
        (DonationID, DonorID, DonationDate, IntakeMethod, ReceivedBy, Notes)
    VALUES
        (vDonationID, p_donor_id, SYSDATE, 'Dropoff', 'System', 'Inserted via stored procedure');

    INSERT INTO DonationItem
        (DonationItemID, DonationID, ItemID, QuantityReceived, BatchDate, ExpirationDate)
    VALUES
        ((SELECT NVL(MAX(DonationItemID), 0) + 1 
          FROM DonationItem),
          vDonationID, p_item_id, p_quantity_received, p_batch_date, p_expiration_date);

COMMIT;

END;
/



--Stored Procedure 6

CREATE OR REPLACE PROCEDURE PeopleInSystem_sp

AS PIS SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: November 14, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns donors and recipients in a unified list using UNION.

 Example:
        EXEC PeopleInSystem_sp;

CHANGE HISTORY
Date            Modified By        Notes
11/14/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN PIS FOR

    SELECT   D.DonorID AS PersonID, NVL(D.FirstName, D.OrganizationName) AS FirstName, D.LastName, D.City, D.State
    FROM     Donor D

    UNION

    SELECT   R.RecipientID AS PersonID, R.FirstName, R.LastName, R.City, R.State 
    FROM     Recipient R
    ORDER BY 1, 2;

DBMS_SQL.RETURN_RESULT(PIS);

END;
/




--Stored Procedure 7

CREATE OR REPLACE PROCEDURE TopDonorsByQuantity_sp

(
    p_min_total_qty IN INT
)

AS TDQ SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: December 2, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns donors whose total donated quantity meets or exceeds a minimum threshold.
             Uses GROUP BY and HAVING to support donation analytics.

 Example:
          EXEC TopDonorsByQuantity_sp(50);



CHANGE HISTORY
Date            Modified By        Notes
12/02/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN TDQ FOR

    SELECT     D.DonorID, NVL(D.FirstName, D.OrganizationName) AS DonorName,
               SUM(DS.TotalQuantity) AS TotalQuantityDonated
    FROM       DonationSummary_vw DS
    INNER JOIN Donor D
    ON         DS.DonorID = D.DonorID
    GROUP BY   D.DonorID,
               NVL(D.FirstName, D.OrganizationName)
    HAVING     SUM(DS.TotalQuantity) >= p_min_total_qty
    ORDER BY   TotalQuantityDonated DESC;

DBMS_SQL.RETURN_RESULT(TDQ);

END;
/



--Stored Procedure 8

CREATE OR REPLACE PROCEDURE RecipientPriority_sp

AS RP SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: December 2, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Returns recipients with a computed "PriorityLevel" using a CASE expression based on
             household size and eligibility status. Also shows how many distributions they have
             received to date.

 Example:
          EXEC RecipientPriority_sp;


CHANGE HISTORY
Date            Modified By        Notes
12/02/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN RP FOR

    SELECT          R.RecipientID, R.FirstName, R.LastName, R.HouseholdSize, R.EligibilityStatus,
                    NVL(COUNT(DISTINCT DT.DistributionID), 0) AS TotalDistributions,
                    CASE WHEN R.EligibilityStatus <> 'Eligible' 
                         THEN 'Inactive / On Hold'
                         WHEN R.HouseholdSize >= 5          
                         THEN 'High Priority'
                         WHEN R.HouseholdSize BETWEEN 3 AND 4 
                         THEN 'Medium Priority'
                    ELSE 'Standard Priority'
                    END AS PriorityLevel
    FROM            Recipient R
    LEFT OUTER JOIN Distribution DT
    ON              R.RecipientID = DT.RecipientID
    GROUP BY        R.RecipientID, R.FirstName, R.LastName, R.HouseholdSize, R.EligibilityStatus
    ORDER BY        PriorityLevel DESC, TotalDistributions DESC, R.LastName, R.FirstName;

DBMS_SQL.RETURN_RESULT(RP);

END;
/





--Stored Procedure 9

CREATE OR REPLACE PROCEDURE CategorySupplyDemand_sp

(
    p_category_id IN INT
)

AS CSD SYS_REFCURSOR;

/*-------------------------------------------------------------------------------------------------
CREATED: December 2, 2025
AUTHOR:  Trey Van Ersvelde
DESCRIPTION: Compares total quantity received vs. total quantity distributed for each item in a
             given category. Helps the pantry see which items are oversupplied or undersupplied.

 Example:
          EXEC CategorySupplyDemand_sp(1);   -- Canned Goods category, for example


CHANGE HISTORY
Date            Modified By        Notes
12/02/2025      TVE                Procedure Created
----------------------------------------------------------------------------------------------------*/

BEGIN

OPEN CSD FOR

    SELECT          I.ItemID, I.ItemName, C.CategoryName, NVL(SUM(DI.QuantityReceived), 0) AS TotalReceived,
                    NVL(SUM(DSI.QuantityDistributed), 0) AS TotalDistributed,
                    NVL(SUM(DI.QuantityReceived), 0) - NVL(SUM(DSI.QuantityDistributed), 0)  AS NetInventory
    FROM            Item I
    INNER JOIN      Category C
    ON              I.CategoryID = C.CategoryID
    LEFT OUTER JOIN DonationItem DI
    ON              I.ItemID = DI.ItemID
    LEFT OUTER JOIN DistributionItem DSI
    ON              I.ItemID = DSI.ItemID
    WHERE           I.CategoryID = p_category_id
    GROUP BY        I.ItemID, I.ItemName, C.CategoryName
    ORDER BY        NetInventory DESC, I.ItemName;

DBMS_SQL.RETURN_RESULT(CSD);

END;
/



