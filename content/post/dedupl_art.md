De-duplicación de Avisos
==================


Cualquiera que haya hecho un curso introductorio o leído un libro de
Ciencia de Datos sabe que se dice mucho que la limpieza de un dataset
es, por lo menos el 80% del trabajo y luego el modelado. Pero eso no
quiere decir que no hagan falta técnicas propias del modelado para
limpiar un dataset.

<a href="https://lucasenrich.netlify.com/post/dedupl/">Read more </a>

<!--more--> 

Con un scrap hecho a ZonaProp, de las unidades en alquiler en Recoleta
en febrero 2020, luego de una exahustiva limpieza de unificación de la
moneda, de corrección de datos implícitos (NA's que implicaban un dato,
por ejemplo, cocheras-si es NA, cocheras=0).

El problema que quedó fue que el resultado es una base de datos de
*avisos*, pero, ¿que pasa si yo quiero que mi base de datos sea de
*inmuebles*? El problema que me encuentro es que hay avisos duplicados,
ya sea porque vuelven a estar publicados o porque un mismo inmueble es
publicado por más de una inmobiliaria.

¿Cómo se pueden detectar sistematicamente esas duplicaciones? Debajo hay
un método posible

### Los Datos

    library(tidyverse)
    alqs<-read_csv("alq_feb20_recoleta.csv")

Bien, este es el dataset. Una primera idea sería: si dos publicaciones
se parecen lo suficiente, sospechamos que son la misma.

Las columnas son

<table>
<thead>
<tr class="header">
<th>Columna</th>
<th>Descrpción</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>WEB</td>
<td>La url de la publicación</td>
</tr>
<tr class="even">
<td>Provincia</td>
<td>La provincia de la publicación</td>
</tr>
<tr class="odd">
<td>Tipo_Op</td>
<td>Si corresponde a venta o alquiler</td>
</tr>
<tr class="even">
<td>Tipo</td>
<td>Si es casa, comercio,oficina, PH, departamento, etc</td>
</tr>
<tr class="odd">
<td>Zona</td>
<td>El barrio, para CABA, el municipio para las provincias</td>
</tr>
<tr class="even">
<td>Dirección</td>
<td>La dirección de la publicación</td>
</tr>
<tr class="odd">
<td>Latitud y Longittud</td>
<td>Georreferencia</td>
</tr>
<tr class="even">
<td>Inmobiliaria</td>
<td>Quien está publicando</td>
</tr>
<tr class="odd">
<td>Tiempo</td>
<td>Cuanto tiempo lleva publicado en días</td>
</tr>
<tr class="even">
<td>Cochera</td>
<td>Si tiene cochera, boolean</td>
</tr>
<tr class="odd">
<td>Expensas</td>
<td>Cuanto se paga de expensas</td>
</tr>
<tr class="even">
<td>Prices</td>
<td>El precio de venta/alquiler</td>
</tr>
<tr class="odd">
<td>Antigüedad</td>
<td>Cuantos años tiene de construido</td>
</tr>
<tr class="even">
<td>Metros</td>
<td>Tamaño en metros cuadrados</td>
</tr>
<tr class="odd">
<td>Ambientes</td>
<td>Cantidad de Ambientes</td>
</tr>
<tr class="even">
<td>Descripción</td>
<td>El texto de la descripción</td>
</tr>
<tr class="odd">
<td>Baños</td>
<td>Cantidad de baños</td>
</tr>
</tbody>
</table>

Ahora bien, cualquier procedimiento de detección de duplicados requiere
necesariamente cierta flexibilidad, sino buscamos aquellos identicos y
listo; pero la realidad es que la duplicación en general va a tener un
motivo en concreto, sea por corrección de algún dato en particular, sea
por ponerlo en otra inmobiliaria, sea por cambio de la descripción para
que sea más atractiva. Pero por otro lado, revisar todos los pares
posible nos va a llevar a que, si *N* es la cantidad de publicaciones en
el dataset, los chequeos sean *N*<sup>2</sup>. Manualmente, esto, es
inviable.

Entonces, lo que se puede hacer es:

-   Ver la tasa de variación de las variables numéricas.

-   Verificar la distancia (aprovechando que estan georreferenciados)

-   Ver cuanto se parecen las descripciones

### Tasa de variacion de las variables numericas

Una opción sería considerar solo las variables que son iguales, pero eso
descarta la posibilidad que haya una corrección en los datos, ni hablar
si alguno de los datos se considera missing (*N**A*).

Una cuestión antes de arrancar con esta sección, se estará generando una
matriz simétrica para cada una de estas variables númericas. En la cual
*x*<sub>*i**j*</sub> va a ser la tasa de variación entre las
observaciones; y por lo tanto la diagonal cuando *i* = *j*,
*x*<sub>*i**j*</sub> = 0

Empecemos

    pmx<-matrix(nrow=nrow(alqs1), ncol=nrow(alqs1))
    for(i in 1:nrow(alqs)){
      for(j in 1:nrow(alqs)){
        h= abs(alqs3$Prices[i]-alqs3$Prices[j])/max(alqs3$Prices[i],alqs3$Prices[j], na.rm = T)
        pmx[i,j] = h
      }
    }

¿Qué está mal con esta aproximación? Que es un loop anidado, por lo que
el Big O, es cuadrático, la forma *menos* eficiente de llenar una
matriz. Esto quiere decir, que el tiempo que tarda el terminar este loop
depende cuadráticamente del tamaño de las filas.

Se puede aprovechar las operaciones vectorizadas que tiene R-Base para
quedarnos con una Big O lineal.

    pmx<-matrix(nrow=nrow(alqs1), ncol=nrow(alqs1))
    for(i in 1:nrow(alqs)){
      pmx[i,] = abs(alqs3$Prices[i]-alqs3$Prices)/max(alqs3$Prices[i],alqs3$Prices, na.rm = T)
    }

Esto es mejor, pero R tiene su propio diálecto para tratar con loops y
es la facilidad que tiene para trabajar vectorialmente y la familia de
funciones de *apply*, y de paso ponemos en práctica la máxima de *evitar
los loops*

    rel_dif = function(a,b){
      abs(a-b)/max(a,b, na.rm = T)
    }
    pmx<-sapply(FUN = rel_dif, alqs1$Prices,alqs1$Prices)

Ahora que podemos obtener la matriz de diferencias con una sola linea de
código, hagamoslo para todoas las variables númericas.

    mts.mx<-sapply(FUN = rel_dif, alqs1$Metros,alqs1$Metros) #Metros cuadrados

    antig.pmx<-sapply(FUN = rel_dif, alqs1$Antiguedad,alqs1$Antiguedad) #Antigüedad

Solo una cosa, lo que queremos es ver cuan cerca están, pero hasta ahora
vimos la variación, por lo que la cercacia va a estar dada por:

    pmx<-1-as.matrix(pmx)
    pmts<-1-as.matrix(pmts)
    pantg<-1-as.matrix(pantg)

#### Distancia geográfica

Para calcular la distancia geográfica vamos a estar necesitando el
paquete *geosphere* para lo cual se usa el criterio de la distancia
entre dos puntos en una superficie esférica, llamada la distancia
Haversine.

    latlongs<-alqs1 %>% select(Latitud,Longitud)
    dm <- distm(latlongs,latlongs, fun=distHaversine)  

La función llamada **distm** es realmente útil porque viene con una
implementación vectorizada,lo cual soluciona de entrada el problema de
los potenciales loops anidados que teniamos antes.

#### Descripción

Bueno, llegamos al punto álgido, y por esto me refiero a que el criterio
para determinar que tan cerca están dos descripciones no es tan obvio
como la distancia o la variación relativa de alguna variable, porque
estamos tratando ahora con variables no numéricas; por lo tanto antes de
realizar la comparación necesitamos convertir a ese texto en un vector
numérico, para lo cual existen varias vías.

La utilizada en este caso fue *T**F* − *I**D**F* que significa **"term
frequency–inverse document frequency,"**, el cual genera un vector
numérico ponderado por la importancia de cada palabra en el texto (term
frequency) y la frecuencia de la palabra en todos los textos (inverse
document frequency)

Es decir, la ponderación indica que no todas la palabras tienen el mismo
peso para describir una descripción, sino que hay algunas que deben
ponderarse más y otras que deben ponderarse menos. En el caso de una
descripción de un inmueble, las palabras que son más comunes a todas las
descripciones, como pueden ser "baño" ó "cocina", son ponderadas menos
que las palabras que son menos frecuentes a cada descripción, como "a
tres cuadras de la estacion Primera Junta".

Este score esta definido por
$$TFIDF\_{xy} = TF\_{xy}\*log\\frac{N}{df}$$
 donde:

-   *T**F*<sub>*x**y*</sub> es la frecuencia de la palabra *x* en la
    descripción *y*

-   *N* es el número total de descripciones

-   *d**f* es el número total de documentos que contienen la palabra *x*

Por suerte, python tienen una libreria para (casi)todo, por lo que esta
vectorización require solo unas pocas lineas de código;
desafortunadamente, el texto está "sucio" y debe ser limpiado antes de
la vectorización.

    #Eliminar caracteres especiales y espacios innecesarios
    cleanFun <- function(htmlString) {
      #Saco los tags de html
      t=(gsub("\t","",gsub("\n","",gsub("<.*?>", "", htmlString))))
      #Lo paso a minuscula
      t=tolower(t)
      #Le saco los caracteres no alfanumericos
      t=str_replace_all(t, "[[:punct:]]", " ")
      t
      
    }
    #Tokenización y eliminación de stopwords
    prepTx <- function(tx){
      t1=word_tokenizer(cleanFun(tx))
      t2 = t1[!(t1%in%stopwords(kind="es"))]
      t2 = unlist(t2)[nchar(unlist(t2))>2]
      t2
      
    }

Ok, ahora que el text está limpio, es hora de generar la conversión a
numeros

    library(tcR)
    prep_fun <- cleanFun
    tok_fun <- word_tokenizer
    smp_size<-floor(0.75*length(descripciones))
    set.seed(123)
    train_ind <- sample(seq_len(length(descripciones)), size = smp_size)
    train <- descripciones
    it_train <- itoken(train, 
                       preprocessor = prep_fun, 
                       tokenizer = tok_fun,
                       progressbar = TRUE)
    vocab <- create_vocabulary(it_train)
    pruned_vocab = prune_vocabulary(vocab, term_count_min = 100,
                                    doc_proportion_max = 0.5, doc_proportion_min = 0.001)
    vectorizer <- vocab_vectorizer(pruned_vocab)
    dtm_train <- create_dtm(it_train, vectorizer)

    tfidf = TfIdf$new()
    dtm_transformed = tfidf$fit_transform(dtm_train)

Ahora *dtm\_transformed* es nuestra variable que contiene los vectores
numericos para cada descripción. Como son vectores, una forma sencilla
de compararlos es usando la distancia coseno.

    d1_d2_tfidf_cos_sim = sim2(x = dtm_transformed, method = "cosine", norm = "l2")

Y ahora si, nuestra matriz de similitud *d1\_d2\_tfidf\_cos\_sim* nos
permite comparar las descripciones.

#### Unificación de las matrices de similitud

Ahora que tenemos todas las matrices que comparan todos los registros
con todos los demás, es hora de unificarlas.

    A<-pmx
    B<-pmts
    C<-pantg
    D<-d1_d2_tfidf_cos_sim
    E<-dm

    colnames(A)<-alqs3$id
    rownames(A)<-alqs3$id

    colnames(B)<-alqs3$id
    rownames(B)<-alqs3$id

    colnames(C)<-alqs3$id
    rownames(C)<-alqs3$id

    colnames(D)<-alqs3$id
    rownames(D)<-alqs3$id

    colnames(E)<-alqs3$id
    rownames(E)<-alqs3$id


    Aa<-as.data.frame(as.table(A)) %>% distinct(Var1,Var2, .keep_all = T)
    Bb<-as.data.frame(as.table(B)) %>% distinct(Var1,Var2, .keep_all = T)
    Cc<-as.data.frame(as.table(C)) %>% distinct(Var1,Var2, .keep_all = T)
    Dd<-as.data.frame(as.table(D)) %>% distinct(Var1,Var2, .keep_all = T)
    Ee<-as.data.frame(as.table(E)) %>% distinct(Var1,Var2, .keep_all = T)


    colnames(Aa)[3]='precios'
    colnames(Bb)[3]='metros'
    colnames(Cc)[3]='antiguedad'
    colnames(Dd)[3]='descripcion'
    colnames(Ee)[3]='dist_mts'

    AB<-right_join(Aa,Bb, by = c('Var1','Var2'))
    CD<-right_join(Cc,Dd, by = c('Var1','Var2'))
    ABCD<-right_join(AB,CD,by = c('Var1','Var2'))
    ABCDE<-right_join(ABCD,Ee,by = c('Var1','Var2'))

    ABCDE<-ABCDE %>% filter(Var1!=Var2) %>% as_tibble()

Ahora *ABCDE* es nuestra dataframe con todos los pares de *i**d*′*s*, y
las columnas con cada criterio de similitud se agregan en la misma fila

Lo que sigue es un poco arbitrario y seguro hay mejores métodos para
hacerlo. Pero nuestros candidatos a duplicados son aquellos que,
decimos, cumplen los siguientes criterios (en simultaneo):

-   Estan a menos de 300mts entre sí.

-   Tienen una variación en Metros menor al 10%

-   Tienen una variación en Precio menor al 25%

-   Tienen una variación en la descripcion menor al 30%

-   Tienen una variación en antigüedad menor al 10%

En todos los casos se mantienen los resultados *NA* porque eso nos
indica que podría haberse agregado el dato.

    cand_dupls<-ABCDE %>% filter(dist_mts<=300 | is.na(dist_mts)) %>% 
      filter(metros>0.9| is.na(metros)) %>% filter(precios>0.75| is.na(precios)) %>% 
      filter(descripcion>0.7| is.na(descripcion))%>% filter(antiguedad>0.90| is.na(antiguedad))

El resultado de esto es de 840 pares que son potencialmente duplicados.
Lo cual es una reducción bastante drástica de los 1716<sup>2</sup> que
llevaría revisar todos los registros de una base de 1716 registros.

Finalmente, hay un paso más que puede hacerse para que el proceso sea
más robusto y es considerar la propiedad transitiva de los pares,
realizar un network analysis, lo que significa agrupar todos aquellos
id's que tienen suficiente similitud, para eso generamos una variable
que sea 1 para aquellos pares que cumplen los criterios y 0 para
aquellos que no:

    cand_dupls<-cand_dupls %>% mutate(
      potdup = case_when(
       (precios > 0.75 |  is.na(precios)) & (metros > 0.9 |  is.na(metros)) & 
         (antiguedad > 0.9 |  is.na(antiguedad)) & (descripcion > 0.9 |  is.na(descripcion)) &
         (dist_mts<300 | is.na(dist_mts)) ~ 1,
       T ~ 0
      )
    )

Lo que tenemos ahora, es un dataframe que tiene los pares que creemos
que son duplicados, estos van a ser nuestros vinculos en el analisis de
red, los *edges*:

    edges<-cand_dupls %>% select(Var1, Var2, potdup)

Que tienen esta forma

<table>
<thead>
<tr class="header">
<th>ID1</th>
<th>ID2</th>
<th>match</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>45557690</td>
<td>44375852</td>
<td>1</td>
</tr>
<tr class="even">
<td>44349226</td>
<td>45589067</td>
<td>1</td>
</tr>
<tr class="odd">
<td>45620618</td>
<td>44714730</td>
<td>1</td>
</tr>
</tbody>
</table>

Que es la forma que acepta el paquete igraph para generar el grafo que
va a vincular el id como en la imagen debajo, donde

<img src="/img/nodes.png" width="400px" />

-   6,9,10 y 4 serían un anuncio separado del resto, por ejemplo

<!-- -->

    library(igraph)
    g <- graph_from_data_frame(edges)
    fc <- fastgreedy.community(as.undirected(g))

Ahora fc es una lista en el que cada elemento es un vector de id's que
corresponderían al mismo inmueble para ver por ejemplo el grupo 3
podemos hacer:

    alqs %>% filter(id%in%  as.numeric(fc[[3]])) %>% View()

Los links asociados al grupo 3, entonces, son:

\[1\]
"<https://www.zonaprop.com.ar/propiedades/arenales-y-callao-excelente-edificio-de-estilo-44714730.html>"  
\[2\]
"<https://www.zonaprop.com.ar/propiedades/arenales-1700-43499494.html>"
\[3\]
"<https://www.zonaprop.com.ar/propiedades/petit-hotel-arenales-y-callao-700-m-sup2--lote-propio-45138045.html>"
\[4\]
"<https://www.zonaprop.com.ar/propiedades/petit-hotel-arenales-y-callao-700-m-sup2--lote-propio-45564366.html>"
\[5\]
"<https://www.zonaprop.com.ar/propiedades/petit-hotel-arenales-y-callao-700-m-sup2--lote-propio-45564348.html>"

Al grupo 10:

\[1\]
"<https://www.zonaprop.com.ar/propiedades/piso-pueyrredon-y-guido-191-m-sup2--una-o-dos-44047718.html>"  
\[2\]
"<https://www.zonaprop.com.ar/propiedades/pueyrredon-y-guido-piso-191-m-sup2--1-o-2-cocheras-44748468.html>"
\[3\]
"<https://www.zonaprop.com.ar/propiedades/piso-pueyrredon-y-guido-191-m-sup2--una-o-dos-45455991.html>"  
\[4\]
"<https://www.zonaprop.com.ar/propiedades/pueyrredon-2400-45078667.html>"

Pero no todo es un éxito, tambien existen grupos tales como el 1, en el
que hay más de uno:

\[1\]
"<https://www.zonaprop.com.ar/propiedades/en-alquiler-temporario-departamentos-tipo-lofts-de-47-40313161.html>"
\[2\]
"<https://www.zonaprop.com.ar/propiedades/departamentos-en-alquiler-temporario-posadas-1300-40075639.html>"  
\[3\]
"<https://www.zonaprop.com.ar/propiedades/alquiler-loft-m-sup2--47-posadas-1323-recoleta-amobl-y-41937518.html>"
\[4\]
"<https://www.zonaprop.com.ar/propiedades/gran-oport-recoleta-1-amb-47-m-sup2--piso-alto-en-41324130.html>"  
\[5\]
"<https://www.zonaprop.com.ar/propiedades/venta-1amb-al-frente-m-sup2--47-balcon-vista-a-los-41324195.html>"  
\[6\]
"<https://www.zonaprop.com.ar/propiedades/venta-gran-oport-posadas-1323-1-amb-m-sup2--47-balcon-41163069.html>"
\[7\]
"<https://www.zonaprop.com.ar/propiedades/departamento-tipo-lofts-m-sup2--47-amoblados-y-41242674.html>"  
\[8\]
"<https://www.zonaprop.com.ar/propiedades/posadas-1323-edificio-alquiler-temporal-departamentos-41683158.html>"
\[9\]
"<https://www.zonaprop.com.ar/propiedades/loft-al-frente.-amueblado-y-decoracion-de-diseno-42984563.html>"  
\[10\]
"<https://www.zonaprop.com.ar/propiedades/posadas-1323-alquiler-depto-amobl.-y-equip-lofts-41775461.html>"  
\[11\]
"<https://www.zonaprop.com.ar/propiedades/venta-y-alquiler-temporal-apartments-amoblados-41242680.html>"  
\[12\]
"<https://www.zonaprop.com.ar/propiedades/venta-loft-m-sup2--47-balcon-al-frente.-o-en-alquiler-40116759.html>"
\[13\]
"<https://www.zonaprop.com.ar/propiedades/posadas-1323-lofts-m-sup2--47-amobl-y-equip-confort-41768916.html>"  
\[14\]
"<https://www.zonaprop.com.ar/propiedades/posadas-1323-apart-hotel-departamento-41682584.html>"

Pero en todo caso, esto efectivamente detecta gran parte de los
duplicados y puede asistir a que un ser humano genere la identificación
de duplicados.

Esto es un ejemplo de aprendizaje no-supervisado, pero si este analisis
se llevara a fondo obtendríamos un set de datos de duplicaciones
etiquetadas, lo cual podría ser la base para el analisis con
procedimientos de analisis supervisados, y así encontrar patrones de que
causa la duplicaciones; lo cual mejoraría el proceso de identificación
de duplicados y podría usarse también para optimizar los criterios
subjetivos que utilicé mas arriba.
