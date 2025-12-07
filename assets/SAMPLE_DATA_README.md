# Pakistani Pharmacy Sample Data

## Overview
This file contains 100+ common pharmacy products found in Pakistani pharmacies with realistic prices in PKR.

## Categories Included

### 1. **Pain Relief & Fever** (6 products)
- Panadol, Disprin, Ponstan Forte, Brufen, etc.
- Price range: PKR 4 - 12 per tablet/dose

### 2. **Antibiotics** (6 products)
- Augmentin, Zithromax, Ciproxin, Cefspan, etc.
- Price range: PKR 160 - 500 per pack

### 3. **Antacids & Digestive** (6 products)
- Gaviscon, Omez, Risek, Motilium, Gelusil, etc.
- Price range: PKR 90 - 500 per pack

### 4. **Cough & Cold** (6 products)
- Rynathsiol, Brofex, Cetrizet, Actifed, etc.
- Price range: PKR 80 - 240 per pack

### 5. **Vitamins & Supplements** (6 products)
- Multivitamins, Calcium D3, Omega-3, Vitamin C, etc.
- Price range: PKR 100 - 400 per pack

### 6. **Diabetes Medicines** (6 products)
- Glucophage, Januvia, Forxiga, Insulatard, etc.
- Price range: PKR 120 - 3000 per pack

### 7. **Blood Pressure Medicines** (6 products)
- Norvasc, Atenolol, Telmisartan, Ramipril, etc.
- Price range: PKR 60 - 300 per pack

### 8. **Cholesterol/Lipid Medicines** (6 products)
- Atorvastatin, Rosuvastatin, Simvastatin, etc.
- Price range: PKR 120 - 500 per pack

### 9. **Dermatological Products** (6 products)
- Fucidin Cream, Betnovate-N, Candid Cream, Elocon, etc.
- Price range: PKR 80 - 400 per tube

### 10. **Eye & Ear Drops** (6 products)
- Tobramycin, Chloramphenicol, Artificial Tears, etc.
- Price range: PKR 80 - 400 per bottle

### 11. **Women's Health** (6 products)
- Folic Acid, Feroglobin, Duphaston, Fluconazole, etc.
- Price range: PKR 60 - 800 per pack

### 12. **Cardiovascular & Neuropsychiatry** (10 products)
- Aspirin, Clopidogrel, Lasix, Alprazolam, Fluoxetine, etc.
- Price range: PKR 20 - 400 per pack

### 13. **Pharmacy Items (Non-Medicine)** (10 products)
- Bandages, Gloves, Syringes, Thermometers, BP Monitors, Masks, etc.
- Price range: PKR 10 - 3000 per item

## How to Import Data

### Option 1: Using SQLite Browser (Recommended for Windows)
1. Download DB Browser for SQLite from: https://sqlitebrowser.org/
2. Open your Stockify database file (usually in `AppData\Local\stockify_db`)
3. Go to "Execute SQL" tab
4. Copy and paste the contents of `sample_pakistan_pharmacy_data.sql`
5. Click "Execute" button
6. Save changes

### Option 2: Using Command Line
```bash
# Navigate to your Stockify database location
cd "C:\Users\<YourUsername>\AppData\Local\stockify_db"

# Import the SQL file
sqlite3 your_database.db < path\to\sample_pakistan_pharmacy_data.sql
```

### Option 3: Programmatic Import (Flutter)
You can also import this data programmatically in your Flutter app by reading the SQL file and executing it through Drift/SQLite.

## Data Structure

Each medicine entry includes:
- **Code**: Unique product code (e.g., PANA001)
- **Name**: Commercial/brand name
- **Generic Name**: Active pharmaceutical ingredient
- **Main Category**: Primary classification
- **Sub Category**: Detailed classification
- **Pack Size**: Number of units (tablets/ml/pieces)
- **Manufacturer**: Pharmaceutical company

Each batch includes:
- **Batch Number**: Unique batch identifier
- **Expiry Date**: Product expiration
- **Quantity**: Stock available
- **Purchase Price**: Cost per pack (PKR)
- **Sale Price**: Selling price per pack (PKR)

## Pricing Information

All prices are in **Pakistani Rupees (PKR)** and represent realistic market prices as of 2024. Prices include:
- **Purchase Price**: Wholesale/cost price (typically 50% of sale price)
- **Sale Price**: Retail/MRP price

## Stock Levels

Initial stock quantities vary by product type:
- High-volume items (painkillers, common antibiotics): 100-250 units
- Medium-volume items (prescription medicines): 60-120 units
- Low-volume items (specialty drugs, devices): 30-70 units

## Expiry Dates

All products have reasonable expiry dates:
- Medicines: 6 months to 2 years from import date
- Medical supplies: 2-5 years from import date
- Devices: 3-5 years from import date

## Notes

- All data is for **demonstration and testing purposes only**
- Prices are approximate and may vary in actual market
- Consult actual pharmaceutical pricing for production use
- Some product names are trademarked by their respective companies
- Always verify batch numbers and expiry dates in real scenarios

## License

This sample data is provided as-is for educational and testing purposes with the Stockify pharmacy management system.
