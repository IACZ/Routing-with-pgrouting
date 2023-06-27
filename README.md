# Routing-with-pgrouting
Queries to create the necessary datasets to calculate routes from A to B ina postgres database with the extensions postGIS and pgRouting.  This process uses a dataset from the Netherlands that is updated every month (NWB)

## Introduction
pgRouting is a extension from postGIS and its purpose is the calculaton of routes in maps between two locations. With this extension it is posible to calculte:
* routes with restrictions
* routes between two locations based on distance or traveltime or any other attribute that the user wanst to use
## Data source 
For this example, the  "Nationaal Wegenbestand" ([NWB](https://www.nationaalwegenbestand.nl)) was used as a road network together with the [snelheden](https://downloads.rijkswaterstaatdata.nl/wkd/Maximum%20Snelheden/) dataset to retrieve the maximun speed on each segment of the road.  The NWB dataset can be retrieved from this [location](https://downloads.rijkswaterstaatdata.nl/nwb-wegen/geogegevens/shapefile/Nederland_totaal/) in shapefile format.This dataset can be uploaded to the postgres database with the help of QGIS or using the shp2pgsql.exec file located in the bin folder from the installation of Postgres \\PostgreSQL\15\bin. 
