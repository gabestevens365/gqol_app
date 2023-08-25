import os
import datetime
from datetime import date, datetime
import mysql.connector
import pyodbc
import pandas as pd
from openpyxl.utils import get_column_letter, column_index_from_string


# Function to connect to the ADM/v5 MySQL database
def connect_to_v5_database():
    from credentials.credentials_sosdb import adm_host, adm_port, adm_username, adm_password, adm_database
    try:
        mysql.connector.raise_on_warnings = True
        conn = mysql.connector.connect(
            host=adm_host,
            port=adm_port,
            user=adm_username,
            password=adm_password,
            database=adm_database)
        print(f"Connected to the ADM/v5 (MySQL) database successfully!")
        return conn
    except mysql.connector.Error as error:
        print(f"Failed to connect to the ADM/v5 (MySQL) database: {error}")
        return None


# Function to connect to the Legacy MsSQL database
def connect_to_leg_database():
    from credentials.credentials_sosdb import legacy_server, legacy_database, legacy_uid, legacy_pwd
    try:
        conn = pyodbc.connect(
            'DRIVER={SQL Server Native Client 11.0};'
            f'SERVER={legacy_server};'
            f'DATABASE={legacy_database};'
            f'UID={legacy_uid};'
            f'PWD={legacy_pwd};'
        )
        print(f"Connected to the Legacy (MsSQL) database successfully!")
        return conn
    except pyodbc.Error as error:
        print(f"Failed to connect to the Legacy (MsSQL) database: {error}")
        return None


# Function to connect to the Legacy MsSQL database
def connect_to_av_database():
    from credentials.credentials_sosdb import av_server, av_database, av_uid, av_pwd
    try:
        conn = pyodbc.connect(
            'DRIVER={SQL Server Native Client 11.0};'
            f'SERVER={av_server};'
            f'DATABASE={av_database};'
            f'UID={av_uid};'
            f'PWD={av_pwd};'
        )
        print(f"Connected to the AirVend (MsSQL) database successfully!")
        return conn
    except pyodbc.Error as error:
        print(f"Failed to connect to the AirVend (MsSQL) database: {error}")
        return None


# Function to test if an SSH tunnel is already established.
def check_ssh_tunnel(port):
    import psutil

    """Check if an SH tunnel is already established on the specified port."""
    established_connections = [conn for conn in psutil.net_connections() if conn.status == 'LISTEN']
    for conn in established_connections:
        if conn.laddr.port == port:
            return True
    return False


# Function to connect to the CompanyKitchen MySQL database
def connect_to_ck_database():
    from credentials.credentials_sosdb import ck_host, ck_port, ck_username, ck_password, ck_database

    try:
        # Check if the SSH tunnel is already active
        if not check_ssh_tunnel(3309):
            # Pause and prompt the user to connect to the SSH tunnel using PowerShell
            print("Before connecting to the CompanyKitchen (MySQL) database, \
please open PowerShell and start the SSH tunnel on port 3309.")
            print("Once the tunnel is active, press 'C' to continue or 'Q' to quit.")

            while True:
                user_input = input().lower()
                if user_input == 'c':
                    break
                elif user_input == 'q':
                    print("Quitting the program.")
                    return None
                else:
                    print("Invalid input. Press 'C' to continue or 'Q' to quit.")

        # Try connecting to the CK database
        mysql.connector.raise_on_warnings = True
        conn = mysql.connector.connect(
            host=ck_host,
            port=ck_port,
            user=ck_username,
            password=ck_password,
            database=ck_database
        )
        print(f"Connected to the CompanyKitchen (MySQL) database successfully!")
        return conn
    except mysql.connector.Error as error:
        print(f"Failed to connect to the CompanyKitchen (MySQL) database: {error}")
        return None


def connect_to_avanti_database():
    from credentials.credentials_sosdb import avanti_server, avanti_database, avanti_uid, avanti_pwd
    try:
        conn = pyodbc.connect(
            'DRIVER={ODBC Driver 17 for SQL Server};'
            f'SERVER={avanti_server};'
            f'DATABASE={avanti_database};'
            'Authentication=ActiveDirectoryPassword;'
            f'UID={avanti_uid};'
            f'PWD={avanti_pwd};'
        )
        print(f"Connected to the Avanti (MsSQL / Azure Synapse) database successfully!")
        return conn
    except pyodbc.Error as error:
        print(f"Failed to connect to the Avanti (MsSQL / Azure Synapse) database: {error}")
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
        cursor.close()

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
              f", elapsed time: {int(query_elapsed)} seconds.\n")
        return df
    except mysql.connector.Error as error:
        print(f"Failed to execute the {query_file} query: {error}\n")
        return None


# Function to format the worksheet
def format_worksheet(df, workbook, worksheet):
    format_gray = workbook.add_format({'pattern': 18, 'bg_color': '#CCCCCC'})
    format_red = workbook.add_format({'bg_color': '#FFB6C1'})
    format_orange = workbook.add_format({'bg_color': '#FFE4B5'})
    format_yellow = workbook.add_format({'bg_color': '#FFFFE0'})
    format_green = workbook.add_format({'bg_color': '#BDFCC9'})
    format_blue = workbook.add_format({'bg_color': '#BFEFFF'})
    format_purple = workbook.add_format({'bg_color': '#E6E6FA'})

    formats = [format_red, format_orange, format_yellow, format_green, format_blue, format_purple]

    info_cols = [get_column_letter(i+1) for i, col in enumerate(df.columns) if col.endswith(" Info")]
    last_col = get_column_letter(df.shape[1])

    # Apply formatting to the first column, and all the info_cols
    worksheet.set_column('A:A', None, format_gray)
    for col_letter in info_cols:
        worksheet.set_column(f'{col_letter}:{col_letter}', None, format_gray)

    # Apply additional formatting to the header row
    start_col = 'A'
    for i, info_col in enumerate(info_cols):
        end_col = get_column_letter(column_index_from_string(info_col) - 1)
        worksheet.conditional_format(f'{start_col}1:{end_col}1',
                                     {'type': 'no_blanks', 'format': formats[i % len(formats)]})
        start_col = info_col
    # Apply conditional formatting from the last " Info" column to the last column in the dataframe
    worksheet.conditional_format(f'{start_col}1:{last_col}1',
                                 {'type': 'no_blanks', 'format': formats[len(info_cols) % len(formats)]})


# Function to save a DataFrame as an Excel file
def save_to_excel(dataframes, file_name, sheet_names):
    print("Formatting and Saving. Please wait...")
    try:
        if len(dataframes) != len(sheet_names):
            raise ValueError("Number of dataframes and sheet names must be equal.")

        with pd.ExcelWriter(file_name, engine='xlsxwriter') as writer:
            for df, sheet_name in zip(dataframes, sheet_names):
                # Write to DataFrames to Excel
                df.to_excel(writer, sheet_name=sheet_name, index=False)
                workbook = writer.book
                worksheet = writer.sheets[sheet_name]

                # Freeze the top rows
                worksheet.freeze_panes(1, 0)

                # Auto-width columns
                for i, col in enumerate(df.columns):
                    column_len = max(df[col].astype(str).str.len().max(), len(col))
                    column_len = min(column_len, 59)  # limit column width to 59
                    worksheet.set_column(i, i, column_len)

                # Format specific sheets
                if sheet_name == 'All ADM-v5 Devices':
                    format_worksheet(df, workbook, worksheet)
                elif sheet_name == 'All Legacy Devices':
                    format_worksheet(df, workbook, worksheet)
                elif sheet_name == 'All AirVend Devices':
                    format_worksheet(df, workbook, worksheet)
                elif sheet_name == 'All CompanyKitchen Devices':
                    format_worksheet(df, workbook, worksheet)
                elif sheet_name == 'All Avanti Devices':
                    format_worksheet(df, workbook, worksheet)

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
    print("1. All Devices Report")
    print("2. Kiosk Age Report")
    print("0. Quit")

    choice = input("Enter your choice: ")

    if choice == '1':
        report_builder("./reports/AllDevices/", "All_Devices_Report")
    elif choice == '2':
        report_builder("./reports/KioskAge/", "KioskAge_Report")
    elif choice == '0':
        print("Exiting the program. Goodbye!")
        return
    else:
        print("Invalid choice. Please try again.")
        main_menu()


# The Report Builder
def report_builder(report_path, report_name):
    today = date.today()
    formatted_date = today.strftime("%Y-%m-%d")

    current_time = datetime.now()
    formatted_time = current_time.strftime("%H%M")

    report_date = formatted_date
    report_time = formatted_time
    report_ext = ".xlsx"
    final_file_name = report_path + report_name + "_" + report_date + "_" + report_time + report_ext

    print(f"{report_name} for {report_date} at {report_time}...")

    # Check to see whether the file already exists, first.
    report_exists = find_latest_report(report_path, report_name, report_date)
    if report_exists is None:
        print(f"Generating the first copy of {report_name} for {report_date}.")
        if report_name == "All_Devices_Report":
            alldevice_report_365rm_writer(final_file_name)
        elif report_name == "KioskAge_Report":
            kiosk_age_report_writer(final_file_name)
        else:
            print("There is a problem in the Report Name.")
            main_menu()
    else:
        print(f"{report_path}{report_exists} already exists!\n")
        choice = input("Do you want to generate a new copy? [Y/N]: ")
        choice = choice.upper()

        if choice == "Y":
            print(f"Generating a new copy of {report_name} for {report_date}.")
            if report_name == "All_Devices_Report":
                alldevice_report_365rm_writer(final_file_name)
            elif report_name == "KioskAge_Report":
                kiosk_age_report_writer(final_file_name)
            else:
                print("There is a problem in the Report Name.")
                main_menu()
        elif choice == "N":
            main_menu()
        else:
            print("Invalid Choice.")
            main_menu()


# AllDevices Report
def alldevice_report_365rm_writer(filename):
    # MySQL query
    query_file_v5 = "./queries/All-Devices_v5.sql"
    query_file_leg = "./queries/All-Devices_Legacy.sql"
    query_file_av = "./queries/All-Devices_AV.sql"
    query_file_ck = "./queries/All-Devices_CK.sql"
    query_file_avanti = "/queries/All-Devices_Avanti.sql"

    # Connect to the v5 database
    connection_v5 = connect_to_v5_database()
    if connection_v5 is None:
        return

    # Execute the v5 query
    result_v5_df = execute_query(connection_v5, query_file_v5)
    if result_v5_df is None:
        connection_v5.close()
        return

    # Connect to the Legacy database
    connection_leg = connect_to_leg_database()
    if connection_leg is None:
        return

    # Execute the Legacy query
    result_leg_df = execute_query(connection_leg, query_file_leg)
    if result_leg_df is None:
        connection_leg.close()
        return

    # Connect to the AV database
    connection_av = connect_to_av_database()
    if connection_av is None:
        return

    # Execute the AV query
    result_av_df = execute_query(connection_av, query_file_av)
    if result_av_df is None:
        connection_av.close()
        return

    # Connect to the CompanyKitchen database
    connection_ck = connect_to_ck_database()
    if connection_ck is None:
        return

    # Execute the CompanyKitchen query
    result_ck_df = execute_query(connection_ck, query_file_ck)
    print("Don't forget to disconnect the CK SSH tunnel on 3309.")
    if result_ck_df is None:
        connection_ck.close()
        return

    '''
    # Connect to the Avanti Data-Warehouse
    connection_avanti = connect_to_avanti_database()
    if connection_avanti is None:
        return

    # Execute the Avanti Query
    result_avanti_df = execute_query(connection_avanti, query_file_avanti)
    if result_avanti_df is None:
        connection_avanti.close()
        return
    '''

    # Save the result to an Excel file
    sheet1 = "All ADM-v5 Devices"
    sheet2 = "All Legacy Devices"
    sheet3 = "All AirVend Devices"
    sheet4 = "All CompanyKitchen Devices"
    # sheet5 = "All Avanti Devices"
    save_to_excel([result_v5_df, result_leg_df, result_av_df, result_ck_df],
                  filename, [sheet1, sheet2, sheet3, sheet4])


# KioskAge Report
def kiosk_age_report_writer(filename):
    # Get the SQL query
    query_file_v5 = "./queries/KioskAge_v5_Report.sql"
    query_file_rt = "./queries/KioskAge_RT_Report.sql"

    # Connect to the v5 / RT database
    connection_v5 = connect_to_v5_database()
    if connection_v5 is None:
        return

    # Execute the v5 query
    result_v5_df = execute_query(connection_v5, query_file_v5)
    if result_v5_df is None:
        connection_v5.close()
        return

    # Execute the ReadyTouch query
    result_rt_df = execute_query(connection_v5, query_file_rt)
    if result_rt_df is None:
        connection_v5.close()
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
#    result_rt_df.loc[result_rt_df]
    # Save the result to an Excel file
    sheet1 = "v5 KioskAges"
    sheet2 = "RT KioskAges"
    save_to_excel([result_v5_df, result_rt_df], filename, [sheet1, sheet2])


# Entry point of the program
if __name__ == '__main__':
    main_menu()
