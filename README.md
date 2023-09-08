# Internet Speed Test in a Container


Check your internet bandwidth using the [Speedtest CLI](https://www.speedtest.net/apps/cli) from a Docker container. You can configure the tool to run periodically and save the results to an InfluxDB for visualization or long-term records.

For a full visualization and long term tracking, I recommend InfluxDB as a time-series database and Grafana as a dashboard engine. Both come in Docker containers, so the whole setup can be achieved through the compose file.

A compose file spins up three containers: 
1. speedtest - Perform speedtest and write results to file
2. grafana - Visualizations 
3. influxdb - storage

4. Python script reads the speedtest results file and writes to influxdb via influxdb_client module

## Configuration

Required env variables in the compose file are read form a .env file cotaining a list of variables needed by the 3 containers. The variable names are similar to the variable names in the compose file, only with variables rather than mappings.

Grafana has to run as the user owning the working directory
`user: "$USERID_VALUE"`

## Network

There are two networks. The logic behind their existence is, there are front-facing containers and there are those in the back-end.

![Image displaying the compartmentalized network structure](./img/Networks.png)



## Grafana and InfluxDB

![Screenshot of a Grafana Dashboard with upload and download speed values](./img/Grafana.png)


To configure Grafana, we need to add InfluxDB as a data source and create a dashboard with the upload and download values. You can find a demo dashboard configuration in the [/Grafana](/Grafana) folder.

> **Hint:** The data source uuid must be changed when using a new data source, even if it's an influxdb data source

> **Hint:** The speedtest outputs values as bytes per second. Make sure to divide all values by 125000 in your dashboard to get the Mbps values.

### Sample flux query
```
from(bucket: "speedtest")
  |> range(start: -60d)
  |> filter(fn: (r) => r["_measurement"] == "upload")
  |> filter(fn: (r) => r["_field"] == "value" and r["_value"] != "null")
  |> group(columns: ["host"])
  |> toFloat()
  |> map(fn: (r) => ({r with _value: r._value / 125000.00}))
  |> map(fn: (r) => ({ r with upload_speed: r._value }))
  |> keep(columns: ["_time","upload_speed"])
  
```
