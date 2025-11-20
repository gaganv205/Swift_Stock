import streamlit as st
import mysql.connector
import pandas as pd
import json
from datetime import date

st.set_page_config(page_title="Warehouse Dashboard", layout="wide")

# -------- CONFIG: change DB credentials/defaults if needed ----------
DB_HOST = "localhost"
DB_NAME = "ss"            # change if your schema name is different
# Note: users will provide username/password at login

# ---------- helpers ----------
def get_connection(user, password):
    """Return a new MySQL connection for given user credentials."""
    return mysql.connector.connect(
        host=DB_HOST,
        user=user,
        password=password,
        database=DB_NAME,
        autocommit=True
    )

def query_df(conn, sql, params=None):
    return pd.read_sql(sql, conn, params=params)

def exec_stmt(conn, sql, params=None):
    cur = conn.cursor()
    cur.execute(sql, params or ())
    try:
        conn.commit()
    except Exception:
        pass
    cur.close()

def call_proc(conn, procname, args):
    cur = conn.cursor()
    cur.callproc(procname, args)
    # collect resultsets (if any)
    results = []
    for r in cur.stored_results():
        results.append(pd.DataFrame(r.fetchall(), columns=[c[0] for c in r.description]))
    cur.close()
    return results

# ---------- session & auth ----------
if "auth" not in st.session_state:
    st.session_state.auth = {"logged_in": False, "user": None, "role": None, "pwd": None}

def logout():
    st.session_state.auth = {"logged_in": False, "user": None, "role": None, "pwd": None}
    st.experimental_rerun()

# ---------- Login sidebar ----------
with st.sidebar:
    st.title("Login")
    if not st.session_state.auth["logged_in"]:
        username = st.text_input("DB Username", value="")
        password = st.text_input("DB Password", type="password")
        role = st.selectbox("Role (for UI)", ["customer", "picker", "admin"])
        if st.button("Login"):
            # attempt to connect with provided creds to validate
            try:
                conn = get_connection(username, password)
                conn.close()
                st.session_state.auth = {"logged_in": True, "user": username, "role": role, "pwd": password}
                st.success("Login successful")
                st.experimental_rerun()
            except mysql.connector.Error as e:
                st.error(f"Login failed: {e.msg}")
    else:
        st.write(f"Signed in as: **{st.session_state.auth['user']}** ({st.session_state.auth['role']})")
        if st.button("Logout"):
            logout()

# require auth to continue
if not st.session_state.auth["logged_in"]:
    st.stop()

# make a connection for current user
try:
    conn = get_connection(st.session_state.auth["user"], st.session_state.auth["pwd"])
except Exception as e:
    st.error(f"Could not connect to DB with saved credentials: {e}")
    st.stop()

# ---------- UI: choose view based on role ----------
role = st.session_state.auth["role"]
st.title("🏭 Warehouse Dashboard")

if role == "customer":
    st.header("🛒 Customer Portal")

    tab_new, tab_existing = st.tabs(["New Customer", "Existing Customer"])

    # -------------------------
    # TAB 1: New Customer Registration
    # -------------------------
    with tab_new:
        st.subheader("Register New Customer")
        with st.form("new_customer_form", clear_on_submit=True):
            cust_name = st.text_input("Full Name")
            cust_email = st.text_input("Email ID")
            cust_phone = st.text_input("Phone Number")
            submit_new = st.form_submit_button("Register")

            if submit_new:
                if not cust_name or not cust_email:
                    st.error("Name and Email are required.")
                else:
                    try:
                        cur = conn.cursor()
                        cur.execute("SELECT Customer_ID FROM CUSTOMER WHERE Email_ID = %s", (cust_email,))
                        existing = cur.fetchone()
                        if existing:
                            st.warning("Customer already exists. Please use the 'Existing Customer' tab.")
                        else:
                            cur.execute(
                                "INSERT INTO CUSTOMER (Name, Email_ID, Phone_Number) VALUES (%s, %s, %s)",
                                (cust_name, cust_email, cust_phone)
                            )
                            conn.commit()
                            st.success("🎉 Customer registered successfully! You can now place orders.")
                        cur.close()
                    except Exception as e:
                        st.error(f"Error creating customer: {e}")

    # -------------------------
    # TAB 2: Existing Customer — Place Order
    # -------------------------
    with tab_existing:
        st.subheader("Place an Order")

        # Step 1: Select existing customer
        try:
            cur = conn.cursor()
            cur.execute("SELECT Customer_ID, Name FROM CUSTOMER")
            customers = cur.fetchall()
            cur.close()
            customer_dict = {f"{row[1]} (ID: {row[0]})": row[0] for row in customers}
        except Exception as e:
            st.error(f"Could not load customer list: {e}")
            customer_dict = {}

        if customer_dict:
            selected_customer = st.selectbox("Select Customer", list(customer_dict.keys()))
            customer_id = customer_dict[selected_customer]
        else:
            st.warning("No customers found. Please register a new customer first.")
            customer_id = None

        # Step 2: Show products
        st.subheader("Available Products")
        try:
            df_products = query_df(conn, "SELECT Product_ID, Name, Weight, Popularity FROM PRODUCT")
            st.dataframe(df_products)
        except Exception as e:
            st.error(f"Could not load products: {e}")

        # Step 3: Add order items dynamically
        if "order_items" not in st.session_state:
            st.session_state.order_items = []

        with st.form("existing_order_form", clear_on_submit=False):
            col1, col2 = st.columns([2, 1])
            with col1:
                product_id_in = st.number_input("Product ID", min_value=1, value=1, step=1)
            with col2:
                qty_in = st.number_input("Quantity", min_value=1, value=1, step=1)
            add_item = st.form_submit_button("Add Item to Cart")

            if add_item:
                # Get product details when adding to cart
                product_info = query_df(conn, "SELECT Name, Weight FROM PRODUCT WHERE Product_ID = %s", params=(product_id_in,))
                if not product_info.empty:
                    st.session_state.order_items.append({
                        "product_id": int(product_id_in),
                        "product_name": product_info.iloc[0]['Name'],
                        "quantity": int(qty_in)
                    })
                    st.success("Item added to cart ✅")
                else:
                    st.error("Product not found!")

            # Display cart items in a table format
            if st.session_state.order_items:
                st.write("🧾 Current Cart:")
                cart_df = pd.DataFrame(st.session_state.order_items)
                cart_df.columns = ['Product ID', 'Product Name', 'Quantity']
                st.dataframe(cart_df, use_container_width=True)
            else:
                st.info("Cart is empty")

            submit_order = st.form_submit_button("Submit Order")
            if submit_order and customer_id:
                if len(st.session_state.order_items) == 0:
                    st.error("Add at least one item.")
                else:
                    try:
                        cur = conn.cursor()
                        cur.execute(
                            "INSERT INTO ORDER_TABLE (Customer_ID, Order_Date) VALUES (%s, %s)",
                            (customer_id, date.today())
                        )
                        order_id = cur.lastrowid
                        for item in st.session_state.order_items:
                            cur.execute(
                                "INSERT INTO ORDER_ITEM (Order_ID, Product_ID, Quantity) VALUES (%s, %s, %s)",
                                (order_id, item["product_id"], item["quantity"])
                            )
                        conn.commit()
                        cur.close()
                        st.success(f"✅ Order #{order_id} placed successfully!")
                        st.session_state.order_items = []
                    except Exception as e:
                        st.error(f"Error creating order: {e}")
        # end form


elif role == "picker":
    st.header("Picker Portal")
    st.info("Select your picker identity to view assigned racks & orders.")

    # Let picker choose which Picker_ID they represent (no auth linking)
    try:
        df_p = query_df(conn, "SELECT Picker_ID, Name, Shift FROM PICKER")
        picker_choice = st.selectbox("Select your Picker_ID", df_p["Picker_ID"].tolist())
    except Exception as e:
        st.error(f"Could not load pickers: {e}")
        picker_choice = None

    if picker_choice:
        st.subheader("Your assigned racks & products")
        try:
            sql = """
                SELECT pa.Picker_ID, p.Name AS Picker_Name, pa.Rack_ID, pr.Product_ID, prd.Name AS Product_Name, prd.Weight
                FROM PICKER_ASSIGNMENT pa
                LEFT JOIN PICKER p ON pa.Picker_ID = p.Picker_ID
                LEFT JOIN Product_Storage pr ON pa.Rack_ID = pr.Rack_ID
                LEFT JOIN PRODUCT prd ON pr.Product_ID = prd.Product_ID
                WHERE pa.Picker_ID = %s
            """
            df = query_df(conn, sql, params=(picker_choice,))
            st.dataframe(df)
        except Exception as e:
            st.error(f"Error fetching assignments: {e}")

        st.subheader("Orders assigned to you (per picker_assignment)")
        try:
            sql2 = """
                SELECT pa.Order_ID, o.Order_Date, pa.Rack_ID
                FROM PICKER_ASSIGNMENT pa
                JOIN ORDER_TABLE o ON pa.Order_ID = o.Order_ID
                WHERE pa.Picker_ID = %s
                ORDER BY o.Order_Date DESC
            """
            df2 = query_df(conn, sql2, params=(picker_choice,))
            st.dataframe(df2)
        except Exception as e:
            st.error(f"Error fetching picker orders: {e}")

elif role == "admin":
    st.header("Admin Portal")

    tab1, tab2, tab3 = st.tabs(["Reassignments & Procs", "CRUD Management", "Views & Analytics"])

    # ==============================
    # TAB 1 — PROCEDURES / REASSIGNMENTS
    # ==============================
    with tab1:
        st.subheader("Call stored procedures / reassign product")
        col1, col2 = st.columns([2,2])
        with col1:
            pid = st.number_input("Product_ID to reassign (call reassign_product_safely)", min_value=1, value=1)
            if st.button("CALL reassign_product_safely"):
                try:
                    cur = conn.cursor()
                    cur.callproc("reassign_product_safely", (pid,))
                    cur.close()
                    conn.commit()
                    st.success("Procedure called successfully (check RE_ASSIGNMENT and Product_Storage).")
                except Exception as e:
                    st.error(f"Procedure call failed: {e}")

        with col2:
            n = st.number_input("Top N popular products", min_value=1, value=5)
            if st.button("View top popular"):
                try:
                    results = call_proc(conn, "view_most_popular_products", (n,))
                    if results:
                        st.dataframe(results[0])
                    else:
                        dfp = query_df(conn, "SELECT Product_ID, Name, Popularity FROM PRODUCT ORDER BY Popularity DESC LIMIT %s", params=(n,))
                        st.dataframe(dfp)
                except Exception as e:
                    st.error(f"Could not retrieve popular products: {e}")

        st.subheader("Recent reassignment log (RE_ASSIGNMENT)")
        try:
            df_re = query_df(conn, "SELECT * FROM RE_ASSIGNMENT ORDER BY Reassign_ID DESC LIMIT 50")
            st.dataframe(df_re)
        except Exception as e:
            st.error(f"Could not read RE_ASSIGNMENT: {e}")


    # ==============================
    # TAB 2 — CRUD MANAGEMENT
    # ==============================
    with tab2:
        st.subheader("CRUD Management (Products, Customers, Racks, Pickers)")

        entity = st.selectbox("Select table to manage:", ["Product", "Customer", "Rack", "Picker"])

        if entity == "Product":
            st.markdown("### 🧩 Manage Products")
            df = query_df(conn, "SELECT * FROM PRODUCT")
            st.dataframe(df)

            with st.form("product_form"):
                st.markdown("### ➕ Add / Update Product Details")

                col1, col2, col3 = st.columns(3)
                with col1:
                    pid = st.number_input("Product_ID", min_value=1, step=1)
                    name = st.text_input("Name")
                    weight = st.number_input("Weight (kg)", min_value=0.0, format="%.2f")
                with col2:
                    height = st.number_input("Height (cm)", min_value=0.0, format="%.2f")
                    width = st.number_input("Width (cm)", min_value=0.0, format="%.2f")
                    breadth = st.number_input("Breadth (cm)", min_value=0.0, format="%.2f")
                with col3:
                    popularity = st.number_input("Popularity", min_value=0)

                submitted = st.form_submit_button("Add / Update Product")

                if submitted:
                    try:
                        cur = conn.cursor()
                        cur.execute("""
                            INSERT INTO PRODUCT (Product_ID, Name, Weight, Height, Width, Breadth, Popularity)
                            VALUES (%s, %s, %s, %s, %s, %s, %s)
                            ON DUPLICATE KEY UPDATE 
                                Name = VALUES(Name),
                                Weight = VALUES(Weight),
                                Height = VALUES(Height),
                                Width = VALUES(Width),
                                Breadth = VALUES(Breadth),
                                Popularity = VALUES(Popularity)
                        """, (pid, name, weight, height, width, breadth, popularity))
                        conn.commit()
                        cur.close()
                        st.success("✅ Product added/updated successfully!")
                        st.rerun()  # auto-refresh
                    except Exception as e:
                        st.error(f"❌ Error updating Product: {e}")

            del_id = st.number_input("Delete Product_ID", min_value=1, step=1, key="del_prod")
            if st.button("Delete Product"):
                try:
                    cur = conn.cursor()
                    cur.execute("DELETE FROM PRODUCT WHERE Product_ID=%s", (del_id,))
                    conn.commit()
                    cur.close()
                    st.success("🗑️ Product deleted.")
                    st.rerun()  # refresh table after delete
                except Exception as e:
                    st.error(f"❌ Could not delete: {e}")

        elif entity == "Customer":
            st.markdown("### 👥 Manage Customers")
            df = query_df(conn, "SELECT * FROM CUSTOMER")
            st.dataframe(df)

            with st.form("cust_form"):
                st.markdown("### ➕ Add / Update Customer Details")

                col1, col2 = st.columns(2)
                with col1:
                    cid = st.number_input("Customer_ID", min_value=1, step=1)
                    name = st.text_input("Full Name")
                with col2:
                    email = st.text_input("Email ID")
                    phone = st.text_input("Phone Number")

                submitted = st.form_submit_button("Add / Update Customer")

                if submitted:
                    if not name or not email:
                        st.error("Name and Email are required fields.")
                    else:
                        try:
                            cur = conn.cursor()
                            cur.execute("""
                                INSERT INTO CUSTOMER (Customer_ID, Name, Email_ID, Phone_Number)
                                VALUES (%s, %s, %s, %s)
                                ON DUPLICATE KEY UPDATE 
                                    Name = VALUES(Name),
                                    Email_ID = VALUES(Email_ID),
                                    Phone_Number = VALUES(Phone_Number)
                            """, (cid, name, email, phone))
                            conn.commit()
                            cur.close()
                            st.success("✅ Customer added/updated successfully!")
                            st.rerun()  # auto-refresh table
                        except Exception as e:
                            st.error(f"❌ Error updating Customer: {e}")

            del_id = st.number_input("Delete Customer_ID", min_value=1, step=1, key="del_cust")
            if st.button("Delete Customer"):
                try:
                    cur = conn.cursor()
                    cur.execute("DELETE FROM CUSTOMER WHERE Customer_ID=%s", (del_id,))
                    conn.commit()
                    cur.close()
                    st.success("🗑️ Customer deleted.")
                    st.rerun()  # refresh after delete
                except Exception as e:
                    st.error(f"❌ Could not delete: {e}")


        elif entity == "Rack":
            st.markdown("### 🏗️ Manage Racks")
            df = query_df(conn, "SELECT * FROM RACK")
            st.dataframe(df)

            with st.form("rack_form"):
                st.markdown("### ➕ Add / Update Rack Details")

                col1, col2, col3 = st.columns(3)
                with col1:
                    rid = st.number_input("Rack_ID", min_value=1, step=1)
                with col2:
                    aisle_number = st.text_input("Aisle Number")
                with col3:
                    level = st.text_input("Level")

                distance = st.number_input("Distance (m)", min_value=0.0, format="%.2f")
                submitted = st.form_submit_button("Add / Update Rack")

                if submitted:
                    if aisle_number == "" or level == "":
                        st.error("Aisle Number and Level are required fields.")
                    else:
                        try:
                            cur = conn.cursor()
                            cur.execute("""
                                INSERT INTO RACK (Rack_ID, Aisle_Number, Level, Distance)
                                VALUES (%s, %s, %s, %s)
                                ON DUPLICATE KEY UPDATE 
                                    Aisle_Number = VALUES(Aisle_Number),
                                    Level = VALUES(Level),
                                    Distance = VALUES(Distance)
                            """, (rid, aisle_number, level, distance))
                            conn.commit()
                            cur.close()
                            st.success("✅ Rack added/updated successfully!")
                            st.rerun()  # auto-refresh
                        except Exception as e:
                            st.error(f"❌ Error updating Rack: {e}")

            del_id = st.number_input("Delete Rack_ID", min_value=1, step=1, key="del_rack")
            if st.button("Delete Rack"):
                try:
                    cur = conn.cursor()
                    cur.execute("DELETE FROM RACK WHERE Rack_ID=%s", (del_id,))
                    conn.commit()
                    cur.close()
                    st.success("🗑️ Rack deleted.")
                    st.rerun()
                except Exception as e:
                    st.error(f"❌ Could not delete: {e}")


        elif entity == "Picker":
            st.markdown("### 🧑‍🔧 Manage Pickers")
            df = query_df(conn, "SELECT * FROM PICKER")
            st.dataframe(df)

            with st.form("picker_form"):
                st.markdown("### ➕ Add / Update Picker Details")
                pid = st.number_input("Picker_ID", min_value=1, step=1)
                name = st.text_input("Name")
                shift = st.text_input("Shift")
                submitted = st.form_submit_button("Add / Update Picker")

                if submitted:
                    try:
                        cur = conn.cursor()
                        cur.execute("""
                            INSERT INTO PICKER (Picker_ID, Name, Shift)
                            VALUES (%s, %s, %s)
                            ON DUPLICATE KEY UPDATE Name=VALUES(Name), Shift=VALUES(Shift)
                        """, (pid, name, shift))
                        conn.commit()
                        cur.close()
                        st.success("✅ Picker added/updated successfully!")
                    except Exception as e:
                        st.error(f"❌ Error updating Picker: {e}")

            del_id = st.number_input("Delete Picker_ID", min_value=1, step=1, key="del_picker")
            if st.button("Delete Picker"):
                try:
                    cur = conn.cursor()
                    cur.execute("DELETE FROM PICKER WHERE Picker_ID=%s", (del_id,))
                    conn.commit()
                    cur.close()
                    st.success("🗑️ Picker deleted.")
                except Exception as e:
                    st.error(f"❌ Could not delete: {e}")
    
    # ==============================
    # TAB 3 — DATABASE VIEWS / ANALYTICS
    # ==============================
    with tab3:
        st.subheader("📊 Explore Warehouse Views & Analytics")

        view_mapping = {
            "Picker & Rack Assignments 🧑‍🔧": "vw_picker_rack_products",
            "Full Warehouse Overview 🏭": "vw_admin_warehouse_snapshot",
            "Rack Utilization Status 📦": "vw_rack_product_status",
            "Product Storage Distribution 🔄": "vw_product_storage_comparison",
            "Top 5 Best-Selling Products 🔥": "vw_top_selling_products"
        }

        selected_option = st.selectbox("Select a view to display:", list(view_mapping.keys()))
        selected_view = view_mapping[selected_option]

        # Mapping short descriptions
        desc = {
            "vw_picker_rack_products": "🧑‍🔧 Shows pickers, racks, and the products stored in those racks (LEFT JOIN).",
            "vw_admin_warehouse_snapshot": "🏭 Full warehouse overview with orders, customers, racks, and popularity (multi LEFT JOIN).",
            "vw_rack_product_status": "📦 Rack utilization count (RIGHT JOIN + HAVING).",
            "vw_product_storage_comparison": "🔄 All racks and products (FULL OUTER JOIN simulated via UNION).",
            "vw_top_selling_products": "🔥 Top 5 selling products by total quantity (INNER JOIN + aggregates)."
        }

        st.caption(desc[selected_view])

        if st.button("🔍 Load View Data"):
            try:
                df_view = query_df(conn, f"SELECT * FROM {selected_view} LIMIT 200")
                if len(df_view) == 0:
                    st.info("No data found in this view.")
                else:
                    st.dataframe(df_view, use_container_width=True)
                    st.success(f"✅ Loaded {len(df_view)} rows from {selected_view}")
            except Exception as e:
                st.error(f"❌ Could not load view {selected_view}: {e}")

        st.markdown("---")
        st.write("💡 Tip: These views demonstrate **LEFT JOIN**, **RIGHT JOIN**, **FULL OUTER JOIN**, **NATURAL JOIN (in script)**, **nested queries**, and **aggregates**.")


# ---------- footer ----------
st.sidebar.markdown("---")
st.sidebar.write("DB host:", DB_HOST)
st.sidebar.write("DB:", DB_NAME)
st.sidebar.write("Logged in as: " + st.session_state.auth["user"])

# close connection on exit
conn.close()
