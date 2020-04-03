##
library(tidyverse)
library(raster)
library(rgdal)
df = read_csv('mardel_trimestre_zon.csv')
geo = read_csv('mardel_geo.csv')

df6 = df %>% filter(zona==1)

ggplot()+geom_polygon(data=geo, aes(long,lat,group=group), fill = NA, color = 'black')+
  geom_point(data=df6, aes(Longitud, Latitud))


SP0<-readOGR('./SP/SP0/SP0.shp', verbose=FALSE) 
SP1<-readOGR('./SP/SP1/SP1.shp', verbose=FALSE)
SP2<-readOGR('./SP/SP2/SP2.shp', verbose=FALSE)
SP3<-readOGR('./SP/SP3/SP3.shp', verbose=FALSE)
SP4<-readOGR('./SP/SP4/SP4.shp', verbose=FALSE)
SP5<-readOGR('./SP/SP5/SP5.shp', verbose=FALSE)
SP6<-readOGR('./SP/SP6/SP6.shp', verbose=FALSE)

dta = df %>% filter(Tipo=="Departamento") %>% group_by(zona) %>% summarise(Prices=mean(Prices,na.rm=T))


mdp <- shapefile("./gral_pueyrredon/gral_pueyrredon.shp")


SP0$value = 0
SP0$Prices = dta$Prices[2]
SP0@data


SP1$value = 1
SP1$Prices = dta$Prices[3]


SP2$value = 2
SP2$Prices = dta$Prices[4]



SP3$value = 3
SP3$Prices = dta$Prices[5]




SP4$value = 4
SP4$Prices = dta$Prices[6]



SP5$value = 5
SP5$Prices = dta$Prices[7]




SP6$value = 6
SP6$Prices = dta$Prices[8]



SP = rbind(SP0,SP1,SP2,SP3,SP4,SP5,SP6)
#SP = rbind(SP,SP0,SP1,SP2,SP3,SP4,SP5,SP6)


SP@data=SP@data %>% dplyr::select(value,Prices)
SP0@data=SP0@data %>% dplyr::select(value,Prices)

plot(SP)

plot(mdp)
mdp@data$value=-1
mdp@data$Prices=dta$Prices[1]
mdp@data$clumps = -1
slot(mdp@polygons[[i]], "ID") = "7"
mdp@data=mdp@data %>% dplyr::select(value, Prices)
SPM = rbind(mdp,SP)



plot(SPM)
library(spdep)
w <- poly2nb(SPM, row.names=SPM$Id)
wm<- nb2mat(w, style='B', zero.policy = T)
ww<-nb2listw(w, style='B',zero.policy = T)
moran.test(SPM$Prices, ww, randomisation=T, zero.policy = T)
moran.mc(SPM$Prices, ww, nsim=9999,zero.policy = T)


##Hay autocorrelacion espacial entre densidad y precio, cuando se filtra por tipo de unidad. Si se mezclan,
#no la hay.
