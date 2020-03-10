*El problema*: Clusterizar diseños

¿Como hago para clasificar estilos de banners?

    knitr::include_graphics("banner-example.png")

<img src="banner-example.png" width="400px" />

**Input data**

*Se sacan metadatos de un archivo de photoshop*

    knitr::include_graphics("input_data.png")

<img src="input_data.png" width="65%" style="float:left; padding:20px" />

-   <font size = 3> *y* : Distancia desde arriba </font>

-   <font size = 3> *x* : Distancia desde la izquierda </font>

-   <font size = 3> *w* : Ancho (width) </font>

-   <font size = 3> *h* : Alto (height) </font>

Estrategia 1:

-   <font size = 3> Reduccion de dimensionalidad + Clustering </font>

<!-- -->


    library(umap)
    library(dbscan)
    #umap_data<- umap(data)
    #cl <-hdbscan(x = umap_data, minPts = 3)

    knitr::include_graphics("sin_norm2.png")

<img src="sin_norm2.png" width="45%" style="float:left; padding:20px" />

-   <font size = 3> Se puede ver un grupo diferenciado, pero los demas
    no estan tan claros. </font>

**Validacion**

*En terminos de negocio...¿sirve hacer esto?*

-   <font size = 4> Al separar en diferentes carpetas los archivos de
    cada cluster generado, los diseñadores no estaban conformes, habia
    diseños distintos que habian sido clasificados como similares

</font>

    #knitr::include_graphics("preguntas-768x449.jpg")

**Estrategia 2**

<font size = 3> Surge la necesidad de transformar los datos

Opciones </font>

-   <font size = 2> Estandarizacion (z-score): Representa el numero de
    desvios estandar arriba o debajo del valor resultante. **Útil para
    variables normalmente distribuidas** </font>

-   <font size = 2> Normalizacion (min-max scaler): Permite llevar los
    valores entre 0 y 1. **Útil para comparar variables de diferentes
    ordenes de magnitud** (Precio de una casa y los m2 que ocupa)
    </font>

<!-- -->

    knitr::include_graphics("normaliz_data.png")

<img src="normaliz_data.png" width="60%" height="10%" style="float:center; padding:20px" />

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

    #knitr::include_graphics("img_rel.jpg")

</font>

Normalizacion "geometrica"
--------------------------

-   x' es la proporcion de x respecto al rango total (ancho del canvas)

<font size = 3> *mi nueva variable x' es: la linea roja dividida la
linea azul* </font>

![](x_demo_plot.jpeg)

Normalizacion "geometrica"
--------------------------

-   y' es la proporcion de y respecto al rango total (alto del canvas)

<font size = 3> *mi nueva variable y' es: la linea roja dividida la
linea azul* </font>

![](demo_plot_y.jpeg)

Normalizacion "geometrica"
--------------------------

-   areaRelativa es la proporcion del area del elemento respecto al
    total

<font size = 3> *mi nueva variable areaRelativa es: el area del cuadrado
chiquito dividido la del rectangulo grande* </font>

![](area_plot.jpeg)

Normalizacion "geometrica"
--------------------------

-   disposicion (dividiendo alto por acho) es para saber si el elemento
    es horizontal, vertical, o cuadrado

<font size = 3> *mi nueva variable disposicion es: el alto dividido por
el ancho* </font>

    knitr::include_graphics("rectangular.png")

<img src="rectangular.png" width="30%" style="float:center; padding:0% 35%" />

Resultados
----------
