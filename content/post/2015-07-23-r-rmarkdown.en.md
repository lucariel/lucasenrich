*El problema*: Clusterizar diseños

¿Como hago para clasificar estilos de banners? ENGLISH

Con tantos adds dando vueltas en internet, sigue siendo, muchas veces,
un proceso relativamente manual y poco estandarizado los diseños. Para
eso existen diseñadores.

Pero cuando ya tienen miles realizados, esta bueno mirar atrás e
identificar patrones recurrentes. Saber lo que venimos haciendo sirve
para mirar hacia adelante.

<!--more--> 

<img src="/img/banner-example.png" width="400px" />

**Input data**

El problema tenia originalmente cientos de diseños, en este ejemplo,
dado que tiene que ver con algoritmos de clusterización, se usaran
algunos hechos ad hoc, por lo que el ejemplo es con tamaños reducidos y
la clasificacion de imagenes, fuentes de texto y demás quedan afuera. Lo
que queremos saber es si la ubicación de los elementos en la imagen
sigue un patron en particular.

Los datos venian de la siguiente forma:

<img src="/img/input_data.png" width="65%" style="float:left; padding:20px" />

Donde:

-   <font size = 3> *y* : Distancia desde arriba </font>

-   <font size = 3> *x* : Distancia desde la izquierda </font>

-   <font size = 3> *w* : Ancho (width) </font>

-   <font size = 3> *h* : Alto (height) </font>

Si tenemos 50 ejemplos, con 3 elementos cada uno, y hay 4 variables por
elemento, la forma del input es 50 × 3 × 4, esto, a los algoritmos, no
les gusta demasiado. Asique fue necesario achatar la base para obtener
una base de datos de 50 × 12, para lo cual:

Primero se agarra cada uno (una base de 1 × 3 × 4) y se la transforma en
una sola fila 1 × 12 para lo cual se uso el código:

    library(tidyverse)
    cols_used = c('element_top', 'element_left', 'element_width', 'element_height')
    spread_file<-function(data, cols_used){
      cols_used_a = c('element_name',cols_used)
      y=data[cols_used]
      h = data[cols_used_a]
      z=c(1,1,1,1)
      for(i in 1:nrow(y)) {
        z = cbind(z,y[i,])
      }
      z = z[1,-1] 
      
      newcols <- c()
      for (i in  h['element_name']){
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
      n<-as_vector(data['id'])
      z['id']<-n[1]
      z
    }

Lo que transforma cada elementos con la forma:

$$\\begin{bmatrix} elem1 & y\_1 & x\_1 & w\_1 & h\_1 \\\\   elem2 & y\_2 & x\_2 & w\_2 & h\_2  \\\\   \\vdots \\\\   elemk & y\_2 & x\_k & w\_k & h\_k \\end{bmatrix}$$
 a la forma:

$$\\begin{bmatrix} 
   id.1 & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w
\\end{bmatrix}$$
 Así se pueden apilar todos elementos de la muestra para quedar una sola
base de datos con la forma:

$$\\begin{bmatrix} id.1 & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w \\\\ id.2 & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w \\\\ \\vdots \\\\ id.N & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w \\end{bmatrix}$$

-   <font size = 3> Reduccion de dimensionalidad + Clustering </font>

La forma más directa para realizar la tarea de clusterización es
simplemente usando el paquete **dbscan** y correrlo sobre nuestra base
transformada. Pero no funcionó del todo. Asique lo siguiente fue reducir
la dimensionalidad de los objetos, en este caso se uso el algoritmo UMAP
y luego se hizo la clusterización.

PCA (componentes principales), es el algoritmo más popular para reducir
la dimensionalidad. Luego esta t-SNE.

En pocas palabras, UMAP fue la mejor opción porque utiliza un algoritmo
rapido que preserva mejor la estructura global.

Y finalmente:


    library(umap)
    library(dbscan)
    umap_data<- umap(data)
    cl <-hdbscan(x = umap_data, minPts = 3)

Pero también habia un tema de escala, quiza el diseño era parecido pero
un banner era dos veces mas grande, por lo que el resultado no era
adecuado.

<font size = 3> Surge la necesidad de transformar los datos

Opciones </font>

-   <font size = 2> Estandarizacion (z-score): Representa el numero de
    desvios estandar arriba o debajo del valor resultante. **Útil para
    variables normalmente distribuidas** </font>

-   <font size = 2> Normalizacion (min-max scaler): Permite llevar los
    valores entre 0 y 1. **Útil para comparar variables de diferentes
    ordenes de magnitud** (Precio de una casa y los m2 que ocupa)
    </font>

<img src="/img/normaliz_data.png" width="65%" style="float:left; padding:20px" />

**¿Puedo usar estas transformaciones en estos datos?**

<font size = 4>

-   No, como las variables describen dimensiones (alto y ancho), y
    posicion en el espacio no le encontré mucho sentido a la
    estandarizacion ni la normalizacion.

</font>

<font size = 4>

-   ¿Que podría hacer? En lugar de ver las posiciones y dimensiones
    *absolutas*, ver las posiciones y dimensiones *relativas*, lo que
    voy a llamar "normalizacion geometrica"

<!-- -->

    normalize_geometric<-function(df){
      df['total_area']<-max(df['element_height'])*max(df['element_width'])

      df['rel_area']<-df['element_height']*df['element_width']/df['total_area']
      
      df['orientation']<-df['element_height']/df['element_width']
      
      df['element_top_relative']<-df['element_top']/max(df['element_height'])
      
      df['element_left_relative']<-df['element_left']/max(df['element_width'])
      
      df
    }

</font>

-   x' es la proporcion de x respecto al rango total (ancho del canvas)

<font size = 3> *mi nueva variable x' es: la linea roja dividida la
linea azul* </font>

<img src="/img/x_demo_plot.jpeg" width="65%" style="float:left; padding:20px" />

-   y' es la proporcion de y respecto al rango total (alto del canvas)

<font size = 3> *mi nueva variable y' es: la linea roja dividida la
linea azul* </font>

<img src="/img/demo_plot_y.jpeg" width="65%" style="float:left; padding:20px" />

-   areaRelativa es la proporcion del area del elemento respecto al
    total

<font size = 3> *mi nueva variable areaRelativa es: el area del cuadrado
chiquito dividido la del rectangulo grande* </font>

<img src="/img/area_plot.jpeg" width="65%" style="float:left; padding:20px" />

-   disposicion (dividiendo alto por acho) es para saber si el elemento
    es horizontal, vertical, o cuadrado

<font size = 3> *mi nueva variable disposicion es: el alto dividido por
el ancho* </font>

<img src="/img/rectangular.png" width="30%" style="float:center; padding:0% 35%" />

Resultados
----------

Para empezar a evaluar los resultados, todo "spread" tiene que tener su
"gather":


    gather_file<-function(gdf){
      x<-strsplit(colnames(gdf), '\\.')
      
      element_name=unique(unlist(map(x, 1)))
      original_cols=unique(unlist(map(x, 2)))
      gdf1<-data.frame(element_name)
      gdf1[original_cols[1]]<-0
      gdf1[original_cols[2]]<-0
      gdf1[original_cols[3]]<-0
      gdf1[original_cols[4]]<-0
      
      
      
      rel_area<-c()
      orientation<-c()
      element_top_relative<-c()
      element_left_relative<-c()
      
      for(i in seq(from=1, to=length(gdf), by=4)){
        #  stuff, such as
        rel_area=c(rel_area,gdf[i])
        orientation=c(orientation,gdf[i+1])
        element_top_relative = c(element_top_relative,gdf[i+2])
        element_left_relative = c(element_left_relative,gdf[i+3])
      }
      
      gdf1['rel_area']=as_vector(unlist(rel_area))
      gdf1['orientation']=as_vector(unlist(orientation))
      gdf1['element_top_relative']=as_vector(unlist(element_top_relative))
      gdf1['element_left_relative']=as_vector(unlist(element_left_relative))
      gdf1}

En principio veamos como quedaron los grupos sin normalizar y con la
normalización

<img src="/img/unnamed-chunk-12-1.png" width="30%" style="float:center; padding:0% 35%" />

Y finalmente, un par de ejemplos por grupo:

Primer cluster:

<img src="/img/c1img.jpeg" width="30%" style="float:center; padding:0% 35%" />
000003.png

Segundo cluster:

<img src="/img/cl2img.jpeg" width="30%" style="float:center; padding:0% 35%" />

Tercero:

<img src="/img/cl3img.jpeg" width="30%" style="float:center; padding:0% 35%" />
