# Routing-with-pgrouting
Queries to create the necessary datasets to calculate routes from A to B.  This process uses a dataset from the Netherlands that is updated every month (NWB)

## Introduction
pgRouting is a extension from postGIS and its purpose is the calculaton of routes in maps between two locations. With this extension it is posible to calculte:
* routes with restrictions
* routes between two locations based on distance or traveltime or any other attribute that the user wanst to use
## Data source 
For this example, the  "Nationaal Wegenbestand" ([NWB](https://www.nationaalwegenbestand.nl)) was used as a road network.
