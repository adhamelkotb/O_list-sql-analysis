# O_list-sql-analysis
SQL analysis of Brazil’s Olist e-commerce dataset using advanced queries (joins, subqueries, window functions).
Tools & Skills
- SQL (PostgreSQL / EXCEL)
- Joins, subqueries, aggregations, window functions
- Data quality checks & preprocessing
- Business KPI analysis

---

## 🔹 Data Cleaning Highlights
- Checked and removed inconsistent orders with missing delivery dates.
- Standardized ZIP codes (customers, sellers, geolocation) by padding leading zeros.
- Replaced NULL product categories with "unknown".
- Validated delivery timestamps and removed illogical records (e.g., delivered before carrier).
- Ensured no negative payment or freight values.

---

## 🔹 Business Insights Highlights
- **Delivery Performance**: Calculated average delivery days by seller and state.  
- **Customer Behavior**: Measured repeat customer percentage and purchasing patterns.  
- **Sales Trends**: Monthly revenue, average order value, and growth rate analysis.  
- **Top Sellers**: Ranked sellers by revenue per month.  

---


## 🚀 How to Use
1. Clone the repository:
   ```bash
   git clone https://github.com/adhamelkotb/O_list-sql-analysis.git
