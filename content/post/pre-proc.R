#Pre-procesamiento
library("zpreproc")
library(tidyverse)
library(funModeling)
library(gridExtra)
source('inpolygon.r')
#%>%latlong_na(geo)
limpieza_zprop<-function(df, tc, geo = NA, print = F, correct_latlong  = F){
  if(correct_latlong){
    df%>%limp_num_zprop()%>%print('Num extrac: OK')%>%add_id_zprop()%>%correct_dormitorio()%>%correct_ambientes()%>%
      correct_banos()%>%correct_cochera()%>%declara_expensas_dummy()%>%correct_metros()%>%correct_moneda(tc)%>%
      correct_antiguedad()%>%latlong_na(geo)
  }
  else{
    df%>%limp_num_zprop()%>%print('Num extrac: OK')%>%add_id_zprop()%>%correct_dormitorio()%>%correct_ambientes()%>%
      correct_banos()%>%correct_cochera()%>%declara_expensas_dummy()%>%correct_metros()%>%correct_moneda(tc)%>%
      correct_antiguedad()
  }
}

##Limp num
limp_num_zprop<-function(dataset){
  #dataset$Antiguedad<- gsub('hoy', '0',dataset$Antiguedad)
  #dataset$Antiguedad<- gsub('ayer', '-1',dataset$Antiguedad)
  #ataset$Antiguedad <- extract_numeric(dataset$Antiguedad)
  
  
  dataset$Metros<- gsub('ha', '0000',dataset$Metros)
  dataset$Metros_Cub<- gsub('ha', '0000',dataset$Metros_Cub)
  
  dataset$Metros <- extract_numeric(dataset$Metros)
  dataset$Metros_Cub <- extract_numeric(dataset$Metros_Cub)
  
  dataset$Tiempo<- gsub("Publicado hoy", '0',dataset$Tiempo)
  dataset$Tiempo<- gsub("Publicado desde ayer", '1',dataset$Tiempo)
  dataset$Tiempo <- extract_numeric(dataset$Tiempo)
  
  dataset$Antiguedad<- gsub("A estrenar", '0',dataset$Antiguedad)
  dataset$Antiguedad<- gsub("En construcción", '-1',dataset$Antiguedad)
  dataset$Antiguedad <- extract_numeric(dataset$Antiguedad)
  
  dataset$Cochera<-extract_numeric(dataset$Cochera)
  dataset$Prices<-extract_numeric(dataset$Prices)
  dataset$Longitud<-extract_numeric(dataset$Longitud)
  dataset$Latitud<-extract_numeric(dataset$Latitud)
  dataset
}
#### 
add_id_zprop<- function(df){
  df['id']=as.numeric(substr(df$WEBS, (nchar(df$WEBS)-12), (nchar(df$WEBS)-5)))
  df
}

######################## DATOS IMPLICITOS ##################################
correct_dormitorio<-function(df, print = T, plot = F){
  nadorm = df%>%filter(is.na(Dormitorio))
  if(plot){
    if(!all(is.na(nadorm$Ambientes))){
      pl = nadorm%>%ggplot()+geom_bar(aes(Ambientes), fill = 'red', alpha = 0.7)+scale_x_log10()
      print(pl)
    }
    else{
      print('Nada para el plot') 
    }
  }
  if(print){
    if(!all(is.na(nadorm$Ambientes))){
      print("Cantidad de registros con: Dormitorio[NA], Ambientes[no-NA] ~ (impica: cantidad de datos implicitos imputados)")
      print(length(nadorm$Ambientes))
      print("Summary de Ambientes si la variable Dormitorio es NA")
      print(summary(nadorm$Ambientes))
    }
    else{
      print("Al filtrar por cuales son los Dormitorio son NA, todos Ambientes es NA")
    }
    
  }
  
  df %>% mutate (
    Dormitorio = case_when(
      Ambientes == 1 & is.na(Dormitorio) ~ 0,
      Ambientes == 2 & is.na(Dormitorio) ~ 1,
      Ambientes == 3 & is.na(Dormitorio) ~ 2,
      Ambientes == 4 & is.na(Dormitorio) ~ 3,
      Ambientes == 5 & is.na(Dormitorio) ~ 4,
      Ambientes == 6 & is.na(Dormitorio) ~ 5,
      Ambientes == 7 & is.na(Dormitorio) ~ 6,
      TRUE ~ Dormitorio
    )
  )
  
}

correct_ambientes<-function(df, print = T, plot = F){
  naamb = df%>%filter(is.na(Ambientes))
  if(plot){
    if(!all(is.na(naamb$Dormitorio))){
      print(naamb%>%ggplot()+geom_bar(aes(Dormitorio), fill = 'red', alpha = 0.7))
    }
    else{
      print('Nada para el plot')
    }
  }
  if(print){
    if(!all(is.na(naamb$Dormitorio))){
      print("Cantidad de registros con: Ambientes[NA], Dormitorio[no-NA]~ (impica: cantidad de datos implicitos imputados)")
      print(length(naamb$Dormitorio))
      print("Summary de Dormitorio si la variable Ambientes es NA")
      print(summary(naamb$Dormitorio))
    }
    else{
      print("Al filtrar por cuales son los Ambientes NA, todos Dormitorio es NA")
    }
  }
  df %>% mutate (
    Ambientes = case_when(
      Dormitorio == 1 & is.na(Ambientes) ~ 2,
      Dormitorio == 2 & is.na(Ambientes) ~ 3,
      Dormitorio == 3 & is.na(Ambientes) ~ 4,
      Dormitorio == 4 & is.na(Ambientes) ~ 5,
      Dormitorio == 5 & is.na(Ambientes) ~ 6,
      Dormitorio == 6 & is.na(Ambientes) ~ 7,
      Dormitorio == 7 & is.na(Ambientes) ~ 8,
      
      
      TRUE ~ Ambientes
    )
  )
}

##Si tiene uno o dos ambientes, y baños == NA, tiene un baño
correct_banos <- function(df){
  dfbn = df%>%filter(is.na(Baños) & Ambientes %in% c(1,2,3))
  print(paste0("Baños corregidos: ", length(dfbn$Ambientes)))
  prop = round(length(dfbn$Cochera)/length(df$Prices)*100,2)
  print(paste0("Proporción: ", prop,'%'))
  
  df%>%mutate(
    Baños = case_when(
      Ambientes == 1 & is.na(Baños) ~ 1,
      Ambientes == 2 & is.na(Baños) ~ 1,
      Ambientes == 3 & is.na(Baños) ~ 1,
      T ~ Baños
    )
  )
}

correct_cochera<-function(df){
  df$Cochera = extract_numeric(df$Cochera)
  dfc = df%>%filter(is.na(Cochera))
  print(paste0("Cocheras corregidas:", length(dfc$Cochera)))
  prop = round(length(dfc$Cochera)/length(df$Prices)*100,2)
  print(paste0("Proporción: ", prop,'%'))
  df%>%mutate(
    Cochera = case_when(
      is.na(Cochera ) ~ 0,
      T ~ Cochera
    )
  )
}

######Se aplican y completan los datos implicitos
correct_datos_implicitos<-function(df){
  df%>%correct_cochera()%>%correct_ambientes()%>%correct_banos()%>%correct_dormitorio()
}


declara_expensas_dummy<-function(df){
  df%>%mutate(
    Declara_Expensas = case_when(
      is.na(Expensas) ~ 0,
      T ~ 1
    )
  )
}
check.rep.dig<-function(value){
  if(value%>%toString()%>%strsplit('')%>%unlist()%>%unique()%>%length()==1){
    T
  }
  else{
    F
  }
}
#check.rep.dig(999999)
## correct_usd
correct_moneda <- function(df,Tipo_de_cambio){
  ## Probar Prices = todos digitos iguales
  print('--------------------------Correccion de Moneda----------------------')
  t=sapply(df$Prices, check.rep.dig)
  df['rd'] = t
  cant_de_repdig = sum(df$rd)
  print(paste0("Cantidad de registros cuyo precio eran digitos repetidos: ",cant_de_repdig))
  prop_usd_corr = round(sum(df$rd)/length(df$Prices)*100,2)
  print(paste0("Proporción: ", prop_usd_corr,'%'))
  print('--------------------------------------------------------------------')
  #Reemplazo aquellos que complen con la condicion de ser todos digitos iguales por NA
  df$Prices[df$rd] = NA
  
  #Elimino la columna rd que me sirvio para chequear esto.
  df<-df%>%select(-rd)
  
  df$Prices[df$Prices<=1000] = NA
  
  df_usd=df%>%filter(Moneda == 'USD')
  
  df_usd=df_usd%>%mutate(
    p.x.m2 = Prices/Metros
  )
  ## Ver analisis de "los que dicen USD pero estan en ARS" a partir 
  ### Aca estoy usando el 1.5 IQR, se deberia hacer con el percentil 1% y 99% 
  outliers= df_usd$p.x.m2[df_usd$p.x.m2>20000 | df_usd$p.x.m2<250]
  #outliers = boxplot(df_usd$p.x.m2, plot=F)$out
  df_usd.out = df_usd[which(df_usd$p.x.m2 %in% outliers),]
  
  
  #Este tiene los outliers de boxplot filtrados 
  df_usd.1=df_usd[-which(df_usd$p.x.m2 %in% outliers),]
  print("Summary de: Publica USD -  esta USD - sin outliers")
  print("Precio por m2")
  print(summary(df_usd.1$p.x.m2))
  print("Precio del inmueble")
  print(summary(df_usd.1$Prices))
  print(paste0("Cantidad: ", length(df_usd.1$Prices)))
  prop_usd_corr = round(length(df_usd.1$Prices)/length(df$Prices)*100,2)
  print(paste0("Proporción: ", prop_usd_corr,'%'))
  #Y deja una distribucion de los precios por metro cuadrado  realista
  ##Datos irreales, usd
  print('--------------------------------------------------------------------')
  df_usd.i=anti_join(df_usd, df_usd.1, by = 'id')
  
  
  ##En teoria, se corrigen los outliers fuera de boxplot por NA para sacar
  
  ## Ahora habria que, con la distr de USD correctas, ver cuales,
  ## que dicen que estan en pesos, estan en pesos
  df_ars = df%>%filter(Moneda == 'ARS')%>%mutate(
    p.x.m2 = Prices/Metros
  )

  df_ars.usd= df_ars%>%filter(p.x.m2 <= max(df_usd.1$p.x.m2, na.rm = T) & 
                                p.x.m2 >= min(df_usd.1$p.x.m2, na.rm = T) & Prices<5000000 & Tipo != 'Terrenos' & Metros<200)
  
  
  print("Summary de: Publica ARS - Estan en USD")
  print("Precio por m2")
  print(summary(df_ars.usd$p.x.m2))
  print("Precio del inmueble")
  print(summary(df_ars.usd$Prices))
  print(paste0("Cantidad: ", length(df_ars.usd$Prices)))
  prop_usd_corr = round(length(df_ars.usd$Prices)/length(df$Prices)*100,2)
  print(paste0("Proporción: ", prop_usd_corr,'%'))
  print('--------------------------------------------------------------------')
  #Se verifican simil distr
  ## estos son los que, sospecho, estan efectivamente, en ARS
  df_ars=anti_join(df_ars, df_ars.usd, by = 'id')
  
  #Tipo_de_cambio = 55
  #Al revisar el histograma, veo que hay dos distribuciones, una de los que estan en ARS
  # y otra de datos irreales en pesos, en el limite inferior de los pesos, (que es donde hay mas)
  # si son irreales en pesos van a ser irreales en USD, divido por tc de $50 y vuelvo a extraer outliers
  todos.pm2.pesos=df_ars%>%mutate(
    Precios.m2_ars.to.usd = p.x.m2/ Tipo_de_cambio
  )
  #Y, me quedo con los que, transformados a usd, tienen sentido dentro de la distr de pm2 en usd 
  
  todos.pm2.pesos.t=todos.pm2.pesos%>%filter(Precios.m2_ars.to.usd <= max(df_usd.1$p.x.m2, na.rm = T) & Precios.m2_ars.to.usd >= min(df_usd.1$p.x.m2, na.rm = T))
  print("Summary (USD) de: Publica ARS - Estan en ARS")
  print("Precio por m2")
  print(summary(todos.pm2.pesos.t$Precios.m2_ars.to.usd))
  print("Precio del inmueble")
  print(summary(todos.pm2.pesos.t$Prices/Tipo_de_cambio))
  print(paste0("Cantidad: ", length(todos.pm2.pesos.t$Prices)))
  prop_usd_corr = round(length(todos.pm2.pesos.t$Prices)/length(df$Prices)*100,2)
  print(paste0("Proporción: ", prop_usd_corr,'%'))
  print('--------------------------------------------------------------------')
  ## El resto, digo, son datos irreales
  todos.pm2.pesos.i = anti_join(todos.pm2.pesos, todos.pm2.pesos.t, by = 'id')
  
  #entonces, me quedan.
  #Los datos que dicen dolares, que estan bien, sin datos irreales
  df_usd.1
  
  #Los datos que dicen dolres, pero que son irreales
  df_usd.i$Prices = NA
  df_usd.i$p.x.m2 = NA
  
  #hist(df_usd.i$p.x.m2)
  #Los datos que dicen ARS pero estan en usd
  df_ars.usd
  #Los datos que dicen ARS y son reales 
  todos.pm2.pesos.t$Prices = todos.pm2.pesos.t$Prices/Tipo_de_cambio
  todos.pm2.pesos.t= todos.pm2.pesos.t%>%select(-Precios.m2_ars.to.usd)
  #Los datos que dicen ARS y son irreales
  todos.pm2.pesos.i$Prices = NA
  todos.pm2.pesos.i= todos.pm2.pesos.i%>%select(-Precios.m2_ars.to.usd)
  
  tds = rbind(df_usd.1,df_usd.i,todos.pm2.pesos.t,todos.pm2.pesos.i,df_ars.usd)
  tds = tds%>%mutate(
    p.x.m2 = Prices/Metros
  )
  tds$Moneda = 'USD'
  tds
}



###
select_numeric<-function(df){
  df[unlist(lapply(df, is.numeric))]
}
#Para todos

random_na_ks<-function(df, col, alt = 'two.sided',metric = 'p', plot = F, plottype = 'ecdf'){
  na_df = df%>%filter(is.na(df[col]))
  no_na_df = df%>%filter(!is.na(df[col]))
  if(is.numeric(as_vector(df[col]))){
    colnames.check = df%>%select_numeric()%>%select(-col)%>%colnames()
  }else{
    colnames.check = df%>%select_numeric()%>%colnames()
  }
  df_ch  = data.frame(colnames.check)
  p = c()
  plots = list()
  for(i in 1:length(colnames.check)){
    
    x = as_vector(na_df[colnames.check[i]])
    #Hay que mejorar esto, porque cuando coinciden en todos NA, genera problemas en el test
    #quiza sea signo de que efectivamente esos NA estan relacionados
    y = as_vector(no_na_df[colnames.check[i]])
    if(length(x[is.na(x)])/length(x)>0.98 | length(y[is.na(y)])/length(y)>0.98){
      p = c(p,NA)
    }
    else{
      ks_p=ks.test(x,y, alternative = alt)
      
      ks_p_value = case_when(
        metric == 'p' ~ ks_p$p.value,
        metric == 'd' ~ ks_p$statistic,
        T~0
      )
      p = c(p,round(ks_p_value, digits = 2))
    }
    #print(p)
    if(plot){
      plots[[i]] = plot_compared_na(df,col   , colnames.check[i], type = plottype)
      #Crear un codigo para hacer un facet plot de cada variable
      
    }
  }
  #print(p)
  df_ch['p.values'] = p
  if(plot){
    n <- length(plots)
    nCol <- floor(sqrt(n))
    do.call("grid.arrange", c(plots, ncol=nCol))
  }
  df_ch
  
}



random_na_ks_all<-function(df, metric = 'p', alt = 'two.sided'){
  variables.na= df_status(df)%>%filter(q_na>100)
  tests.ks = data.frame()
  kss_colnames = c()
  for(i in 1:length(colnames(df))){
    if(colnames(df)[i] %in% variables.na$variable){
      kss_colnames = c(kss_colnames,colnames(df)[i])
      kss = random_na_ks(df, colnames(df)[i], alt = alt,metric = metric)
      rownames(kss)=kss$colnames.check
      kss=kss%>%select(p.values)
      kss = as_tibble(t(kss))
      tests.ks = bind_rows(tests.ks, kss)
      
    }
  }
  tests.ks['tested'] = kss_colnames
  tests.ks = tests.ks%>%select(tested, everything())
  tests.ks
}




plot_compared_na<-function(df, var, var.comp, type = 'ecdf'){
  df.no=df%>%filter(!is.na(get(var)))
  df.si=df%>%filter(is.na(get(var)))
  ##Ahora queda histograma, pero eventualmente se podria agregar la funcion de distr
  ##acumulada que es lo que usa el test
  if(type == 'histogram'){
    
    
    
    #bw = 2 * IQR(as_vector(df[var.comp]), na.rm = T) / length(as_vector(df[var.comp]))^(1/3)
    #Azul es la distribucion sin los NA, rojo es la distribucion de solo los NA
    ggplot()+geom_histogram(data = df.no, aes(x = get(var.comp), y = ..count../sum(..count..)), fill = 'blue', alpha = 0.6)+
      geom_histogram(data = df.si, aes(x = get(var.comp), y = ..count../sum(..count..)), fill = 'red', alpha = 0.6)+xlab(var.comp)+ylab('')+scale_x_log10()
    
  }
  else if(type == 'ecdf'){
    ggplot()+stat_ecdf(data = df.no, aes(get(var.comp)), color = 'blue')+
      stat_ecdf(data = df.si, aes(get(var.comp)),  color = 'red') +scale_x_log10()+xlab(var.comp)+ylab('')
  }
}  

random_na_ks.alts <- function(df,col, plot = F, metric = 'p'){
  two.sided = random_na_ks(df, col,metric = metric,alt = 'two.sided',plot = F)
  less = random_na_ks(df, col,metric = metric,alt = 'less',plot = F)
  if(plot){
    greater = random_na_ks(df, col,metric = metric,alt = 'greater',plot = T)
  }else{
    greater = random_na_ks(df, col,metric = metric,alt = 'greater',plot = F)
  }
  data.frame(two.sided$colnames.check,two.sided$p.values,less$p.values,greater$p.values)
}


##Correct Antiguedad
correct_antiguedad<-function(df, col){
  df$Antiguedad[df$Antiguedad>=1900 & df$Antiguedad<=2019 & !is.na(df$Antiguedad)] = 2019 - df$Antiguedad[df$Antiguedad>=1900 & df$Antiguedad<=2019 & !is.na(df$Antiguedad)]
  df$Antiguedad[df$Antiguedad>=200] = NA
  #m = max(df$Antiguedad[ntile(df$Antiguedad, 10000)/100>99.9& !is.na(df$Antiguedad)])
  
  #df$Antiguedad[ntile(df$Antiguedad, 10000)/100>99.9& !is.na(df$Antiguedad)] = NA
  df
}


correct_ambientes_i<-function(df){
  dfp = (df%>%mutate(
    ambientesxdormitorio = 
      case_when(Dormitorio!=0 ~ Ambientes/Dormitorio,
                T ~ 1)
  ))
  
  
  
  m = max(dfp$ambientesxdormitorio[ntile(dfp$ambientesxdormitorio, 10000)/100<99.99& !is.na(dfp$ambientesxdormitorio)])
  
  dfp%>%filter(ambientesxdormitorio == 'NA')
  dfp$ambientesxdormitorio[ntile(dfp$ambientesxdormitorio, 10000)/100>99.9& !is.na(dfp$ambientesxdormitorio)] = 'NA'
  dfp=dfp%>%mutate(
    Ambientes = case_when(
      ambientesxdormitorio == 'NA' ~ NA,
      T ~ Ambientes
    )
  )%>%select(-ambientesxdormitorio)
  dfp
}


correct_dormitorio_i<-function(df){
  dfp = (df%>%mutate(
    ambientesxdormitorio = 
      case_when(Ambientes!=0 ~ Dormitorio/Ambientes,
                T ~ 1)
  ))
  
  
  
  m = max(dfp$ambientesxdormitorio[ntile(dfp$ambientesxdormitorio, 10000)/100<99& !is.na(dfp$ambientesxdormitorio)])
  
  
  dfp$ambientesxdormitorio[ntile(dfp$ambientesxdormitorio, 10000)/100>99& !is.na(dfp$ambientesxdormitorio)] = m
  dfp=dfp%>%mutate(
    Dormitorio = case_when(
      ambientesxdormitorio == m ~ Ambientes*m,
      T ~ Dormitorio
    )
  )%>%select(-ambientesxdormitorio)
  dfp
}



latlong_na<-function(dataset, geodata){
  dataset$Latitud[is.na(dataset$Latitud)]=0
  dataset$Longitud[is.na(dataset$Longitud)]=0
  pb = txtProgressBar(min = 1, max = length(dataset$Longitud), initial = 1) 
  cat("Corrección de Latlong")
  for(i in 1:length(dataset$Longitud)){
    if(!inpolygon(dataset$Latitud[i], dataset$Longitud[i], geodata$lat, geodata$long, boundary = T)){
      dataset$Latitud[i] = NA
      dataset$Longitud[i] = NA
    }
    
    setTxtProgressBar(pb,i)
  }
  dt = dataset%>%filter(!is.na(Latitud)&!is.na(Longitud))
  print(paste0("Cantidad de registros geolocalizados:",length(dt$Latitud)))
  print(paste0("Proporcion de registros geolocalizados:",round(length(dt$Latitud)/length(dataset$Latitud)*100,2), "%"))
  
  dataset

}



#buscar si balcon

correct_metros<-function(df){
  df = df %>%mutate(
    p.x.m2 = Prices/Metros
  )
  df$Metros[df$Metros<=25] = NA
  df$Metros_Cub[df$Metros_Cub<=25] = NA
  df$Metros[df$Metros>=10000] = NA
  df$Metros_Cub[df$Metros_Cub>=10000] = NA
  
  df=df %>% mutate(
    c = Metros_Cub/Metros
  )
  
  
  
  #summary(df$Metros)
  #View(df%>%filter(c>=99.64103))
  #f =  df$c[ntile(df$c,10000)/100>99.98 & !is.na(df$c) & df$c<500]
  #nas = df$c[df$c>=500]
  #df$Metros_Cub[df$c %in% f]  = df$Metros_Cub[df$c %in% f]/100
  #df$Metros_Cub[df$c %in% nas]  = NA
  
  
  #e = 0
  for(i in 1:length(df$c)){
    if (!is.na(df$c[i])){
      if(df$c[i]>1){
        temp= df$Metros[i]
        df$Metros[i] = df$Metros_Cub[i]
        df$Metros_Cub[i] = temp
      }
    }
    
  }
  
  
  
  
  df= df%>%select(-c)
  df
  }


correct_outliers_1<-function(df){
  print('Corregido: Antigüedad, Ambientes, Dormitorios, Metros, Metros_Cub')
  df%>%correct_antiguedad()%>%correct_metros()
}
