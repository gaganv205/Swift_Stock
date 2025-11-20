# Swift_Stock - Smart E-Commerce Warehouse Management System

## Problem Statement
E-commerce warehouses struggle with managing large volumes of products and fulfilling orders efficiently. Poor product placement increases picker travel time, while the absence of order history analysis and real-time tracking leads to delays, higher operational costs, and reduced customer satisfaction.

---

## Project Overview
This system provides an intelligent warehouse management solution tailored for e-commerce operations. It maintains detailed records of:

- Products  
- Racks  
- Customers  
- Orders  
- Pickers & Picking Activity  

Using order history data, the system determines product popularity and enables **dynamic rack reassignment**—moving frequently ordered products closer to the packing area to minimize picker travel distance.

The system also:
- Assigns pickers to orders  
- Records their picking activity  
- Tracks order status (Pending → Picked → Shipped) in real time  
- Generates insights for warehouse optimization  

This integrated approach speeds up order fulfilment, reduces costs, and supports better decision-making for warehouse managers.

---

## Tech Stack
- **Database:** MySQL  
- **Frontend:** Streamlit  
- **Programming Language:** Python  
- **SQL Script:** `final_commands.sql`  

---

## Set Up the MySQL Database
- Install MySQL Server (if not installed).
- Create a database (example: warehouse_db).
- Run the SQL script:
  `mysql -u root -p warehouse_db < final_commands.sql`

---

## Run the Streamlit Application
- Use the following command:
  `streamlit run frontend.py`
- Streamlit will automatically open the app in your browser at:
  `http://localhost:8501`
