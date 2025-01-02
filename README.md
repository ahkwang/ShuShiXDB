# SushiX Database System

## Overview
A comprehensive database management system for a sushi restaurant chain that handles customer orders, reservations, menu management, and employee tracking.

## Database Schema

### Core Tables

#### Restaurant Management
- **KHUVUC** - Regional areas where restaurants are located
- **CHINHANH** - Branch/restaurant locations
- **BOPHAN** - Departments
- **NHANVIEN** - Employee information
- **LICHSULAMVIEC** - Employee work history

#### Menu Management
- **MUCTHUCDON** - Menu categories
- **MONAN** - Dishes/menu items
- **CHINHANH_MON** - Available dishes at each branch

#### Customer Management
- **KHACHHANG** - Customer information
- **THETHANHVIEN** - Membership cards
- **LICHSUTRUYCAP** - Customer access logs

#### Order Management
- **BAN** - Tables in restaurants
- **DATBAN** - Table reservations
- **THONGTINPHIEUDATMON** - Order information
- **CHITIETPHIEUDATMON** - Order details
- **HOADON** - Invoices
- **DANHGIA** - Customer reviews

## Key Features
- Multi-branch restaurant management
- Menu and inventory tracking
- Table reservation system
- Order processing
- Customer membership program
- Employee management
- Customer feedback system
- Sales reporting

## Setup Instructions

### Database Creation
Execute the schema creation scripts in the following order:

1. `script_nokey.sql` - Creates tables without constraints
2. `script_key.sql` - Adds primary/foreign keys and constraints
3. `index.sql` - Creates performance indexes
4. `procedures.sql` - Creates stored procedures

### File Structure
```shell
.
├── script_nokey.sql    # Initial table creation
├── script_key.sql      # Constraints and relationships
├── index.sql          # Database indexes
├── procedures.sql     # Stored procedures
├── script_generate_data.py  # Sample data generator
└── data/             # Sample data files