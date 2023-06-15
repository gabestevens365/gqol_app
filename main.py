import mysql.connector
import pandas as pd
import datetime
import os
from datetime import date
from credentials_sosdb import host, port, username, password, database


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
    query_starttime = datetime.datetime.now()
    print(f"Starting the query at {query_starttime}")
    try:
        cursor = conn.cursor()

        with open(query_file, 'r') as file:
            query = file.read()

        cursor.execute(query)
        results = cursor.fetchall()
        columns = [column[0] for column in cursor.description]
        df = pd.DataFrame(results, columns=columns)
        query_endtime = datetime.datetime.now()
        query_elapsed = (query_endtime - query_starttime).total_seconds()
        print(f"Ending the query at {query_endtime}, elapsed time: {query_elapsed}.")
        # Fix the elapsed time to show in seconds.
        return df
    except mysql.connector.Error as error:
        print(f"Failed to execute the query: {error}")
        return None


# Function to save a DataFrame as an Excel file with UTF-8 encoding
def save_to_excel(df, file_name, sheet_name):
    try:
        # TODO: Auto-size the column widths, with column_dimensions[column_letter].width
        # TODO: Put the data into a named Excel Table so it can use local variables in formulas
        # TODO: Add a "Summary" sheet with a pivot table explaining the data
        # TODO: Move the Duplicate Name Checker into it's own function and call it from here.
        today = date.today()
        formatted_date = today.strftime("_%Y-%m-%d")
        formatted_time = ''
        final_file_name = file_name + formatted_date + formatted_time + ".xlsx"
        print(f"The filename we are testing against is: {final_file_name}.")
        if os.path.exists(final_file_name):
            choice = input("That file already exists!\n\nChoose an option:"
                           "\n1. Cancel"
                           "\n2. Rename the file (append new filename with time)"
                           "\n3. Overwrite the original file"
                           "\n#:")
            if choice == "1":
                print("Operation Cancelled")
                main_menu()
                # TODO: Figure out how to return the user to the menu they came from, not just the main menu.
            elif choice == "2":
                todaytime = datetime.datetime.now().time()
                formatted_time = todaytime.strftime("_%H%M%S")
                print("You are saving a second copy of this file, please note your specific file name.")
            elif choice == "3":
                print("Overwriting the original file (if that was the wrong choice it's too late, please panic).")
            else:
                print("That wasn't one of your choices.")
                main_menu()
                # TODO: Figure out how to return the user to the menu they came from, not just the main menu.
        final_file_name = file_name + formatted_date + formatted_time + ".xlsx"
        df.to_excel(final_file_name, sheet_name=sheet_name, index=False)
        # TODO: Re-write this to use more choices than just .XLSX, this is a terrible way to do this!
        print(f"Data saved to '{final_file_name}' successfully!")
    except Exception as error:
        print(f"Failed to save the data to Excel file: {error}")


# Main menu function
def main_menu():
    print("=== Main Menu ===")
    print("1. ADM / v5 Reports")
    print("2. AirVend Reports")
    print("3. Avanti Reports")
    print("4. CK Reports")
    print("5. Legacy Reports")
    print("6. Stockwell Reports")
    print("0. Quit")

    choice = input("Enter your choice: ")

    if choice == '1':
        adm_v5_reports_menu()
    elif choice == '2':
        airvend_reports_menu()
    elif choice == '3':
        avanti_reports_menu()
    elif choice == '4':
        ck_reports_menu()
    elif choice == '5':
        legacy_reports_menu()
    elif choice == '6':
        stockwell_reports_menu()
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
    print("3. Hardware Replacement Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        adm_all_devices_reports()
    elif choice == '2':
        adm_os_upgrade_reports()
    elif choice == '3':
        adm_hardware_replacement_reports()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        adm_v5_reports_menu()


# All Devices Reports
def adm_all_devices_reports():
    print("Generating All Devices Reports...")
    # MySQL query
    query_file = "./queries/v5_All_Device_Report.sql"

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
    filename = f"./reports/adm_all_devices_report"
    sheetname = "All ADM-v5 Devices"
    save_to_excel(result_df, filename, sheetname)


# OS Upgrade Reports
def adm_os_upgrade_reports():
    # TODO: Implement the adm_os_upgrade query and save the results as an Excel file
    print("Generating OS Upgrade Reports...")


# Hardware Replacement Reports
def adm_hardware_replacement_reports():
    # TODO: Implement the adm_hardware_replacement query and save the results as an Excel file
    print("Generating Hardware Replacement Reports...")


# AirVend Reports sub-menu
def airvend_reports_menu():
    print("=== AirVend Reports ===")
    print("1. All Devices Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        airvend_all_devices_reports()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        airvend_reports_menu()


def airvend_all_devices_reports():
    # TODO: Implement the airvend_all_devices query and save the results as an Excel file
    print("Generating AirVend All-Devices Report...")


# Avanti Reports sub-menu
def avanti_reports_menu():
    print("=== Avanti Reports ===")
    print("1. All Devices Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        avanti_all_devices_reports()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        avanti_reports_menu()


def avanti_all_devices_reports():
    # TODO: Implement the avanti_all_devices query and save the results as an Excel file
    print("Generating Avanti All-Devices Report...")


# CompanyKitchen Reports sub-menu
def ck_reports_menu():
    print("=== CompanyKitchen Reports ===")
    print("1. All Devices Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        ck_all_devices_reports()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        ck_reports_menu()


def ck_all_devices_reports():
    # TODO: Implement the ck_all_devices query and save the results as an Excel file
    print("Generating CompanyKitchen All-Devices Report...")


# Legacy Reports sub-menu
def legacy_reports_menu():
    print("=== Legacy Reports ===")
    print("1. All Devices Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        legacy_all_devices_reports()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        legacy_reports_menu()


def legacy_all_devices_reports():
    # TODO: Implement the legacy_all_devices query and save the results as an Excel file
    print("Generating Legacy All-Devices Report...")


# Stockwell Reports sub-menu
def stockwell_reports_menu():
    print("=== Stockwell Reports ===")
    print("1. All Devices Reports")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == '1':
        stockwell_all_devices_reports()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        stockwell_reports_menu()


def stockwell_all_devices_reports():
    # TODO: Implement the stockwell_all_devices query and save the results as an Excel file
    print("Generating Stockwell All-Devices Report...")


# Entry point of the program
if __name__ == '__main__':
    main_menu()
