# %%
#pip install influxdb_client
from influxdb_client import InfluxDBClient
from influxdb_client.client.exceptions import InfluxDBError
from influxdb_client.client.write_api import SYNCHRONOUS
from influxdb_client.domain.write_precision import WritePrecision


# %%
def main():
    #open file with speedtest results
    with open("/opt/speedtest/speedtest_results.txt","r", encoding="utf-8") as file:
        #Read line by line
        data = file.readlines()
    
    #list to store the individual dictionaries
    final_points_dict_list = []
    
    #process to split the line into (measurement, field, tag, time) begins here

    #Sample result
    '''
    download,host=00027ae5644d value=5388655 1694155140
    upload,host=00027ae5644d value=11281864 1694155140
    ping,host=00027ae5644d value=6.943 1694155140


    #Processing
    1. After split:
     len == 3

     i.e 
     download,host=00027ae5644d => To be further split
     value=5388655
     1694155140
    '''
    for line in data:
        if line != '\n':
            parts = line.split(" ")
            measurement, tags_str, fields_str, time_str = (parts[0].split(","))[0],(parts[0].split(","))[1], parts[1], parts[2]
    
            tags = {}
            tags_list = tags_str.split("=")
            tags[tags_list[0]] = tags_list[1]
    
            fields = {}
            fields_list = fields_str.split("=")
            fields[fields_list[0]] = fields_list[1]
    
            time = int(time_str)
    
            points_dict = {
                "measurement": measurement,
                "tags": tags,
                "fields": fields,
                "time": time
            }
    
            final_points_dict_list.append(points_dict)
            file.close()
    #reads credentials from the specific file
    with InfluxDBClient.from_config_file("/opt/speedtest/influxdb_conf_yamls_tomls/creds.toml","r",encoding="utf-8") as client:
        with client.write_api(write_options=SYNCHRONOUS) as write_api:
            try:
                write_api.write(bucket="speedtest", record=final_points_dict_list,write_precision=WritePrecision.S)
                print(f"Successfully wrote {len(data)} metrics")
                write_api.close()

            except InfluxDBError as e:
                print(e)
        

# %%

import sys
if __name__ == "__main__":
    sys.exit(main())

# with open("./speedtest_results.txt","r", encoding="utf-8") as file:
#        data = file.readlines()
# final_points_dict_list = []
# for line in data:
#     parts = line.split(" ")
#     measurement, tags_str, fields_str, time_str = (parts[0].split(","))[0],(parts[0].split(","))[1], parts[1], parts[2]

#     tags = {}
#     tags_list = tags_str.split("=")
#     tags[tags_list[0]] = tags_list[1]
    
#     fields = {}
#     fields_list = fields_str.split("=")
#     fields[fields_list[0]] = fields_list[1]

#     time = int(time_str)

#     points_dict = {
#         "measurement": measurement,
#         "tags": tags,
#         "fields": fields,
#         "time": time
#     }

#     final_points_dict_list.append(points_dict)

# for dictionary in final_points_dict_list:
#     print(dictionary)



