import mysql.connector
import pandas as pd
import datetime
import os
from datetime import date
from credentials.credentials_sosdb import host, port, username, password, database


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
        query_endtime = datetime.datetime.now()
        query_elapsed = (query_endtime - query_starttime).total_seconds()
        print(f"Ending the query at {query_endtime.strftime('%Y-%m-%d @ %H:%M:%S')}, elapsed time: {int(query_elapsed)} seconds.")
        return df
    except mysql.connector.Error as error:
        print(f"Failed to execute the query: {error}")
        return None


# Function to check for duplicate filenames before starting a query
def check_for_duplicates(filename):
    today = date.today()
    formatted_date = today.strftime("_%Y-%m-%d")
    formatted_time = ''
    final_file_name = filename + formatted_date + formatted_time + ".xlsx"
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
            final_file_name = filename + formatted_date + formatted_time + ".xlsx"
            print("You are saving a second copy of this file, please note your specific file name.")
            return final_file_name
        elif choice == "3":
            print("Overwriting the original file (if that was the wrong choice it's too late; please panic).")
            print(f"Sending the filename '{final_file_name}'.")
            return final_file_name
        else:
            print("That wasn't one of your choices.")
            main_menu()
            # TODO: Figure out how to return the user to the menu they came from, not just the main menu.
    return final_file_name


# Function to save a DataFrame as an Excel file with UTF-8 encoding
def save_to_excel(df, file_name, sheet_name):
    try:
        # TODO: Auto-size the column widths, with column_dimensions[column_letter].width
        # TODO: Put the data into a named Excel Table so it can use local variables in formulas
        # TODO: Add a "Summary" sheet with a pivot table explaining the data
        df.to_excel(file_name, sheet_name=sheet_name, index=False)
        # TODO: Re-write this to use more choices than just .XLSX, this is a terrible way to do this!
        print(f"Data saved to '{file_name}' successfully!")
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
        adm_all_devices_reports_menu()
    elif choice == '2':
        adm_os_upgrade_reports_menu()
    elif choice == '3':
        adm_hardware_replacement_reports_menu()
    elif choice == '0':
        main_menu()
    else:
        print("Invalid choice. Please try again.")
        adm_v5_reports_menu()


# All Devices Reports Menu
def adm_all_devices_reports_menu():
    print("=== All Devices Reports ===")
    print("1. All-Devices Report - 365RM (This one is everything in ADM)")
    print("2. All-Devices Report - Canteen")
    print("3. All-Devices Report - CFGs")
    print("4. All-Devices Report - FiveStar")
    print("5. All-Devices Report - Canteen Canada")
    print("6. ")
    print("7. ")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == "1":
        adm_all_devices_report()
    elif choice == "2":
        adm_all_devices_report_canteen()
    elif choice == "3":
        adm_all_devices_report_cfgs()
    elif choice == "4":
        adm_all_devices_report_fivestar()
    elif choice == "5":
        adm_all_devices_report_canteencanada()
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


# ADM Hardware Replacement Reports Menu
def adm_hardware_replacement_reports_menu():
    # TODO: Implement the adm_os_upgrade_reports submenu
    print("=== ADM Hardware Replacement Reports ===")


# All Devices Reports
def adm_all_devices_report():
    print("Generating The All Devices Report...")
    # MySQL query
    query_file = "./queries/v5_All_Device_Report.sql"

    # Check to see whether the file already exists, first.
    filename = "./reports/ADM_All_Devices_Report"
    final_filename = check_for_duplicates(filename)

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
    save_to_excel(result_df, final_filename, sheetname)


# All Devices Report Canteen
def adm_all_devices_report_canteen():
    print("Generating All Devices Report for Canteen...")
    # MySQL query
    query_file = "./queries/v5_All_Device_Report_Canteen.sql"

    # Check to see whether the file already exists, first.
    filename = f"./reports/ADM_All_Devices_Report_Canteen"
    final_filename = check_for_duplicates(filename)

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
    sheetname = "All Canteen v5 Devices"
    save_to_excel(result_df, final_filename, sheetname)


# All Devices Report CFGs
def adm_all_devices_report_cfgs():
    print("Generating All Devices Report for CFGs...")
    # MySQL query
    # query_file = "./queries/v5_All_Device_Report_CFGs.sql"


# All Devices Report FiveStar
def adm_all_devices_report_fivestar():
    print("Generating All Devices Report for FiveStar...")
    # MySQL query
    # query_file = "./queries/v5_All_Device_Report_FiveStar.sql"


# All Devices Report CanteenCanada
def adm_all_devices_report_canteencanada():
    print("Generating All Devices Report for Canteen Canada...")
    # MySQL query
    query_file = "./queries/v5_All_Device_Report_CanteenCanada.sql"

    # Check to see whether the file already exists, first.
    filename = f"./reports/ADM_All_Devices_Report_CanteenCanada"
    final_filename = check_for_duplicates(filename)

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
    sheetname = "All Canteen v5 Devices"
    save_to_excel(result_df, final_filename, sheetname)


# OS Upgrade Reports
def adm_os_upgrade_reports():
    # TODO: Implement the adm_os_upgrade query and save the results as an Excel file
    print("Generating OS Upgrade Reports...")


# v5 KioskAge Report - All 365
def v5_kiosk_age_report_365rm():
    print("Generating All Devices Report for Canteen Canada...")
    # MySQL query
    query_file = "./queries/v5_KioskAge_Report.sql"

    # Check to see whether the file already exists, first.
    filename = f"./reports/v5_KioskAge_Report"
    final_filename = check_for_duplicates(filename)

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
    sheetname = "All VSH Kiosks"
    save_to_excel(result_df, final_filename, sheetname)


# v5 KioskAge Report - Canteen
def v5_kiosk_age_report_canteen():
    print("Generating All Devices Report for Canteen Canada...")
    # MySQL query
    query_file = "./queries/v5_KioskAge_Report_Canteen.sql"

    # Check to see whether the file already exists, first.
    filename = f"./reports/v5_KioskAge_Report-Canteen"
    final_filename = check_for_duplicates(filename)

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
    sheetname = "Canteen VSH Kiosks"
    save_to_excel(result_df, final_filename, sheetname)


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
