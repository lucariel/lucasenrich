# Img Analysis
library(tidyverse)
library(funModeling)
library(umap)
library(purrr)
library(gridExtra)
library(plotly)
#Init variables
cols_used <- c('layer_top', 'layer_left', 'layer_width', 'layer_height')
cols_used_s<-c('layer_name','layer_top', 'layer_left', 'layer_width', 'layer_height')




#df<-data
norm_cols<-c('psd_name','layer_name','rel_area','orientation','layer_top_relative','layer_left_relative')
norm_cols_s<-c('rel_area','orientation','layer_top_relative','layer_left_relative')

normalize_geometric<-function(df){
  df['total_area']<-max(df['layer_height'])*max(df['layer_width'])
  df['rel_area']<-df['layer_height']*df['layer_width']/df['total_area']
  df['orientation']<-df['layer_height']/df['layer_width']
  df['layer_top_relative']<-df['layer_top']/max(df['layer_height'])
  df['layer_left_relative']<-df['layer_left']/max(df['layer_width'])
  df
}



###Spread file 
spread_file<-function(data, cols_used){
  #cols_used = c('layer_top', 'layer_left', 'layer_width', 'layer_height')
  cols_used_a = c('layer_name',cols_used)
  y=data[cols_used]
  h = data[cols_used_a]
  z=c(1,1,1,1)
  for(i in 1:nrow(y)) {
    z = cbind(z,y[i,])
  }
  z = z[1,-1] 
  
  newcols <- c()
  for (i in  h['layer_name']){
    newcols<-cbind(newcols,paste(i,cols_used[1], sep = '.'))
    newcols<-cbind(newcols,paste(i,cols_used[2], sep = '.'))
    newcols<-cbind(newcols,paste(i,cols_used[3], sep = '.'))
    newcols<-cbind(newcols,paste(i,cols_used[4], sep = '.'))
  }
  newcols2<-c()
  for(i in 1:nrow(newcols)) {
    for(j in 1:4){
      newcols2<-c(newcols2,newcols[i,j])
    }
  }
  colnames(z)<-newcols2
  n<-as_vector(data['psd_name'])
  #z['name']<-data['layer_name']
  z['psd_name']<-n[1]
  z
}
##Gather file
#gdf<-spread_file(df1, norm_cols_s)

#View(gdf)
#gather_file(gdf)
gather_file<-function(gdf){
  x<-strsplit(colnames(gdf), '\\.')
  
  layer_name=unique(unlist(map(x, 1)))
  original_cols=unique(unlist(map(x, 2)))
  gdf1<-data.frame(layer_name)
  gdf1[original_cols[1]]<-0
  gdf1[original_cols[2]]<-0
  gdf1[original_cols[3]]<-0
  gdf1[original_cols[4]]<-0
  
  
  
  rel_area<-c()
  orientation<-c()
  layer_top_relative<-c()
  layer_left_relative<-c()
  
  for(i in seq(from=1, to=length(gdf), by=4)){
    #  stuff, such as
    rel_area=c(rel_area,gdf[i])
    orientation=c(orientation,gdf[i+1])
    layer_top_relative = c(layer_top_relative,gdf[i+2])
    layer_left_relative = c(layer_left_relative,gdf[i+3])
  }
  
  gdf1['rel_area']=as_vector(unlist(rel_area))
  gdf1['orientation']=as_vector(unlist(orientation))
  gdf1['layer_top_relative']=as_vector(unlist(layer_top_relative))
  gdf1['layer_left_relative']=as_vector(unlist(layer_left_relative))
  gdf1}
##Spread all files
spread_data_norm <-c()
for (i in 1:length(list.files('./dataset'))){
  df =  read_csv(file.path('./dataset',list.files('./dataset')[i]))
  df = normalize_geometric(df)
  spread_file(df, norm_cols)
  spread_data_norm <- bind_rows(spread_data_norm, spread_file(df, norm_cols_s))
}
spread_data_norm[is.na(spread_data_norm)] <- 0
#Remove text columns, doesnt add relevant information
#spread_data_notext <- spread_data[, -grep("text", colnames(spread_data))]
#View(spread_data_notext)
spread_data <-c()
for (i in 1:length(list.files('./dataset'))){
  df =  read_csv(file.path('./dataset',list.files('./dataset')[i]))
  df = normalize_geometric(df)
  spread_file(df, norm_cols)
  spread_data <- bind_rows(spread_data, spread_file(df, cols_used))
}
spread_data[is.na(spread_data)] <- 0




##UMAP Transformation to the data

##Escalando
spread_data_umap_norm<-subset(spread_data_norm, select=-psd_name)
umap_data<- umap(spread_data_umap_norm)
umap_data_df <-as.data.frame.matrix(umap_data$layout) 
colnames(umap_data_df)<-c('x', 'y')
norm_plot<-ggplot()+geom_point(data = umap_data_df, aes(x , y))
norm_plot



library(plotly)
library(gapminder)

##Sin escalar

plot_banner<-function(idx_n_test){
  
  d=data.frame(x1=idx_n_test$layer_left, 
               x2=idx_n_test$layer_left+idx_n_test$layer_width, 
               y1=idx_n_test$layer_top,
               y2=idx_n_test$layer_top+idx_n_test$layer_height, 
               t = idx_n_test$layer_name)
  
  #d=data.frame(x1=c(1,3,1,5,4), x2=c(2,4,3,6,6), y1=c(1,1,4,1,3), y2=c(2,2,5,3,5), t=c('a','a','a','b','b'), r=c(1,2,3,4,5))
  
  ggplot() + 
    scale_x_continuous(name="x") + 
    scale_y_continuous(name="y") +
    geom_rect(data=d, mapping=aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2, fill = t), color="black", alpha=0.5) + 
    coord_fixed()+
    theme(legend.position="none")
}


plots <- function(files){
  
  ps=lapply(
  paste("./dataset/",sub(".psd", ".csv",files), sep = ''),
  function(x) 
  {
    d <- read_csv(x)
    y <- plot_banner(d)
    Sys.sleep(0.3)
    y
  }
)

grid.arrange(grobs = ps, ncol=2)
}


list.files('./dataset')
df <- read_csv('./dataset/out1.csv')
plot_banner(df)
logo_chico_cuadrado<-df%>%filter(layer_name == 'logo1')
plot_banner(rbind(fondo_color,logo_chico_cuadrado,logo_grande_cuadrado , logo_mediano_cuadrado))


logo_chico_cuadrado<-df%>%filter(layer_name == 'logo1')

logo_chico_cuadrado$layer_name<-'logo_chico_cuadrado'
logo_chico_cuadrado$layer_width<-logo_chico_cuadrado$layer_height

logo_mediano_cuadrado<-logo_chico_cuadrado

logo_mediano_cuadrado$layer_width<-logo_mediano_cuadrado$layer_width*2
logo_mediano_cuadrado$layer_height<-logo_mediano_cuadrado$layer_height*2

logo_grande_cuadrado<-logo_chico_cuadrado
logo_grande_cuadrado$layer_width<-logo_grande_cuadrado$layer_width*4
logo_grande_cuadrado$layer_height<-logo_grande_cuadrado$layer_height*4

logo_chico_rectangular<-df%>%filter(layer_name == 'logo1')

logo_chico_rectangular$layer_name<-'logo_chico_rectangular'
logo_chico_rectangular$layer_width<-logo_chico_rectangular$layer_height*3

logo_mediano_rectangular<-logo_chico_rectangular

logo_mediano_rectangular$layer_width<-logo_mediano_rectangular$layer_width*2
logo_mediano_rectangular$layer_height<-logo_mediano_rectangular$layer_height*2

logo_grande_rectangular<-logo_chico_rectangular
logo_grande_rectangular$layer_width<-logo_grande_rectangular$layer_width*4
logo_grande_rectangular$layer_height<-logo_grande_rectangular$layer_height*4



logo_chico_rectangular_fino<-df%>%filter(layer_name == 'logo1')

logo_chico_rectangular_fino$layer_name<-'logo_chico_rectangular_fino'
logo_chico_rectangular_fino$layer_width<-logo_chico_rectangular_fino$layer_height*20
logo_chico_rectangular_fino$layer_height<-logo_chico_rectangular_fino$layer_height/2
logo_mediano_rectangular<-logo_chico_rectangular

logo_chico_rectangular_fino$layer_width<-logo_chico_rectangular_fino$layer_width*2

logo_mediano_rectangular$layer_width<-logo_mediano_rectangular$layer_width*2
logo_mediano_rectangular$layer_height<-logo_mediano_rectangular$layer_height*2

logo_grande_rectangular<-logo_chico_rectangular
logo_grande_rectangular$layer_width<-logo_grande_rectangular$layer_width*4
logo_grande_rectangular$layer_height<-logo_grande_rectangular$layer_height*4


fondo_color$layer_name='fondo_color'
fondo1$layer_name = 'fondo1'
fondo1$layer_top = 440
fondo1$layer_height = 150


plot_banner(rbind(fondo_color,
fondo1,
logo_grande_cuadrado,
logo_chico_cuadrado,
logo_mediano_cuadrado,
logo_chico_rectangular,
logo_mediano_rectangular,
logo_grande_rectangular,logo_chico_rectangular_fino))

for(j in 1:20){
  estilo1<-fondo_color
  for(k in 1:4){
    a<-logo_chico_cuadrado
    b<-logo_grande_cuadrado
    a$layer_top<-runif(1, 0, 600)
    a$layer_left<-runif(1, 0, 300)
    
    b$layer_top<-runif(1, 0, 600)
    b$layer_left<-runif(1, 0, 300)
    
    estilo1<-rbind(estilo1, a)
    estilo1<-rbind(estilo1, b)
  }
  for(k in 1:2){
    a<-logo_mediano_cuadrado
    b<-logo_chico_rectangular
    a$layer_top<-runif(1, 0, 600)
    a$layer_left<-runif(1, 0, 300)
    
    b$layer_top<-runif(1, 0, 600)
    b$layer_left<-runif(1, 0, 300)
    
    estilo1<-rbind(estilo1, a)
    estilo1<-rbind(estilo1, b)
  }
  
  estilo1$psd_name<-paste('estilo1_artif_out_',j,'.csv', sep = '')
  write_csv(estilo1, paste('estilo1_artif_out_',j,'.csv', sep = ''))
  plot_banner(estilo1)
}


for(j in 1:20){
  estilo1<-fondo_color
  for(k in 1:4){
    a<-logo_chico_cuadrado
    b<-logo_grande_cuadrado
    a$layer_top<-runif(1, 0, 600)
    a$layer_left<-runif(1, 0, 300)
    
    b$layer_top<-runif(1, 0, 600)
    b$layer_left<-runif(1, 0, 300)
    
    estilo1<-rbind(estilo1, a)
    estilo1<-rbind(estilo1, b)
  }
  for(k in 1:3){
    a<-logo_mediano_cuadrado
    b<-logo_chico_rectangular
    a$layer_top<-runif(1, 0, 600)
    a$layer_left<-runif(1, 0, 300)
    
    b$layer_top<-runif(1, 0, 600)
    b$layer_left<-runif(1, 0, 300)
    
    estilo1<-rbind(estilo1, a)
    estilo1<-rbind(estilo1, b)
  }
  
  estilo1$psd_name<-paste('estilo2_artif_out_',j,'.csv', sep = '')
  write_csv(estilo1, paste('estilo2_artif_out_',j,'.csv', sep = ''))
  plot_banner(estilo1)
}


for(j in 1:20){
  estilo1<-fondo_color
  estilo1<-rbind(estilo1, fondo1)
  for(k in 1:2){
    a<-logo_chico_cuadrado
    b<-logo_grande_cuadrado
    a$layer_top<-runif(1, 0, 600)
    a$layer_left<-runif(1, 0, 300)
    
    b$layer_top<-runif(1, 0, 600)
    b$layer_left<-runif(1, 0, 300)
    
    estilo1<-rbind(estilo1, a)
    estilo1<-rbind(estilo1, b)
  }
  for(k in 1:3){
    a<-logo_mediano_cuadrado
    b<-logo_chico_rectangular
    a$layer_top<-runif(1, 0, 600)
    a$layer_left<-runif(1, 0, 300)
    
    b$layer_top<-runif(1, 0, 600)
    b$layer_left<-runif(1, 0, 300)
    
    estilo1<-rbind(estilo1, a)
    estilo1<-rbind(estilo1, b)
  }
  
  estilo1$psd_name<-paste('estilo3_artif_out_',j,'.csv', sep = '')
  write_csv(estilo1, paste('estilo3_artif_out_',j,'.csv', sep = ''))
  plot_banner(estilo1)
}


spread_data_norm <-c()
for (i in 1:length(list.files('.'))){
  df =  read_csv(file.path('.',list.files('.')[i]))
  df = normalize_geometric(df)
  spread_file(df, norm_cols)
  spread_data_norm <- bind_rows(spread_data_norm, spread_file(df, norm_cols_s))
}
spread_data_norm[is.na(spread_data_norm)] <- 0




spread_data <-c()
for (i in 1:length(list.files('.'))){
  df =  read_csv(file.path('.',list.files('.')[i]))
  df = normalize_geometric(df)
  spread_file(df, norm_cols)
  spread_data <- bind_rows(spread_data, spread_file(df, cols_used))
}
spread_data[is.na(spread_data)] <- 0





spread_data_umap<-subset(spread_data, select=-psd_name)
umap_data<- umap(spread_data_umap)
umap_data_df <-as.data.frame.matrix(umap_data$layout) 
colnames(umap_data_df)<-c('x', 'y')
norm_plot<-ggplot()+geom_point(data = umap_data_df, aes(x , y))
norm_plot


spread_data_umap_norm<-subset(spread_data_norm, select=-psd_name)
umap_data_norm<- umap(spread_data_umap_norm)
umap_data_df_norm <-as.data.frame.matrix(umap_data_norm$layout) 
colnames(umap_data_df_norm)<-c('x', 'y')
norm_plot<-ggplot()+geom_point(data = umap_data_df_norm, aes(x , y))
norm_plot

umap_data_df['version'] = 0
umap_data_df_norm['version'] = 1
df_an<-rbind(umap_data_df,umap_data_df_norm)
df_an%>%write_csv('df_an.csv')
colnames(df_an)<-c('x','y','version')

p <- df_an %>%
  plot_ly(
    x = ~x, 
    y = ~y,
    frame = ~version, 
    type = 'scatter',
    mode = 'markers'
  ) 
