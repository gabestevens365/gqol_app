from credentials.credentials_sosdb import host, port, username, password, database
import os
import datetime
from datetime import date, datetime
import mysql.connector
import pandas as pd
import numpy as np


# Function to connect to the MySQL database
def connect_to_database():
    try:
        mysql.connector.raise_on_warnings = True
        conn = mysql.connector.connect(
            host=host,
            port=port,
            user=username,
            password=password,
            database=database)
        print(f"Connected to the database successfully!")
        return conn
    except mysql.connector.Error as error:
        print(f"Failed to connect to the database: {error}")
        return None


# Function to execute a SQL query and return the results as a pandas DataFrame
def execute_query(conn, query_file):
    query_starttime = datetime.now()
    print(f"Starting the query at {query_starttime.strftime('%Y-%m-%d @ %H:%M:%S')}")
    try:
        cursor = conn.cursor()

        with open(query_file, 'r') as file:
            query = file.read()

        cursor.execute(query)
        results = cursor.fetchall()
        columns = [column[0] for column in cursor.description]

        # Convert bytes columns to utf-8 strings
        decoded_results = []
        for row in results:
            decoded_row = []
            for item in row:
                if isinstance(item, bytes):
                    decoded_row.append(item.decode('utf-8'))
                else:
                    decoded_row.append(item)
            decoded_results.append(decoded_row)

        df = pd.DataFrame(decoded_results, columns=columns)
        query_endtime = datetime.now()
        query_elapsed = (query_endtime - query_starttime).total_seconds()
        print(f"Ending the query at {query_endtime.strftime('%Y-%m-%d @ %H:%M:%S')}"
              f", elapsed time: {int(query_elapsed)} seconds.")
        return df
    except mysql.connector.Error as error:
        print(f"Failed to execute the query: {error}")
        return None


# Function to save a DataFrame as an Excel file
def save_to_excel(df, file_name, sheet_name, table_name):
    try:
        # TODO: Add a "Summary" sheet with a pivot table explaining the data
        with pd.ExcelWriter(file_name, engine='xlsxwriter') as writer:
            # Write to DataFrame to Excel
            df.to_excel(writer, sheet_name=sheet_name, index=False)
            worksheet = writer.sheets[sheet_name]

            # Auto-Width for each column, with a max of 60.
            for i, col in enumerate(df.columns):
                column_width = max(df[col].astype(str).map(len).max(), len(col))
                if column_width > 59:
                    column_width = 59
                worksheet.set_column(i, i, column_width + 1)

        print(f"Data saved to '{file_name}' successfully!")
        main_menu()
    except Exception as error:
        print(f"Failed to save the data to Excel file: {error}")
        main_menu()


# Find the most recent report in the folder
def find_latest_report(report_path, report_name, report_date):
    # Filter files in the report_path that start with report_name and include report_date
    matching_files = [file for file in os.listdir(report_path) if file.startswith(report_name) and report_date in file]

    if matching_files:
        # Sort the matching_files based on their modification time (newest first)
        sorted_files = sorted(matching_files, key=lambda f: os.path.getmtime(os.path.join(report_path, f)), reverse=True)
        latest_report = sorted_files[0]
        return latest_report
    else:
        return None


# Main menu function
def main_menu():
    print("=== Main Menu ===")
    print("1. ADM / v5 Reports")
    print("0. Quit")

    choice = input("Enter your choice: ")

    if choice == '1':
        adm_v5_reports_menu()
    elif choice == '0':
        print("Exiting the program. Goodbye!")
        return
    else:
        print("Invalid choice. Please try again.")
        main_menu()


# ADM / v5 Reports sub-menu
def adm_v5_reports_menu():
    print("=== ADM / v5 Reports ===")
    print("1. All Devices Reports")
    print("2. OS Upgrade Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        adm_all_devices_reports_menu()
    elif choice == '2':
        adm_os_upgrade_reports_menu()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        adm_v5_reports_menu()


# All Devices Reports Menu
def adm_all_devices_reports_menu():
    print("=== All Devices Reports ===")
    print("1. All-Devices Report - 365RM (This one is everything in ADM)")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == "1":
        adm_all_devices_report()
    elif choice == "0":
        main_menu()
    else:
        print("Invalid Choice. Please try again.")
        adm_all_devices_reports_menu()


# ADM OS Upgrade Reports Menu
def adm_os_upgrade_reports_menu():
    # TODO: Implement the adm_os_upgrade_reports submenu
    print("=== ADM OS Upgrade Reports ===")
    print("1. Kiosk-Age Report - 365RM")
    print("2. Kiosk-Age Report - Canteen")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == "1":
        v5_kiosk_age_report_365rm()
    elif choice == "2":
        v5_kiosk_age_report_canteen()
    elif choice == "0":
        main_menu()
    else:
        print("Invalid Choice. Please try again.")
        adm_all_devices_reports_menu()


# The All-Devices Reports
def adm_all_devices_report():
    today = date.today()
    formatted_date = today.strftime("%Y-%m-%d")

    current_time = datetime.now()
    formatted_time = current_time.strftime("%H%M")

    report_path = "./reports/AllDevices/"
    report_name = "ADM_All_Devices_Report"
    report_date = formatted_date
    report_time = formatted_time
    report_ext = ".xlsx"

    # MySQL query
    query_file = "./queries/v5_All_Device_Report.sql"

    print(f"{report_name} for {report_date} at {report_time}...")

    # Check to see whether the file already exists, first.
    report_exists = find_latest_report(report_path, report_name, report_date)
    if report_exists == None:
        print(f"Generating the first copy of {report_name} for {report_date}.")
    else:
        print(f"{report_path}{report_exists} already exists!\n")
        choice = input("Do you want to generate a new copy? [Y/N]: ")
        choice = choice.upper()

    if choice == "Y":
        print(f"Generating a new copy of {report_name} for {report_date}

        # Connect to the database
        connection = connect_to_database()
        if connection is None:
            return

        # Execute the query
        result_df = execute_query(connection, query_file)
        if result_df is None:
            connection.close()
            return

        # Save the result to an Excel file
        sheetname = "All ADM-v5 Devices"
        tablename = "t.v5"
        final_file_name = report_path + report_name + "_" + report_date + "_" + report_time + report_ext
        save_to_excel(result_df, final_file_name, sheetname, tablename)
    elif choice == "N":
        main_menu()
    else:
        print("Invalid Choice.")
        adm_all_devices_reports_menu()


# KioskAge Report - All 365
def v5_kiosk_age_report_365rm():
    # Let's get some date and time variables.
    today = date.today()
    current_time = datetime.now()
    formatted_date = today.strftime("%Y-%m-%d")
    formatted_time = current_time.strftime("%H%M")

    # Let's get some report metadata variables.
    report_path = "./reports/KioskAge/"
    report_name = "KioskAge_Report"
    report_date = formatted_date
    report_time = formatted_time
    report_ext = ".xlsx"
    query_file = "./queries/v5_KioskAge_Report.sql"

    # Announce the report we're starting to generate.
    print(f"{report_name} for {report_date} at {formatted_time}...")

    # Check to see whether the file already exists, first.
    report_exists = find_latest_report(report_path, report_name, report_date)
    if report_exists == None:
        print(f"Generating the first copy of {report_name} for {report_date}.")
    else:
        print(f"{report_path}{report_exists} already exists!\n")
        choice = input("Do you want to generate a new copy? [Y/N]: ")
        choice = choice.upper()

    if choice == "Y":
        print(f"Generating a new copy of {report_name} for {report_date}

        # Connect to the database
        connection = connect_to_database()
        if connection is None:
            return

        # Execute the query
        result_df = execute_query(connection, query_file)
        if result_df is None:
            connection.close()
            return

        # Map the "Device Serial" column to "VSH Generation" column values
        conditions = [
            result_df['Device Serial'].str.contains('VSH1|VSH2|VSH3'),
            result_df['Device Serial'].str.contains('VSH4|VSH5|VSH9'),
            result_df['Device Serial'].str.contains('VSH6'),
            result_df['Device Serial'].str.contains('KSK')
        ]
        values = ['Legacy', 'Misc', 'v5 Native', 'ReadyTouch']
        result_df['VSH Generation'] = np.select(conditions, values, default='Misc')

        # Extract the CPU from the "systemInfo" column and fill in the "CPU Product" column with it.
        result_df['CPU Product'] = result_df['systemInfo'].str.extract(r'product=([^|]+)')

        # Delete the "SystemInfo" column
        result_df.drop('systemInfo', axis=1, inplace=True)

        # Exclude specific CPU Products from the dataframe
        excluded_cpu_products = [
            'Elo AiO',
            'Elo AiO X3',
            'EloPOS E2/S2/H2',
            'EloPOS E3/S3/H3',
            'MMH81AP-FH',
            'OptiPlex 7010',
            'S11G',
            'S11M',
            'W11G',
            'W11HS2'
        ]
        result_df = result_df[~result_df['CPU Product'].isin(excluded_cpu_products)]

        # Sort the DataFrame by multiple columns
        result_df = result_df.sort_values(
            by=["Operation Group", "Division", "Operation Name", "Location Name", "Model"])

        # Save the result to an Excel file
        sheetname = "All VSH KioskAges"
        tablename = 't.v5'
        final_file_name = report_path + report_name + "_" + report_date + "_" + report_time + report_ext
        save_to_excel(result_df, final_file_name, sheetname, tablename)
    elif choice == "N":
        main_menu()
    else:
        print("Invalid Choice.")
        adm_os_upgrade_reports_menu()


# v5 KioskAge Report - Canteen
def v5_kiosk_age_report_canteen():
    # This report is a subset of the KioskAge Report - All 365 report
    print("Generating the KioskAge Report for Canteen...")
    # First let's check to see if the All 365 version of the report already exists.
    # Check to see whether the file already exists, first.
        # If yes, choose and open the newest version of it, and load the data as a dataframe.
        # If no, run it, then open it, and load the data as a dataframe.
    # Remove all operator groups EXCEPT "Canteen", "Canteen_Dining", and "CompassGroup"
    # Re-sort the data
    # Save the dataframe as a new KioskAge Report - Canteen file.


# Entry point of the program
if __name__ == '__main__':
    main_menu()
