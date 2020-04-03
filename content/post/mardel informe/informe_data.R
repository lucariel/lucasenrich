library(tidyverse)
library(funModeling)
library(gridExtra)
library(leaflet)
library("KernSmooth")
library("raster")
library(data.table)
library(zpreproc)
#catl_nov = read_csv('ventas_catl_nov19.csv')
#colnames(catl_nov)[colnames(catl_nov)=="Banos"] ='Baños'
#colnames(catl_nov)[colnames(catl_nov)=="Codigo"] ='Moneda'
#catl_novl = limpieza_zprop(catl_nov,63)
#catl_novl = catl_novl %>% latlong_na(geodataset)
#mardel = catl_nov %>% filter(Zona == 'Mar del Plata')
#write_csv(mardel, 'mardel_limpio.csv')

mardel_oct = read_csv('octubre_mardel.csv')
mardel_nov = read_csv('mardel_limpio.csv')
mardel_dec = read_csv('mardel_dec_limpio.csv')

todos_bajaron = read_csv("tods_bajaron_data.csv")

##### MAPA ####
geodataset = read_csv('mardel_geo.csv')


mardel_summary = function(mardel){
  mardel %>% group_by(Tipo) %>%
    summarise(
      Cantidad = n(),
      Precio_M2 = mean(p.x.m2, na.rm = T),
      Tamaño = mean(Metros, na.rm = T),
      Precio = mean(Prices, na.rm = T)

      ) %>% arrange(-Cantidad) %>% head(10)


}


mardel_summary_median = function(mardel){
  mardel %>% group_by(Tipo) %>%
    summarise(
      Cantidad = n(),
      Precio_M2 = median(p.x.m2, na.rm = T),
      Tamaño = median(Metros, na.rm = T),
      Precio = median(Prices, na.rm = T)

    ) %>% arrange(-Cantidad) %>% head(10)


}
summ_oct_median = mardel_summary_median(mardel_oct)
summ_nov_median = mardel_summary_median(mardel_nov)
summ_dec_median = mardel_summary_median(mardel_dec)

summ_oct = mardel_oct %>% mutate(
  Tipo = case_when(
    Tipo == 'Departamento' ~ 'Departamento',
    Tipo =='Casa' ~'Casa',
    Tipo == 'PH'~'PH',
    T~'Otros'
  )
) %>% mardel_summary()
summ_nov = mardel_nov %>% mutate(
  Tipo = case_when(
    Tipo == 'Departamento' ~ 'Departamento',
    Tipo =='Casa' ~'Casa',
    Tipo == 'PH'~'PH',
    T~'Otros'
  )
) %>% mardel_summary()

summ_dec = mardel_dec %>%mutate(
  Tipo = case_when(
    Tipo == 'Departamento' ~ 'Departamento',
    Tipo =='Casa' ~'Casa',
    Tipo == 'PH'~'PH',
    T~'Otros'
  )
) %>% mardel_summary()

library(lubridate)
mardel_dec['Mes'] = ymd("2019-12-01")
mardel_nov['Mes'] = ymd("2019-11-01")
mardel_oct['Mes'] = ymd("2019-10-01")

trimestr =rbind(mardel_oct, mardel_nov %>%
                  dplyr::select(colnames(mardel_oct)),mardel_dec %>%
                  dplyr::select(colnames(mardel_oct))) %>% distinct(id, .keep_all = T)

trimestr_df = trimestr%>% group_by(Mes)%>% filter(p.x.m2 < quantile(p.x.m2, 0.95, na.rm = T)) %>%
  ungroup() %>%group_by(Mes) %>% summarise(
  media = median(p.x.m2, na.rm = T),
  perc25 = quantile(p.x.m2, 0.25, na.rm = T),
  perc75 = quantile(p.x.m2, 0.75, na.rm = T)
)



# no need for dodge
library(scales)

summ_trimestr = mardel_summary(trimestr)


summ_dec['Mes'] = ymd("2019-12-01")
summ_nov['Mes'] = ymd("2019-11-01")
summ_oct['Mes'] = ymd("2019-10-01")
summ_all = rbind(summ_oct,summ_nov,summ_dec)

#summ_all %>% filter(Cantidad>500) %>% ggplot(aes(x = Mes, y = Precio))+
#  geom_line(aes(color = Tipo, group = Tipo),size = 1)+labs(title="Precio del Inmueble")+
#  geom_point(aes(color = Tipo))+theme_bw()+scale_x_date(date_breaks = "1 month",labels = date_format("%m-%Y"))


p1<-summ_all %>% filter(Cantidad>500) %>% ggplot(aes(x = Mes, y = Tamaño))+
  geom_line(aes(color = Tipo, group = Tipo),size = 1)+labs(title="Tamaño del Inmueble")+
  geom_point(aes(color = Tipo))+theme_bw()+ theme(legend.position = "none")+
  scale_x_date(date_breaks = "1 month",labels = date_format("%b"))



p2<-summ_all %>% filter(Cantidad>500) %>% ggplot(aes(x = Mes, y = Precio))+
  geom_line(aes(color = Tipo, group = Tipo),size = 1)+labs(title="Precio del Inmueble")+
  geom_point(aes(color = Tipo))+theme_bw()+ theme(legend.position = "none")+
  scale_x_date(date_breaks = "1 month",labels = date_format("%b"))



p3<-summ_all %>% filter(Cantidad>500) %>% ggplot(aes(x = Mes, y = Precio_M2))+
  geom_line(aes(color = Tipo, group = Tipo),size = 1)+labs(title="Precio por M² del Inmueble")+
  geom_point(aes(color = Tipo))+theme_bw()+scale_x_date(date_breaks = "1 month",labels = date_format("%b"))


#grid.arrange(p1, p2,p3, nrow = 1)


library(ggpubr)

#ggarrange(p1, p2, p3, ncol=3, nrow=1, common.legend = TRUE, legend="bottom")






library(leaflet)



#create pal function for coloring the raster

## Redraw the map
#palRaster <- colorBin("Spectral",domain = KernelDensityRaster@data@values, na.color = "transparent")
#palRaster1 <- colorBin("Spectral",domain = 10^KernelDensityRaster@data@values, na.color = "transparent")

#leaflet() %>% addTiles() %>%
#  addLegend(pal = palRaster,
#            values = KernelDensityRaster@data@values,
#            title = "Densidad de Oferta Inmobiliaria") %>%
#  addRasterImage(KernelDensityRaster,
#                 colors = palRaster,
#                 opacity = .65)
#
gc()
## Leaflet map with raster
##### Bajaron ####
#
#bajarontotal = read_csv('bajaron_noviembre.csv',col_names = F)
#View(bajarontotal)
#bajarontotal[1800:2500,]
#links = c()
#bajamiento = c()
#for(i in 1:(length(bajarontotal$X1)-1)){
#  if(i%%2 == 0){
#    bajamiento = c(bajamiento,bajarontotal$X1[i] )
#  }else{
#    links = c(links, bajarontotal$X1[i])
#  }
#}

#df_baj = data.frame(
#  bajaron = bajamiento,
#  links = links
#)
#df_baj=df_baj[1:1524,]
#df_baj$bajaron = extract_numeric(df_baj$bajaron)
#df_baj %>% df_status()

#library(tidyverse)
#df_baj['id']=regmatches(df_baj$links, regexpr("[0-9]{8}", df_baj$links))
#bajaron_marel = mardel %>% filter(id %in% df_baj$id)
#df_baj$id = as.numeric(df_baj$id)
#bajaron_marel = right_join(df_baj,bajaron_marel)

library(leaflet.extras)
library(leaflet.providers)
library(viridisLite)
bajaron_mardel_nov = read_csv('bajaron_mardel_nov.csv')
bajaron_mardel_resto = todos_bajaron %>% filter(Zona == 'Mar del Plata')
#bajaron_mardel_nov$Bajo
colnames(bajaron_mardel_nov)[colnames(bajaron_mardel_nov)=='Baños']='Banos'
colnames(bajaron_mardel_nov)[colnames(bajaron_mardel_nov)=='bajaron']='Bajo'
bajaron_mardel_nov$Bajo=bajaron_mardel_nov$Bajo/100

colnames(bajaron_mardel_resto)[colnames(bajaron_mardel_resto)=='WEBS.x']='WEBS'
colnames(bajaron_mardel_resto)[colnames(bajaron_mardel_resto)=='Latitud']  = 'latitude'
colnames(bajaron_mardel_resto)[colnames(bajaron_mardel_resto)=='Longitud']  = 'longitude'
colnames(bajaron_mardel_nov)
bajaron_mardel_nov=bajaron_mardel_nov %>% dplyr::select(c('id','WEBS','Provincia','Tipo_Op','Tipo',
                                       'Zona','Direccion','latitude','longitude','Tiempo',
                                       'Cochera','Prices','Antiguedad','Metros','Metros_Cub','Ambientes','Dormitorio',
                                       'Banos','Declara_Expensas','p.x.m2','Bajo'))

bajaron_mardel_resto=bajaron_mardel_resto %>% dplyr::select(c('id','WEBS','Provincia','Tipo_Op','Tipo',
                                       'Zona','Direccion','latitude','longitude','Tiempo',
                                       'Cochera','Prices','Antiguedad','Metros','Metros_Cub','Ambientes','Dormitorio',
                                       'Banos','Declara_Expensas','p.x.m2','Bajo'))
bajaron_mardel_tds = rbind(bajaron_mardel_nov,bajaron_mardel_resto) %>% distinct(id, .keep_all = T)





bajaron_mardel_tds_c = bajaron_mardel_tds %>% group_by(Tipo) %>%
  summarise(
    Cantidad = n(),
    Precio_M2 = mean(p.x.m2, na.rm = T),
    Tamaño = mean(Metros, na.rm = T),
    Precio = mean(Prices, na.rm = T),
    Bajó = mean(Bajo, na.rm = T)

  ) %>% arrange(-Cantidad) %>% head(10)




#dif_table = (bajaron_mardel_nov_table_c[c('Precio_M2','Tamaño','Precio')]/mardel_table[c('Precio_M2','Tamaño','Precio')]-1)
#colnames(dif_table) = c('var Precio m2', 'var Tamaño','var Precio')
#bajaron_mardel_nov_table = cbind(bajaron_mardel_tds_c,dif_table)
#bajaron_mardel_nov_table1 = bajaron_mardel_nov_table %>% dplyr::select(Tipo,Cantidad,'Bajó' ,Precio_M2, "var Precio m2", Tamaño, 'var Tamaño', Precio, 'var Precio')


#bajaron_mardel_nov_table1$`var Precio m2`=as.character(percent(bajaron_mardel_nov_table1$`var Precio m2`))
#bajaron_mardel_nov_table1$`var Tamaño`=as.character(percent(bajaron_mardel_nov_table1$`var Tamaño`))
#bajaron_mardel_nov_table1$`var Precio`=as.character(percent(bajaron_mardel_nov_table1$`var Precio`))
#bajaron_mardel_nov_table1$Bajó=as.character(percent(bajaron_mardel_nov_table1$Bajó))

#bajaron_mardel_nov_table1 %>% mutate_if(is.numeric, round) #%>% write_csv('bajaron_table.csv')


##Pending
###
###Extractor de Amenities para Noviembre de la base para mostrarlas [ya está separado, falta el analisis]
###Analizar los emprendimientos

#unique(trimestr1$Mes)

mardel_dec['Mes'] = ymd("2019-12-01")
mardel_nov['Mes'] = ymd("2019-11-01")
mardel_oct['Mes'] = ymd("2019-10-01")
get_df_propplot = function(df, column){
  props = c(round((df[column]>250 & df[column]<=1000) %>% mean(na.rm = T)*100),round((df[column]>1000 & df[column]<=1700) %>% mean(na.rm = T)*100),round((df[column]>1700 & df[column]<=2500) %>% mean(na.rm = T)*100),round((df[column]>2500 & df[column]<=3500) %>% mean(na.rm = T)*100),round((df[column]>3500) %>% mean(na.rm = T)*100))
  cats = c("200 a 1000",'1000 a 1700','1700 a 2500','2500 a 3500','mas de 3500')
  data.frame(Rango_pm2=factor(cats,ordered = T, levels = c("200 a 1000",'1000 a 1700','1700 a 2500','2500 a 3500','mas de 3500')),Proporciones = props, Mes = unique(df$Mes), stringsAsFactors = T)
}
pm2_discr_sum=bind_rows(get_df_propplot(mardel_dec,'p.x.m2'),get_df_propplot(mardel_nov,'p.x.m2'),get_df_propplot(mardel_oct,'p.x.m2'))

pm2_discr_sum_plot = ggplot(pm2_discr_sum, aes(x = Mes, y = Proporciones, fill = Rango_pm2)) +
  geom_col() +
  geom_text(aes(label = paste0(Proporciones, "%")),
            position = position_stack(vjust = 0.5)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 16) +
  ylab("Percentage") +
  xlab(NULL)

## Con estos datos, hacer la proporcion de cada  TIPO
summ_oct['Proporcion'] = round(summ_oct['Cantidad']/sum(summ_oct['Cantidad'])*100)
summ_oct['Mes']='Octubre'

summ_nov['Proporcion'] = round(summ_nov['Cantidad']/sum(summ_nov['Cantidad'])*100)
summ_nov['Mes']='Noviembre'


summ_dec['Proporcion'] = round(summ_dec['Cantidad']/sum(summ_dec['Cantidad'])*100)
summ_dec['Mes']='Diciembre'

tipo_discr_sum = rbind(summ_oct, summ_nov,summ_dec)
tipo_plot = ggplot(tipo_discr_sum, aes(x = Mes, y = Proporcion, fill = Tipo)) +
  geom_col() +
  geom_text(aes(label = paste0(Proporcion, "%")),
            position = position_stack(vjust = 0.5)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 16) +
  ylab("Percentage") +
  xlab(NULL)


inm_data = mardel_dec %>% group_by(Inmobiliaria) %>% summarise(
  Cantidad.De.Publicaciones=n(),
  Proporcion = round(Cantidad.De.Publicaciones/nrow(mardel_dec)*100)
) %>% arrange(-Cantidad.De.Publicaciones)

library(arules)
intervals_inmo = discretize(inm_data$Cantidad.De.Publicaciones, breaks = 5, method ='cluster')
intervals_inmo=as_tibble(intervals_inmo) %>% group_by(value) %>%
  summarise(
    n = n(),
    Proporcion = round(n/length(intervals_inmo)*100)
  )
intervals_inmo$value = c("1 a 22","23 a 69", "70 a 141","142 a 276","276 a 419")
pie_chart_df_ex <- data.frame(Category = factor(intervals_inmo$value, ordered = T,levels = c("1 a 22","23 a 69", "70 a 141","142 a 276","276 a 419")), "freq" = intervals_inmo$Proporcion)
pie_inmobiliaria = ggplot(pie_chart_df_ex, aes (x="", y = freq, fill = Category)) +
  geom_col(position = 'stack', width = 1) +
  geom_text(aes(label = paste(round(freq / sum(freq) * 100, 1), "%"), x = 1.75),
            position = position_stack(vjust = 0.9)) +
  theme_classic() +
  theme(plot.title = element_text(hjust=0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  labs(fill = "Publicaciones",
       x = NULL,
       y = NULL,
       title = "Publicaciones por Inmobiliaria") +
  coord_polar("y")

## Zonas
#trimestr1 = trimestr
trimestr = trimestr %>% filter(!is.na(Latitud) & !is.na(Longitud))
mardel = trimestr
colnames(mardel)[colnames(mardel)=='Latitud'] = 'latitude'
colnames(mardel)[colnames(mardel)=='Longitud'] = 'longitude'
dat <- data.table(mardel)
setnames(dat, tolower(colnames(dat)))
setnames(dat, gsub(" ", "_", colnames(dat)))
dat <- dat[!is.na(longitude)]
## Create kernel density output
kde <- bkde2D(dat[, list(longitude, latitude)],
              bandwidth = c(.0045, .0068),
              gridsize = c(1000, 1000))
KernelDensityRaster <-
  raster(list(
    x = kde$x1 ,
    y = kde$x2 ,
    z = kde$fhat
  ))
KernelDensityRaster@data@values[which(KernelDensityRaster@data@values < 1)] <-
  NA
KernelDensityRaster@data@values=log(KernelDensityRaster@data@values,10)
require(rgdal)
library(raster)

r=KernelDensityRaster
mardel=trimestr
SP0<-readOGR('./SP/SP0/SP0.shp', verbose=FALSE) 
SP1<-readOGR('./SP/SP1/SP1.shp', verbose=FALSE)
SP2<-readOGR('./SP/SP2/SP2.shp', verbose=FALSE)
SP3<-readOGR('./SP/SP3/SP3.shp', verbose=FALSE)
SP4<-readOGR('./SP/SP4/SP4.shp', verbose=FALSE)
SP5<-readOGR('./SP/SP5/SP5.shp', verbose=FALSE)
SP6<-readOGR('./SP/SP6/SP6.shp', verbose=FALSE)
?readOGR

#SP1 <- rasterToPolygons(clump(r >= 0.5 & r <1 ), dissolve = TRUE)
#SP2 <- rasterToPolygons(clump(r >= 1  & r <1.5 ), dissolve = TRUE)
#SP3 <- rasterToPolygons(clump(r >= 1.5  & r <2 ), dissolve = TRUE)
#SP4 <- rasterToPolygons(clump(r >= 2  & r <2.5 ), dissolve = TRUE)
#SP5 <- rasterToPolygons(clump(r >= 2.5  & r <3 ), dissolve = TRUE)
#SP6 <- rasterToPolygons(clump(r >= 3  & r <=3.5 ), dissolve = TRUE)

z0_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP0), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 0')

z1_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP1), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 1')

z2_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP2), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 2')

z3_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP3), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 3')

z4_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP4), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 4')

z5_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP5), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 5')


z6_plot=ggplot(data = geodataset)+geom_polygon(aes(x=long, y = lat), fill = NA, colour = 'black')+
  geom_polygon(data = fortify(SP6), aes(x=long, y = lat, group = group), fill=NA, colour = "blue")+theme_void()+ggtitle('Zona 6')


zonas_plot = ggarrange(z0_plot, z1_plot, z2_plot,z3_plot,z4_plot,z5_plot,z6_plot, ncol=3, nrow=3)

#
#trimestr['zona'] = z1$zona
#trimestr %>% write_csv('mardel_trimestre_zon.csv')
trimestr=read_csv('mardel_trimestre_zon.csv')

z0tipo=trimestr %>% filter(zona==0) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3) %>% mutate(Prop=round(n/sum(n)*100), Zona = 0)
z0tipo$Prop[1] =z0tipo$Prop[1] +1


z1tipo=trimestr %>% filter(zona==1) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3)%>% mutate(Prop=round(n/sum(n)*100), Zona = 1)

z2tipo=trimestr %>% filter(zona==2) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3)%>% mutate(Prop=round(n/sum(n)*100), Zona = 2)
z3tipo=trimestr %>% filter(zona==3) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3)%>% mutate(Prop=round(n/sum(n)*100), Zona = 3)


z4tipo=trimestr %>% filter(zona==4) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3)%>% mutate(Prop=round(n/sum(n)*100), Zona = 4)
z4tipo$Prop[1] =z4tipo$Prop[1] +1

z5tipo=trimestr %>% filter(zona==5) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3)%>% mutate(Prop=round(n/sum(n)*100), Zona = 5)
z5tipo$Prop[1] =z5tipo$Prop[1] +1


z6tipo=trimestr %>% filter(zona==6) %>% group_by(Tipo) %>% summarise(n=n()) %>% arrange(-n) %>% head(3)%>% mutate(Prop=round(n/sum(n)*100), Zona = 6)
z6tipo$Prop[1] =z6tipo$Prop[1] -1




ztipo = rbind(z0tipo,z1tipo,z2tipo,z3tipo,z4tipo,z5tipo,z6tipo)

#ggplot(data = geodataset)+geom_polygon(aes(x = long, y = lat))+
#  geom_point(data = trimestr, aes(x=Longitud, y = Latitud, color = zona))+theme_void()

pm2_zona_plot = trimestr %>% group_by(zona) %>% summarise(
  n = n(),
  prices = mean(Prices,na.rm = T),
  pm2 = mean(p.x.m2,na.rm = T),
  Tamaño = mean(Metros,na.rm = T)
) %>% filter(zona!=-1) %>% ggplot(aes(x=zona, y = pm2, fill = factor(zona)))+geom_bar(stat="identity") +
  geom_text(aes(label = paste0("U$",round(pm2))),
            position = position_stack(vjust = 0.7)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 16) +
  ylab("Precio por Metro Cuadrado") +
  xlab(NULL)+ scale_y_discrete()+scale_x_continuous("Zona", labels = ztipo$Zona, breaks = ztipo$Zona)+
  theme(legend.position = "none")

Tamaño_zona_plot = trimestr %>% group_by(zona) %>% summarise(
  n = n(),
  prices = mean(Prices,na.rm = T),
  Tamaño = mean(p.x.m2,na.rm = T),
  Tamaño = mean(Metros,na.rm = T)
) %>% filter(zona!=-1) %>% ggplot(aes(x=zona, y = Tamaño, fill = factor(zona)))+geom_bar(stat="identity") +
  geom_text(aes(label = paste0(round(Tamaño),"m²")),
            position = position_stack(vjust = 0.7)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 16) +
  ylab("Tamaño") +
  xlab(NULL)+ scale_y_discrete()+scale_x_continuous("Zona", labels = ztipo$Zona, breaks = ztipo$Zona)+
  theme(legend.position = "none")

trimestr_sdsd = trimestr %>% group_by(zona) %>% summarise(
  n = n(),
  prices = mean(Prices,na.rm = T)/1000,
  sds = sd(Prices,na.rm = T)/1000
  
)
trimestr_sdsd$sds[8]/trimestr_sdsd$sds[2]-1

prices_zona_plot = trimestr %>% group_by(zona) %>% summarise(
  n = n(),
  prices = mean(Prices,na.rm = T)/1000
  #prices = mean(p.x.m2,na.rm = T),
  #prices = mean(Metros,na.rm = T)
) %>% filter(zona!=-1) %>% ggplot(aes(x=zona, y = prices, fill = factor(zona)))+geom_bar(stat="identity") +
  geom_text(aes(label = paste0("U$",round(prices))),
            position = position_stack(vjust = 0.7)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 16) +
  ylab("Precio en Miles de U$") +
  xlab(NULL)+ scale_y_discrete()+scale_x_continuous("Zona", labels = ztipo$Zona, breaks = ztipo$Zona)+
  theme(legend.position = "none")



zona_tipo_plot = ggplot(ztipo, aes(x = Zona, y = Prop, fill = Tipo)) +
  geom_col() +
  geom_text(aes(label = paste0(Prop, "%")),
            position = position_stack(vjust = 0.5)) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 16) +
  ylab(NULL) +
  xlab(NULL)+ scale_y_discrete()+scale_x_continuous("Zona", labels = ztipo$Zona, breaks = ztipo$Zona)

## Prop de unidades en zona y m2 ofrecidos
of.x.z = trimestr %>% filter(zona!=-1)%>% group_by(zona) %>% summarise(
  n = n(),
  Prop = round(n/nrow(trimestr)*100),
  Metros = sum(Metros,na.rm = T),
  Prop_Metros = round(Metros/sum(trimestr$Metros,na.rm=T)*100))



pie_chart_df_ex <- data.frame(Category = factor(of.x.z$zona, ordered = T,levels = c("0","1", "2","3","4","5","6")), "freq" = of.x.z$Prop)
pie_zonas_publicaciones = ggplot(pie_chart_df_ex, aes (x="", y = freq, fill = Category)) +
  geom_col(position = 'stack', width = 1) +
  geom_text(aes(label = paste(round(freq / sum(freq) * 100, 1), "%"), x = 1.75),
            position = position_stack(vjust = 0.9)) +
  theme_classic() +
  theme(plot.title = element_text(hjust=0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  labs(fill = "Publicaciones",
       x = NULL,
       y = NULL,
       title = "Publicaciones por Zona") +
  coord_polar("y")



pie_chart_df_ex <- data.frame(Category = factor(of.x.z$zona, ordered = T,levels = c("0","1", "2","3","4","5","6")), "freq" = of.x.z$Prop_Metros)
pie_zonas_m2_d.total = ggplot(pie_chart_df_ex, aes (x="", y = freq, fill = Category)) +
  geom_col(position = 'stack', width = 1) +
  geom_text(aes(label = paste(round(freq / sum(freq) * 100, 1), "%"), x = 1.75),
            position = position_stack(vjust = 0.9)) +
  theme_classic() +
  theme(plot.title = element_text(hjust=0.5),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank()) +
  labs(fill = "Publicaciones",
       x = NULL,
       y = NULL,
       title = "Metros por Zona") +
  coord_polar("y")


zonas_plot2 = ggarrange(pie_zonas_m2_d.total, pie_zonas_publicaciones,ncol=2, nrow=1,common.legend = TRUE,
                        legend="bottom")

###

#Pasar datos a raster


library(leaflet)
library("KernSmooth")
library("raster")
library(data.table)
library(raster)
library(rgeos)
mardel = trimestr

#r = KernelDensityRaster


#mardelat = mean(mardel$Latitud, na.rm = T)
#mardelong = mean(mardel$Longitud, na.rm = T)
colnames(mardel)[colnames(mardel)=='Latitud']  = 'latitude'
colnames(mardel)[colnames(mardel)=='Longitud']  = 'longitude'

mardel=mardel %>% filter(!is.na(p.x.m2))
dat <- data.table(mardel)
setnames(dat, tolower(colnames(dat)))
setnames(dat, gsub(" ", "_", colnames(dat)))
dat <- dat[!is.na(longitude)]
dat<-dat[, list(longitude, latitude, p.x.m2)]
colnames(dat)=c('x','y','z')



s100 <- dat
colnames(s100) <- c('X', 'Y', 'Z')

library(raster)
# set up an 'empty' raster, here via an extent object derived from your data
names(s100) = c('x','y','z')
e <- extent(dat[,1:2])

r <- raster(e, ncol=100, nrow=100)
# or r <- raster(xmn=, xmx=,  ...
crs(r) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

# you need to provide a function 'fun' for when there are multiple points per cell
x <- rasterize(s100[, 1:2], r, s100[,3], fun=mean)
r2 <- disaggregate(x,5, method="bilinear")

palRaster <- colorBin("Spectral", bins = 7, domain = r2@data@values, na.color = "transparent")

zona_precio_heatmap = leaflet() %>%
  setView(lng = mean(mardel$longitude,na.rm = T), lat = mean(mardel$latitude,na.rm = T), zoom = 10)%>%
  addTiles() %>%
  addRasterImage(r2, colors = palRaster, opacity = 0.7) %>%
  addLegend(pal = palRaster,
            values = r2@data@values,
            title = "Precio por metro cuadrado")

SP0p<-readOGR('./SPp/SP0/SP0.shp', verbose=FALSE)
SP1p<-readOGR('./SPp/SP1/SP1.shp', verbose=FALSE)
SP2p<-readOGR('./SPp/SP2/SP2.shp', verbose=FALSE)
SP3p<-readOGR('./SPp/SP3/SP3.shp', verbose=FALSE)
SP4p<-readOGR('./SPp/SP4/SP4.shp', verbose=FALSE)
SP5p<-readOGR('./SPp/SP5/SP5.shp', verbose=FALSE)
SP6p<-readOGR('./SPp/SP6/SP6.shp', verbose=FALSE)
SP7p<-readOGR('./SPp/SP7/SP7.shp', verbose=FALSE)


trimestr=mardel


check_if_in_z = function(lat, long,SP){
  zlist = c()
  point <- tibble(lon=long, lat=lat)


  sp2   <- SpatialPoints(point,proj4string=CRS(proj4string(SP)))
  gContains(SP,sp2)

}
#z1 = data.frame(id = numeric(), zona = numeric())
#for(i in 1:nrow(trimestr)){
#  z = case_when(
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP0) ~ 0,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP1) ~ 1,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP2) ~ 2,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP3) ~ 3,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP4) ~ 4,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP5) ~ 5,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP6) ~ 6,
#    check_if_in_z(trimestr$latitude[i],trimestr$longitude[i], SP7) ~ 7,
#    T ~ -1
#  )
#  z1[i,'id'] = trimestr$id[i]
#  z1[i,'zona'] = z
#
#  print(i/nrow(trimestr))
#}

#Con los ammenities, amenities mas comunes en cada
#unique(mardel$zona_precio)
#mardel['zona_precio'] = z1$zona
mardel = read_csv('mardel_trim_zprecio.csv')

zona_lables = factor(c('Menor a USD 500','USD 500 a USD 1000','USD 1000 a USD 1500','USD 1500 a USD 2000',
                'USD 2000 a USD 2500','USD 2500 a USD 3000','USD 3000 a USD 3500', 'Más de 3500'), ordered = T)

mardel=mardel %>% filter(zona_precio>=0) %>% mutate(
  zona_precio=case_when(
    zona_precio == 0 ~ zona_lables[1],
    zona_precio == 1 ~ zona_lables[2],
    zona_precio == 2 ~ zona_lables[3],
    zona_precio == 3 ~ zona_lables[4],
    zona_precio == 4 ~ zona_lables[5],
    zona_precio == 5 ~ zona_lables[6],
    zona_precio == 5 ~ zona_lables[7],
    T~zona_lables[8]
  )
)
zpcio_df_p = mardel %>% group_by(zona_precio) %>% summarise(cantidad=n())
zpcio_df_p$zona_precio=factor(zpcio_df_p$zona_precio, levels = zona_lables)

zpcio_df_plot = zpcio_df_p%>%
  ggplot(aes(x=zona_precio, y=cantidad)) +
  geom_bar(stat="identity", fill="steelblue")+
  geom_text(aes(label=cantidad), vjust=-0.5, color="black", size=3.5)+
  theme_minimal() +xlab("")+
  scale_x_discrete(labels = unique(mardel$zona_precio), breaks = unique(mardel$zona_precio))+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



