# Community Food Pantry – Transactional Database System

## Overview
This project is a transactional database designed for a community food pantry to manage food donations, inventory, and distributions to households experiencing food insecurity. The system supports day-to-day operations including donor tracking, inventory management, expiration monitoring, and recipient service history.

## Business Problem
Food pantries must accurately track incoming donations, current inventory, and outgoing distributions while minimizing food waste and ensuring fair access. Manual tracking makes it difficult to monitor stock levels, recognize donors, and enforce first-in, first-out distribution.

## Solution
I designed and implemented a normalized relational database that:
- Records donations and donated items
- Tracks inventory quantities and expiration dates
- Records distributions to recipient households
- Supports reporting on donor activity, recipient service history, and inventory status

## Key Features
- Fully normalized schema (3NF)
- Transactional design using junction tables
- Stored procedures for inserts and reporting
- Inventory-on-hand calculation logic
- Expiration-date tracking to reduce waste

## Technologies Used
- Oracle SQL
- Relational database design (ERD)
- Stored procedures
- SQL queries and reporting

## Documentation
- Conceptual ERD: `/docs/ERD.pdf`
- Business rules and assumptions: `/docs/Letter_of_Engagement.pdf`
- Database schema and queries: `/sql/`

