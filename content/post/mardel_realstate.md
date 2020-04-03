ANALISIS DE LA OFERTA INMOBILIARIA EN MAR DEL PLATA
==================

Entender el mercado inmobiliario, nos permite detectar las necesidades y deseos de la porción de la población
que compran, o que invierten en la generación de servicios de vivienda (ya sea para consumo propio o para
terceros). Los datos se extrajeron de scrappear ZonaProp de manera exhaustiva, los datos estan geolocalizados
por lo cual se pueden hacer analisis espaciales.

<a href="https://lucasenrich.netlify.com/post/mardel_realstate/">Read more </a>

El mercado inmobiliario, está compuesto por un conjunto de bienes y servicios heterogéneos, no sólo en sus
características, sino también en su localización.

Estas características de cada uno de los inmuebles que se encuentran en el mercado constituyen, en su
conjunto, las características de la oferta de inmuebles en un determinado período de tiempo. Habitualmente,
lo que se observa del mercado inmobiliario es un stock de la oferta y se asume que el precio es el de equilibrio,
en el sentido que los oferentes intentarían obtener el mayor precio que le posibilite la venta o el alquiler, en el
menor tiempo posible. Sin embargo, el flujo de inmuebles que se han vendido no es un conjunto observable y
tal vez sea el conjunto más importante por determinar. Este flujo que se ha vendido o alquilado representa a
aquellos inmuebles que hoy no se encuentran en el stock disponible a la venta o en alquiler, pero que en algún
momento lo estuvieron; por lo que es necesario conformar una base de datos con los inmuebles que están
disponibles actualmente en stock, pero también aquellos que en un lapso han salido y aquellos nuevos que
ingresan a conformarlo. Para ello se desarrolló una rutina a través de un software, que permite relevar los
datos de compra y venta de inmuebles disponibles en la web, para analizar su evolución en el tiempo, para
poder construir distintos indicadores que sirvan como herramientas para los desarrolladores inmobiliarios, a
la hora de decidir las características y el emplazamiento de sus proyectos.

Estudio de la base
---------------

El total de registro de ventas con los que contamos en para el tercer trimestre de 2019 de nuestra búsqueda
de datos en la web, una vez que se han eliminado los datos repetidos, es de aproximadamente 25675 casos, de
los cuales, 15562 corresponden a departamentos y 5489 corresponden a casas. En el cuadro resumen de la
base de ventas se tuvieron en cuenta algunas características como la cantidad de m2 ofertados, m2 promedio
y valor en dólares promedio para Mar del Plata.


<table>
<caption>Caracteristicas de la base de datos</caption>
<thead>
<tr class="header">
<th align="left">Tipo</th>
<th align="right">Cantidad</th>
<th align="right">Precio_M2</th>
<th align="right">Tamaño</th>
<th align="right">Precio</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">Departamento</td>
<td align="right">15562</td>
<td align="right">2066</td>
<td align="right">70</td>
<td align="right">138747</td>
</tr>
<tr class="even">
<td align="left">Casa</td>
<td align="right">5489</td>
<td align="right">811</td>
<td align="right">434</td>
<td align="right">245960</td>
</tr>
<tr class="odd">
<td align="left">PH</td>
<td align="right">1645</td>
<td align="right">1207</td>
<td align="right">101</td>
<td align="right">99352</td>
</tr>
<tr class="even">
<td align="left">Terrenos</td>
<td align="right">1451</td>
<td align="right">743</td>
<td align="right">700</td>
<td align="right">316334</td>
</tr>
<tr class="odd">
<td align="left">Local comercial</td>
<td align="right">659</td>
<td align="right">1751</td>
<td align="right">208</td>
<td align="right">197579</td>
</tr>
<tr class="even">
<td align="left">Oficina comercial</td>
<td align="right">287</td>
<td align="right">1569</td>
<td align="right">98</td>
<td align="right">125887</td>
</tr>
<tr class="odd">
<td align="left">Garage</td>
<td align="right">245</td>
<td align="right">912</td>
<td align="right">1932</td>
<td align="right">803429</td>
</tr>
<tr class="even">
<td align="left">Fondo de Comercio</td>
<td align="right">132</td>
<td align="right">1221</td>
<td align="right">968</td>
<td align="right">1340016</td>
</tr>
<tr class="odd">
<td align="left">Bodega-Galpón</td>
<td align="right">99</td>
<td align="right">611</td>
<td align="right">875</td>
<td align="right">336943</td>
</tr>
<tr class="even">
<td align="left">Edificio</td>
<td align="right">51</td>
<td align="right">1737</td>
<td align="right">759</td>
<td align="right">887350</td>
</tr>
</tbody>
</table>

De la tabla, se desprende que el 82.16% de oferta inmobiliaria de Mar del Plata esta compuesta por
Departamento (60.74%) y Casa (21.42%) y que los departamentos tienen el mayor precio por metro cuadrado,
por el menor tamaño de las ofertas.
Asimismo, los datos del trimestre revelan la variación de las cantidades, los precios y tamaños de cada tipo
de inmueble.

<img src="/img/unnamed-chunk-3-1.png" />


En este caso, podemos ver, por ejemplo, que el aumento del tamaño promedio de los inmuebles, causa que, a
pesar de un aumento del precio, el precio por metro cuadrado tenga una ligera caida. Lo contrario ocurre con
los PHs. Lo cual en el caso de los terrenos (una mejora metodologica en Octubre nos permite obtener mejores
datos de Terrenos y Locales Comerciales), las variaciones se compensan y se mantiene estabe el precio por
metro cuadrado
La base de datos cuenta también con inmuebles que han reducido su precio en los últimos 3 meses.

<table>
<caption>Bajaron de Precio</caption>
<thead>
<tr class="header">
<th align="left">Tipo</th>
<th align="right">Cantidad</th>
<th align="left">Bajó</th>
<th align="right">Precio_M2</th>
<th align="left">var Precio m2</th>
<th align="right">Tamaño</th>
<th align="left">var Tamaño</th>
<th align="right">Precio</th>
<th align="left">var Precio</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">Departamento</td>
<td align="right">207</td>
<td align="left">8.63%</td>
<td align="right">1891</td>
<td align="left">-13.51%</td>
<td align="right">54</td>
<td align="left">-33.65%</td>
<td align="right">100875</td>
<td align="left">-35.72%</td>
</tr>
<tr class="even">
<td align="left">PH</td>
<td align="right">10</td>
<td align="left">9.80%</td>
<td align="right">1173</td>
<td align="left">12.05%</td>
<td align="right">81</td>
<td align="left">-50.80%</td>
<td align="right">91780</td>
<td align="left">-27.27%</td>
</tr>
</tbody>
</table>

En el cuadro podemos ver que el precio promedio que bajaron los departamentos es del 8.63% mientras que
los PHs bajaron más, un promedio de 9.8%.
Los inmuebles que bajaron de precio también tienen una serie de caracteristicas particulares. Los precios por
metro cuadrado de los departamentos que bajaron son 13.5% más baratos que el precio promedio, es decir,
que los que bajan son aquellos que de por sí, ya están por debajo del precio promedio. Lo mismo ocurre
respecto al tamaño, los que bajan son 33% más pequeños que la muestra general


Los PH’s tienen una caracteristica particular que tiene que ver con que a pesar de ser más pequeños, tienen
un precio por metro cuadrado mayor que el general de PH en la muestra. Esto se debe a que la diferencia
respecto al promedio en el tamaño es más chica que la diferencia en el precio del inmueble.


Publicaciones por Inmobiliaria
------------------

La base de datos cuenta también con las inmobiliarias, extraídas desde noviembre 2019. Lo cual permite
evaluar mejor la oferta disponible. En principio, podemos ver que la gran mayoría de las inmobiliarias tienen
pocas publicaciones, el 77% tiene menos de 22 publicaciones en el trimestre analizado. Mientras que si
éxisten inmobiliarias que tienen muchas más publicaciones, el 1% de las inmobiliarias tienen entre 276 y 419
publicaciones activas en el trimestre.


<img src="/img/unnamed-chunk-6-1.png" />


Estos datos también pueden ser utilizados para hacer un seguimiento del market-share de cada una de ellas y
eventualmente hacer una valuación de los inmuebles que tienen a la venta.

Zonas de Densidad de oferta
-----------------------

La infomación obtenida esta geolocalizada en un 97%, lo cual nos permite ubicar en un mapa los inmuebles a
la venta, y poder visualizar la densidad de la oferta de inmuebles. La mayor densida, de acuerdo a los datos,
se encuentra en los barrios de La Perla, donde una hay una desproporcionada densidad de inmuebles.
En el norte, cerca de Parque Peña, hay un foco de oferta; al sur, este foco está en Los Acantilados
Por lo general, estos focos de oferta se encuentran en la costa (salvo Los Acantilados). Aquellos que se
encuentran fuera, se caracterizan por ser los barrios cerrados Rumencó y Arenas del Sur



<iframe seamless src="/img/densidad.html" width="100%" height="500"></iframe>



De esta información se puede extraer las zonas y obtener descripciones de cada una de ellas.


<img src="/img/unnamed-chunk-8-1.png" />




<img src="/img/unnamed-chunk-9-1.png" />

Esto nos dice que si bien la zona 6 ocupa el 10% de los m² ofrecidos,
constituye el 26% de las publicaciones. Y, conjuntamente con la zona 5,
son el 25% de los m² ofrecidos, pero superan el 52% del total de
publicaciones. 


Las variables que puede ser descriptas en este sentido son, para cada zona:

-   Tipo de Inmueble
-   Tamaño de los inmuebles
-   Precio por metro cuadrado
-   Precio

### Tipo

Debajo se puede ver que en la zona de menor densidad de oferta (zona 0), el mercado consiste predominantemente en terrenos y casas. Y a medida que nos vamos acercando a la zona de mayor concentración de oferta (zona 6) ocurren varias cosas. En primer lugar los terrenos dejan de estar disponibles; luego, se incorporan casas, los departamentos van ocupando la mayor parte de la oferta y en el centro comercial, donde mayor oferta hay, se incorporan los locales comerciales y garages, desplazando a los PH’s.


<img src="/img/unnamed-chunk-10-1.png" />


Este tipo de distribución es entendible desde el punto de vista que, las unidades de menor tamaño permiten que haya más oferta por unidad de terreno.

### Tamaños

Los tamaños de los inmuebles juegan un rol fundamental en la concentración geográfica de la oferta. Porque inmuebles de menor tamaño permiten una mayor cantidad de inmuebles por unidad de terreno.


<img src="/img/unnamed-chunk-11-1.png" />

Como se vió en la sección de tipos de inmuebles se corrobora que, a menor densidad de oferta, mayor son los tamaños de los inmuebles a la venta. Por ejemplo, en la zona 0, donde predominan terrenos y casas, el tamaño promedio es de 1163m², lo cual se reduce exponencialmente a medida que se acerca a la zona 0.

### Precios

Los precios de los inmuebles en cada zona son más homogeneos que las variables previamente analizadas. Aunque cierta tendencia sigue existiendo. En la zona 6, donde mayor inmuebles hay, es donde se encuentran los menores precios.


<img src="/img/unnamed-chunk-12-2.png" />


Esta información, sin embargo, no refleja la variabilidad de los precios. Ya que si bien los precios en la zona 6 son más baratos, en promedio, la variabilidad de los precios en esa zona es 50% mayor a la variabilidad de los precios en la zona 0. Esto quiere decir que si bien hay más con precios más bajos, también los hay con precios mucho mayores. Es decir, en las zonas donde predominan los departamentos los precios son mucho menos consistentes que los precios donde dominan los terrenos y las casas.

### Precio por metro cuadrado

Si a medida que hay mayor concentración de oferta, las unidades son de mayor tamaño y los precios promedios son más homogéneos transversalmente a las zonas se concluye que los precios por metro cuadrado serán mayores allí donde haya mayor concentración de oferta

<img src="/img/unnamed-chunk-13-1.png" />

### Determinación de zonas de precios...

De la misma manera que se determinaron las zonas de mayor y menor concentración de oferta puede determinarse las zonas de mayor o menor precios por metro cuadrado.

<iframe seamless src="/img/pm2_d.html" width="100%" height="500"></iframe>




Así también como de cualquier variable númerica disponible. Y esta información se puede tener filtrada por tipo de inmueble, inmobiliaria, barrio, mes, etc según sea necesario.
Alguno de los mapas alternativos pueden visualizarse en: [mapa
interactivo](https://lucariel.shinyapps.io/mapa_inmobiliario/)
