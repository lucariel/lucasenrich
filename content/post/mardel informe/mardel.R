#mardel 

library(tidyverse)
library(funModeling)
library(geojsonio)
source('get_density.R')
source('inpolygon.r')
library(rgdal)
library(raster)
dataset <- read_csv('mardel_dec_limpio.csv')
geodataset<- read_csv('mardel_geo.csv')
mardel1<-dataset%>%filter(Zona=="Mar del Plata")
#geomardel<-



ggplot(geodataset,aes(x=long, y=lat)) + 
  coord_equal() + 
  geom_polygon(colour="black", size=0.1, aes(group=group))


