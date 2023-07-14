from credentials.credentials_sosdb import host, port, username, password, database
import os
import datetime
from datetime import date, datetime
import mysql.connector
import pandas as pd


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
    print(f"Starting the {query_file} query at {query_starttime.strftime('%Y-%m-%d @ %H:%M:%S')}")
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
        print(f"Ending the {query_file} query at {query_endtime.strftime('%Y-%m-%d @ %H:%M:%S')}"
              f", elapsed time: {int(query_elapsed)} seconds.")
        return df
    except mysql.connector.Error as error:
        print(f"Failed to execute the {query_file} query: {error}")
        return None


# Function to save a DataFrame as an Excel file
def save_to_excel(dataframes, file_name, sheet_names):
    try:
        if len(dataframes) != len(sheet_names):
            raise ValueError("Number of dataframes and sheet names must be equal.")

        with pd.ExcelWriter(file_name, engine='xlsxwriter') as writer:
            for df, sheet_name in zip(dataframes, sheet_names):
                # Write to DataFrames to Excel
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
        sorted_files = sorted(matching_files, key=lambda f: os.path.getmtime(os.path.join(report_path, f)),
                              reverse=True)
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
        alldevices_report_365rm_builder()
    elif choice == "0":
        main_menu()
    else:
        print("Invalid Choice. Please try again.")
        adm_all_devices_reports_menu()


# ADM OS Upgrade Reports Menu
def adm_os_upgrade_reports_menu():
    # TODO: Implement the adm_os_upgrade_reports submenu
    print("=== ADM OS Upgrade Reports ===")
    print("1. Kiosk-Age Report")
    print("0. Return to Main Menu")

    choice = input("Enter your choice: ")

    if choice == "1":
        kiosk_age_report_builder()
    elif choice == "0":
        main_menu()
    else:
        print("Invalid Choice. Please try again.")
        adm_all_devices_reports_menu()


# The All-Devices Reports
def alldevices_report_365rm_builder():
    today = date.today()
    formatted_date = today.strftime("%Y-%m-%d")

    current_time = datetime.now()
    formatted_time = current_time.strftime("%H%M")

    report_path = "./reports/AllDevices/"
    report_name = "ADM_All_Devices_Report"
    report_date = formatted_date
    report_time = formatted_time
    report_ext = ".xlsx"
    final_file_name = report_path + report_name + "_" + report_date + "_" + report_time + report_ext

    print(f"{report_name} for {report_date} at {report_time}...")

    # Check to see whether the file already exists, first.
    report_exists = find_latest_report(report_path, report_name, report_date)
    if report_exists == None:
        print(f"Generating the first copy of {report_name} for {report_date}.")
        alldevice_report_365rm_v5_writer(final_file_name)
    else:
        print(f"{report_path}{report_exists} already exists!\n")
        choice = input("Do you want to generate a new copy? [Y/N]: ")
        choice = choice.upper()

        if choice == "Y":
            print(f"Generating a new copy of {report_name} for {report_date}.")
            alldevice_report_365rm_v5_writer(final_file_name)
        elif choice == "N":
            main_menu()
        else:
            print("Invalid Choice.")
            adm_all_devices_reports_menu()


# KioskAge Report - All 365
def kiosk_age_report_builder():
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
    final_file_name = report_path + report_name + "_" + report_date + "_" + report_time + report_ext

    # Announce the report we're starting to generate.
    print(f"{report_name} for {report_date} at {formatted_time}...")

    # Check to see whether the file already exists, first.
    report_exists = find_latest_report(report_path, report_name, report_date)
    if report_exists == None:
        print(f"Generating the first copy of {report_name} for {report_date}.")
        kiosk_age_report_writer(final_file_name)
    else:
        print(f"{report_path}{report_exists} already exists!\n")
        choice = input("Do you want to generate a new copy? [Y/N]: ")
        choice = choice.upper()

        if choice == "Y":
            print(f"Generating a new copy of {report_name} for {report_date}.")
            kiosk_age_report_writer(final_file_name)
        elif choice == "N":
            main_menu()
        else:
            print("Invalid Choice.")
            adm_os_upgrade_reports_menu()


# AllDevices Report - 365rm - v5 - Builder
def alldevice_report_365rm_v5_writer(filename):
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
    sheetname = "All ADM-v5 Devices"
    save_to_excel([result_df], filename, [sheetname])


# KioskAge Report - 365rm - Writer
def kiosk_age_report_writer(filename):
    # Get the SQL query
    query_file_v5 = "./queries/KioskAge_v5_Report.sql"
    query_file_rt = "./queries/KioskAge_RT_Report.sql"

    # Connect to the database
    connection = connect_to_database()
    if connection is None:
        return

    # Execute the v5 query
    result_v5_df = execute_query(connection, query_file_v5)
    if result_v5_df is None:
        connection.close()
        return

    # Execute the ReadyTouch query
    result_rt_df = execute_query(connection, query_file_rt)
    if result_rt_df is None:
        connection.close()
        return

    # Exclude specific CPU Products from the dataframe
    excluded_v5_cpu_products = [
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
    excluded_rt_cpu_products = [
        'S11G',
        'W8LPL',
        'EloPOS E3/S3/H3',
        'EloPOS E2/S2/H2',
        'To Be Filled By O.E.M.'
    ]
    result_v5_df = result_v5_df[~result_v5_df['CPU Product'].isin(excluded_v5_cpu_products)]
    result_rt_df = result_rt_df[~result_rt_df['CPU Product'].isin(excluded_rt_cpu_products)]

    # v5 Report -- Add the new columns "Sage Go-Live", "Device Age", and "Resolution Path"
    result_v5_df['Sage Go-Live'], result_v5_df['Device Age'], result_v5_df['Resolution Path'] = "", "", ""

    # Import the Sage Data and convert Excel dates to datetime objects, handling NaN values
    csv_file_path = "./queries/SageData_v5_golives.csv"
    sage_data_df = pd.read_csv(csv_file_path)

    # Convert dates to Excel date format
    sage_data_df['WentLiveOn'] = pd.to_datetime(sage_data_df['WentLiveOn'], format='%m/%d/%Y')
    excel_date_start = datetime(1899, 12, 30)  # Excel's serial date start
    sage_data_df['WentLiveOn'] = (sage_data_df['WentLiveOn'] - excel_date_start).dt.days

    # Merge the result_v5_df and sage_data_df on the 'Device Serial' and 'SerialNumber' columns
    merged_df = pd.merge(result_v5_df, sage_data_df[['SerialNumber', 'WentLiveOn']], how='left',
                         left_on='Device Serial', right_on='SerialNumber')

    # Update the result_v5_df 'Sage Go-Live' column
    result_v5_df.loc[result_v5_df['Device Serial'].isin(
        merged_df.loc[merged_df['WentLiveOn'].notnull(), 'Device Serial']), 'Sage Go-Live'] = merged_df.loc[
        merged_df['WentLiveOn'].notnull(), 'WentLiveOn'].values.tolist()

    # Calculate the Device Age based on Device Go-Live and Sage Go-Live
    result_v5_df['Device Age'] = None
    device_go_live = pd.to_datetime(result_v5_df['Device Go-Live'], format='%m/%d/%Y', errors='coerce')
    sage_go_live = pd.to_datetime(result_v5_df['Sage Go-Live'], format='%m/%d/%Y', errors='coerce')
    max_go_live_dates = pd.concat([device_go_live, sage_go_live], axis=1).max(axis=1)
    current_date = pd.Timestamp.now()
    result_v5_df['Device Age'] = (current_date - max_go_live_dates).dt.days // 365

    # ReadyTouch Report -- Add a new column "Path Forward" and fill it with relevant values.
    result_rt_df['Resolution Path'] = ""
    result_rt_df.loc[result_rt_df['OS Version'] == "Ubuntu 14.04", 'Resolution Path'] = "Upgrade (Ubuntu 14.04)"
    result_rt_df.loc[result_rt_df['CPU Product'].isnull() | (
            result_rt_df['CPU Product'] == ""), 'Resolution Path'] = "Investigate (Not in Dash)"
    result_rt_df.loc[result_rt_df['CPU Product'].str.contains("^Opti", na=False), 'Resolution Path'] = \
        "Replace (CPU Not Eligible)"
    result_rt_df.loc[result_rt_df['OS Version'] == "Ubuntu 20.04", 'Resolution Path'] = "Up-to-Date (Ubuntu 20.04)"

    # v5 Report -- Fill the "Resolution Path" column with relevant values
    four_months_ago = pd.Timestamp.now() - pd.DateOffset(months=4)
    result_v5_df['Resolution Path'] = "Investigate"
    result_v5_df.loc[result_v5_df['OS Version'].notnull() &
                     result_v5_df['OS Version'].str.startswith('Cent'), 'Resolution Path'] = "Upgrade (CentOS)"
    result_v5_df.loc[result_v5_df['OS Version'] == "Ubuntu 14.04", 'Resolution Path'] = "Upgrade (Ubuntu 14)"
    result_v5_df.loc[result_v5_df['Device Age'] >= 6, 'Resolution Path'] = "Replace (6+ years old)"
    mask = (result_v5_df['OS Version'].str.startswith('Cent')) & \
           (result_v5_df['CPU Product'].str.startswith('W10'))
    result_v5_df.loc[mask, 'Resolution Path'] = "Replace (CentOS on W10* cpu)"
    result_v5_df.loc[result_v5_df['Device Serial'].str.startswith('VSH310'), 'Resolution Path'] = "Replace (VSH310xxx)"
    mask = (result_v5_df['Device Serial'].str.startswith(('VSH1', 'VSH2')))
    result_v5_df.loc[mask, 'Resolution Path'] = "Replace (VSH1 / VSH2)"
    mask = (result_v5_df['Device Serial'].str.startswith('VSH3')) & \
           (result_v5_df['Location Name'].isin(['', 'Orphan Loc'])) & \
           (result_v5_df['Device Last Sync'] < four_months_ago)
    result_v5_df.loc[mask, 'Resolution Path'] = "Decommission (VSH3 unused orphan)"
    mask = (result_v5_df['Device Serial'].str.startswith(('VSH1', 'VSH2'))) & \
           (result_v5_df['Location Name'].isin(['', 'Orphan Loc']))
    result_v5_df.loc[mask, 'Resolution Path'] = "Decommission (VSH1 / VSH2 orphan)"
    result_v5_df.loc[result_v5_df['OS Version'] == "Ubuntu 20.04", 'Resolution Path'] = "Already Up-to-Date"

    # Extra Cleanup
    result_v5_df.loc[result_v5_df['Operation Name'] == "Canteen Canada", 'Operation Group'] = "Canteen Canada"
    result_rt_df.loc[result_rt_df]
    # Save the result to an Excel file
    sheet1 = "v5 KioskAges"
    sheet2 = "RT KioskAges"
    save_to_excel([result_v5_df, result_rt_df], filename, [sheet1, sheet2])


# Entry point of the program
if __name__ == '__main__':
    main_menu()
