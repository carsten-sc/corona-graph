#! /usr/bin/python3

from timeit import default_timer as timer
start = timer()

import time
import os.path
import sys
import csv
import datetime
from socket import socket
import argparse

# project specific, needs to be installed
import requests

VERSION = '1.0.2'


CARBON_SERVER = '127.0.0.1'
CARBON_PORT = 2003

LAST_COLUMN_FILE = '.corona-settings/lastcolumn'
LAST_COLUMN_FILE_LASTRUN = '.corona-settings/lastcolumn-lastrun'
# Name of the root metric in graphite
GRAPHITE_ROOT = 'corona.'

# first 4 columns containing country/region and geo location, the data starts in column 4.
HEAD_STARTPOS = 4

# we cannot send to much data at a time, so we do it in parts.
# A too big buffer and/or low delay, would result in shorter
# execution time, but also to data lost in carbon. These
# values work best for my experience and without data loss.
# Would you set the buffer to 500 and the delay to 0.2 then
# it's very likely, that you won't find your home country in graphite.
MESSAGE_BUFFER_SIZE = 150
MESSAGE_DELAY = 0.5

LOGFILE = 'logs/carbon-feeder.log'

CSV_CONFIRMEND = "time_series_covid19_confirmed_global.csv"
CSV_DEATHS = "time_series_covid19_deaths_global.csv"
CSV_RECOVERED = "time_series_covid19_recovered_global.csv"

CSV_URL = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/'
CSV_LOCALPATH = './'

parser = argparse.ArgumentParser(description='Downloads the daily cases file from CSSEGI and send them to carbon')
parser.add_argument('-v', '--version', action='version', version='%(prog)s ' +   VERSION)
args = parser.parse_args()

try:
    if args.version:
        print(VERSION)
        sys.exit
except:
    None

# download data files

def download_file(filename):
    print('DOWNLOADING:')
    try:
        print(filename)
        url = CSV_URL + filename
        r = requests.get(url)

        with open(CSV_LOCALPATH + filename, 'wb') as f:
            f.write(r.content)

        print('status: ' + str(r.status_code) + ' ' + str(r.headers['content-type']) + ' ' + str(r.encoding) +'\n')
    except:
        print('Error downloading file!')
        sys.exit(1)

last_index_before = -1

# Check the state of a last import.
if os.path.isfile(LAST_COLUMN_FILE):
    f = open(LAST_COLUMN_FILE,'r')
    last_index = int(f.readline())
    print('Last imported column: ' + str(last_index) + '\n')
    f.close
else:
    print('No import found, starting initial import \n')
    last_index = -1

last_index_before = last_index

print('Connecting to server ' + CARBON_SERVER + ' on port ' + str(CARBON_PORT) + '\n')
sock = socket()
try:
    sock.connect( (CARBON_SERVER,CARBON_PORT) )
except Exception:
    print("Couldn't connect to %(server)s on port %(port)d, is carbon-agent.py running?" % {
        'server': CARBON_SERVER, 'port': CARBON_PORT
    })
    sys.exit(1)

# Send the data to carbon server
def senddata(messages):
    if len(messages) > 0:
        print('Sending ' + str(len(messages)) + ' messages to server: ' + CARBON_SERVER)
        message = '\n'.join(messages) + '\n' #all lines must end in a newline
        try:
            sock.sendall(message.encode("ascii"))
        except:
            print('Error while sending Data, exiting with error!')
            sys.exit(1)
        messages.clear()
        time.sleep(MESSAGE_DELAY) 

def format_timestamp(timestamp):
    timestamp = datetime.datetime.strptime(timestamp, '%m/%d/%y %H:%M:%S')
    return timestamp

# Here's the main work, returns the last column number of csv file and
# the number of processed items in an array
def feed(csvfile, suffix):
    print('Reading: ' + csvfile)
    f = open(csvfile,'r')
    # read the headline of the csv file, as it contains the dates
    headline = str(f.readline())
    column_names = list(csv.reader([headline]))[0]
    # we store the data for the whole world in a 2 dimensional array
    global_array = []
    lastcolumn = len(column_names)
    messages = []
    # Re added confirmed messages, as it didn't work as expected
    confirmed_messages = []
    Lines = f.readlines()
    print(str(len(Lines)) + ' Lines found containing ' + str(lastcolumn - HEAD_STARTPOS) + ' data columns')
    items_counter = 0

    int_confirmed = 0

    global_daily = 0
    for l in Lines:
        row = list(csv.reader([l]))[0]
        country = row[1]
        if len(row[0].strip()) > 0:
            country = country + '.' +  row[0]
        country = country.strip()
        print('Importing: ' + country)
        country = country.replace(' ', '_')
        values_array = []

        global_daily = global_daily + int(row[HEAD_STARTPOS])
        for i in range(last_index + HEAD_STARTPOS + 1, lastcolumn):
            # Get the date from the head array and prepare it for carbon
            timestamp = column_names[i] + ' 00:00:00'
            timestamp = format_timestamp(timestamp)
            summe = 0
            int_confirmed = int(row[i])
            # to get the sum, we subtract the value with
            # the value in the column before to get
            # the daily cases.
            if i > HEAD_STARTPOS:
                summe = int_confirmed - int(row[i - 1])
            else:
                summe = int_confirmed
            
            # this happen's in some data, maybe because of data correction
            # but, for example -4 deaths per day makes no sense, so we set it to 0
            if summe < 0:
                summe = 0
            str_value = str(summe)
            values_array.append(summe)
            items_counter = items_counter + 2

            # Create the message for carbon and add it to the messages list  
            message = GRAPHITE_ROOT + country + suffix + ' ' + str_value + ' ' + str(timestamp.timestamp())
            messages.append(message)

            timestamp = column_names[i] + ' 00:00:00'
            timestamp = format_timestamp(timestamp)
            message = GRAPHITE_ROOT + country + suffix.replace('daily', 'confirmed') + ' ' + str(int_confirmed) + ' ' + str(timestamp.timestamp())
            confirmed_messages.append(message)

            if len(messages) >= MESSAGE_BUFFER_SIZE:
                senddata(messages)
            if len(confirmed_messages) >= MESSAGE_BUFFER_SIZE:
                senddata(confirmed_messages)

        global_array.append(values_array)
        
        if len(messages) >= MESSAGE_BUFFER_SIZE:
            senddata(messages)
        if len(confirmed_messages) >= MESSAGE_BUFFER_SIZE:
            senddata(confirmed_messages)

    # Send the rest
    senddata(messages)
    senddata(confirmed_messages)

    # Processing the global values
    print('\n')
    print('Processing global values.')
    
    # we need a step counter for getting
    # the position of the items in global_array[]
    # to be aligned with column_names[]
    pos = 0
    for i in range(last_index + HEAD_STARTPOS + 1, lastcolumn):
        global_cnt = 0
        timestamp = column_names[i] + ' 00:00:00'
        timestamp = format_timestamp(timestamp)
        
        for j in range(0, len(global_array)):
            # try block is only for debug purposes
            try:
                global_cnt = global_cnt + global_array[j][pos]
            except:
                print('lastcolumn: ' + str(lastcolumn)+ '/globalarray: ' + str(len(global_array)))
                print(str(j) + '/' + str(i - (HEAD_STARTPOS)))
                print(str(len(global_array[j])))
        message = GRAPHITE_ROOT + "_global"  + suffix + ' ' + str(global_cnt) + ' ' + str(timestamp.timestamp())
        messages.append(message)
        items_counter = items_counter +  2
        pos = pos + 1

        # calculate the number of daily confirmed
        global_confirmed = 0
        for l in Lines:
            row = list(csv.reader([l]))[0]
            global_confirmed = global_confirmed + int(row[i])

        message = GRAPHITE_ROOT + "_global"  + suffix.replace('daily', 'confirmed') + ' ' + str(global_confirmed) + ' ' + str(timestamp.timestamp())
        confirmed_messages.append(message)

        if len(messages) >= MESSAGE_BUFFER_SIZE:
            senddata(messages)
        if len(confirmed_messages) >= MESSAGE_BUFFER_SIZE:
            senddata(confirmed_messages)
        
    # Send the rest
    senddata(messages)
    senddata(confirmed_messages)

    print('\n')
    ret_arr = [lastcolumn, items_counter]
    return ret_arr
# END def feed()

download_file(CSV_CONFIRMEND)
download_file(CSV_DEATHS)
download_file(CSV_RECOVERED)

result_arr = feed(CSV_LOCALPATH + CSV_CONFIRMEND, '_daily_cases')
items_counter = result_arr[1]
result_arr = feed(CSV_LOCALPATH + CSV_DEATHS, '_daily_deaths')
items_counter = items_counter + result_arr[1]
result_arr = feed(CSV_LOCALPATH + CSV_RECOVERED, '_daily_revovered')
items_counter = items_counter + result_arr[1]

try:
    print('Saving last processd column (' + str(result_arr[0]) + ')')
    f2 = open(LAST_COLUMN_FILE,'w')
    f2.writelines(str(result_arr[0] - HEAD_STARTPOS -1))
    f2 = open(LAST_COLUMN_FILE_LASTRUN,'w')
    f2.writelines(str(last_index_before))
except:
    print('Error writing last processed column to ' + LAST_COLUMN_FILE)

end = timer()
try:
    f2 = open(LOGFILE,'a')
    ts = time.gmtime()
    ts = time.strftime("%x %X", ts)
    d_str = "%8.3f"% (end - start)
    print('Logging timestamp, items processed and duration in seconds to: ' + LOGFILE)
    logstr = ts + ' -- ' + str(items_counter) + ' -- ' + d_str.strip()
    print(logstr)
    f2.writelines(logstr)
except:
    print('Error writing to log file: ' + LOGFILE)

print('Done!')