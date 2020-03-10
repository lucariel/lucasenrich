# Img Analysis
library(tidyverse)
library(funModeling)
library(umap)
library(purrr)
library(dbscan)
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
  file = list.files('./dataset')[i]
  if(str_sub(file, start= -3) == 'csv'){
    df =  read_csv(file.path('./dataset',file))
    df = normalize_geometric(df)
    spread_file(df, norm_cols)
    spread_data_norm <- bind_rows(spread_data_norm, spread_file(df, norm_cols_s))
    }
}
spread_data_norm[is.na(spread_data_norm)] <- 0
#Remove text columns, doesnt add relevant information
#spread_data_notext <- spread_data[, -grep("text", colnames(spread_data))]
#View(spread_data_notext)
spread_data <-c()
for (i in 1:length(list.files('./dataset3'))){
  file = list.files('./dataset3')[i]
  if(str_sub(file, start= -3) == 'csv'){
    df =  read_csv(file.path('./dataset3',file))
    df = normalize_geometric(df)
    spread_file(df, norm_cols)
    spread_data <- bind_rows(spread_data, spread_file(df, cols_used))
    }
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
spread_data_umap<-subset(spread_data, select=-psd_name)
umap_data<- umap(spread_data_umap)
umap_data_df_nn <-as.data.frame.matrix(umap_data$layout) 
colnames(umap_data_df_nn)<-c('x', 'y')
plot_nonorm<-ggplot()+geom_point(data = umap_data_df_nn, aes(x , y))

umap_data_df['version']<-1
umap_data_df_nn['version']<-0
umap_data_df$x==umap_data_df_nn$x


df_an<-rbind(umap_data_df,umap_data_df_nn)
df_an%>%write_csv('df_an.csv')

ddf <-df_an%>%filter(df_an$version==0)%>%ggplot()+geom_point(aes(x = x, y = y))
ddf <-df_an%>%filter(df_an$version==1)%>%ggplot()+geom_point(aes(x = x, y = y))

cl <-hdbscan(x = df_an%>%filter(df_an$version==1), minPts = 3)
hdbscan_umap_data_df<- cbind(df_an%>%filter(df_an$version==1),cl$cluster)
ggplot(hdbscan_umap_data_df)+geom_point(aes(x, y), col=cl$cluster)


p <- df_an %>%
  plot_ly(
    x = ~x, 
    y = ~y,
    frame = ~version, 
    type = 'scatter',
    mode = 'markers'
  ) 
write_csv(df_an, 'df_an.csv')
write_csv(umap_data_df,'umap_data_df_normalize.csv') 
write_csv(umap_data_df_nn,'umap_data_df_not_normalize.csv') 
library(plotly)
packageVersion('plotly')
grid.arrange(p1, p2, nrow = 1)


#Clustering

library("dbscan")
cl <-hdbscan(x = umap_data_df, minPts = 6)
hdbscan_umap_data_df<- cbind(umap_data_df,cl$cluster)
ggplot(umap_data_df)+geom_point(aes(x, y), col=cl$cluster)
#cl <-hdbscan(x = spread_data, minPts = 5)
#plot(umap_data_df, col=cl$cluster+1, pch=20)

idx_3<-c()
for(i in 1:length(cl$cluster)){
  if(cl$cluster[i]==3){
    idx_3 <- c(idx_3, i)
  }
}



idx_2<-c()
for(i in 1:length(cl$cluster)){
  if(cl$cluster[i]==2){
    idx_2 <- c(idx_2, i)
  }
}



idx_1<-c()
for(i in 1:length(cl$cluster)){
  if(cl$cluster[i]==1){
    idx_1 <- c(idx_1, i)
  }
}


#idx_4_df <- spread_data[idx_4,]
#idx_4_df1<-(idx_4_df[,apply(idx_4_df,2,function(x) !all(x==0))] )
#View(idx_4_df1)

idx_3_df <- spread_data[idx_3,]
idx_3_df1<-(idx_3_df[,apply(idx_3_df,2,function(x) !all(x==0))] )
#View(idx_3_df1)

idx_2_df <- spread_data[idx_2,]
idx_2_df<-idx_2_df %>% filter(!is.na(psd_name))
idx_2_df1<-(idx_2_df[,apply(idx_2_df,2,function(x) !all(x==0))] )
#View(idx_2_df1)

idx_1_df <- spread_data[idx_1,]
idx_1_df1<-(idx_1_df[,apply(idx_1_df,2,function(x) !all(x==0))] )
#View(idx_1_df1)

#View(idx_4_df1)
View(idx_3_df1)
View(idx_2_df1)
View(idx_1_df1)


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
  paste("./dataset3/",sub(".psd", ".csv",files), sep = ''),
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
#idx_1_df1$psd_name<-paste0(idx_1_df1$psd_name,'.csv')
idx_1_plot<-plots(sample(idx_1_df1$psd_name, 2))


#idx_2_df1$psd_name<-paste0(idx_2_df1$psd_name,'.csv')
idx_2_plot<-plots(sample(idx_2_df1$psd_name, 2))
plot(idx_3_plot)
#idx_3_df1$psd_name<-paste0(idx_3_df1$psd_name,'.csv')
idx_3_plot<-plots(head(idx_3_df1$psd_name, 2))
#idx_4_plot<-plots(sample(idx_4_df1$psd_name, 2))



data<-read_csv('./dataset/out12.csv')
data$layer_name[data$layer_name=='rnt'] <- 'r'
data$layer_name[data$layer_name=='logo_despegar'] <- 'logo'
data$layer_name[data$layer_name=='background'] <- 'fondo'

demo_data
demo_data<-data[c('psd_name','layer_name','layer_top','layer_left','layer_width','layer_height')]
demo_plot<-plot_banner(demo_data)

demo_data<-demo_data%>%filter(layer_name %in% c('logo','icono1','texto1','texto2','legal1','fondo'))

ss <- tableGrob(demo_data[c('layer_name','layer_top','layer_left','layer_width','layer_height')], cols = c('elemento','y','x','w','h'))
ss2 <- tableGrob(head(demo_data[c('layer_name','layer_top','layer_left','layer_width','layer_height')], 1), cols = c('elemento','y','x','w','h'))

grid.arrange(demo_plot,ss, ncol = 2)


xmax_demo<-as.numeric(demo_data[1,]['layer_left'][1])
y_demo<-as.numeric(demo_data[1,]['layer_top'][1])
demo_plot2<-demo_plot+
  geom_rect(mapping=aes(xmin=0, xmax=xmax_demo, ymin=y_demo, ymax=y_demo), color="red")+
  geom_rect(mapping=aes(xmin=0, xmax=300, ymin=y_demo-10, ymax=y_demo-10), color="blue")




demo_plot3<-demo_plot+
  geom_rect(mapping=aes(xmin=xmax_demo+10, xmax=xmax_demo+10, ymin=0, ymax=y_demo), color="red")+
  geom_rect(mapping=aes(xmin=xmax_demo, xmax=xmax_demo, ymin=0, ymax=600), color="blue")


demo_data[2,]['layer_left'] = 300
demo_plot_a1<-plot_banner(demo_data)+
  geom_line(mapping=aes(x = c(150,250), y=c(150,350)))+theme_void()+theme(legend.position = 'none')



ggplot()+geom_rect(mapping=aes(xmin=0, xmax=10, ymin=0, ymax=10),color = 'black', fill = 'blue', alpha = 0.4)+
  xlab("w")+ylab('h')
                   