<h1>Clusterize design patterns</h1>

¿How can I find patterns in design?

With so many adds around, one would think that that process is quite standardized
but it remains, most times, a manual labor. This is, I believe mostly,
because of how competitive that market is. To stand out, graphic designers have
still a lot of work

But that doesn't mean that we can't find design patterns, after all, after
a few thousend design even the best designer tend to have trends.


<a href="https://lucasenrich.netlify.com/en/post/clusterizar-disenos/">Read more </a>

<!--more--> 


<img src="/img/banner-example.png" width="400px" />

**Input data**

This problem had, originally, many houndred of designs, in this example
I will use just a few made ad hoc for this purposes because
in the end, clustering algorithms doesn't need that many data to
be effective.

Given these are manual examples, it's all about sizes and shapes. I
left behind fonts, content of the images and other. What I look for is
pattern in the layout of the elements in the banner




Once extracted, data came in this form:

<img src="/img/input_data.png" width="65%" style="float:left; padding:20px" />

Where:

-   <font size = 3> *y* : Distance from the top </font>

-   <font size = 3> *x* : Distance from the left </font>

-   <font size = 3> *w* : Width </font>

-   <font size = 3> *h* : Height </font>

If we have 50 exameples, with 3 elements each, and 4 variables per element
the shape of the input file is 50 × 3 × 4. Algorithms like I used like
2D data better, so I spread them to 50 × 12 for which:

First, iterate file by file and transform each from 1 × 3 × 4 to
1 × 12. In R code:

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

And then iterate to transform this

$$\\begin{bmatrix} elem1 & y\_1 & x\_1 & w\_1 & h\_1 \\\\   elem2 & y\_2 & x\_2 & w\_2 & h\_2  \\\\   \\vdots \\\\   elemk & y\_2 & x\_k & w\_k & h\_k \\end{bmatrix}$$
 in this:

$$\\begin{bmatrix} 
   id.1 & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w
\\end{bmatrix}$$
 This way, you can stack them into:

$$\\begin{bmatrix} id.1 & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w \\\\ id.2 & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w \\\\ \\vdots \\\\ id.N & elem.1.x & elem.1.y & elem.1.h & elem.1.w & ... & elem.k.w \\end{bmatrix}$$

-   <font size = 3> Dimentionality reduction + Clustering </font>

This most direct form of clusterization for this porpuses is **dbscan** and
run it on our transform base. This didn't work as expected so first I
used a technique to reduce dimensionality and then do the clustering.

PCA and t-SNE are the most popular algorithms in dimensionality reduction
but UMAP is the new kid in the block (well it has almost 2 years now)
with some fancy math behind it, it preserves global and local structures.
and works faster using graphs. One thing to keep in mind when using it is that at one
point uses a random procedure which makes it that each time you run it
the mapping into 2D will look slightly different, but every point is
similary close to others in each iteration. To prevent this, set.seed()
is the way to go. 

And finally:


    library(umap)
    library(dbscan)
    umap_data<- umap(data)
    cl <-hdbscan(x = umap_data, minPts = 3)

This worked better than with the full dimentions, but not quite as needed. Its time to...

<font size = 3> Transform and normalice

Most common option </font>

-   <font size = 2> Standarization (z-score): Represents the number of standard
    deviations up or down of resulting value. **Useful for normally distributed
    variables**
    </font>

-   <font size = 2> Normalization (min-max scaler): It allows to transform the data
    into values between 0 and 1. **Useful when working with variables with different
    orders of magnitude** 
    </font>

<img src="/img/normaliz_data.png" width="65%" style="float:left; padding:20px" />

**Can I use this transformations in this data?**

<font size = 4>

-   Not really, what this variables describe are absolute positions in space
    and are quite linked to one-another.  

</font>

<font size = 4>

-   What can I do? Instead of using absolute positions and dimentions, 
    lets use its *relative*, what I'll call "geometric normalization"

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

-   x' is now the proportion of x in respecto the total width of the canvas

<font size = 3> *My new variable is x', red line divided the blue one* </font>

<img src="/img/x_demo_plot.jpeg" width="65%" style="float:left; padding:20px" />

-   y' is now the proportion of x in respecto the total height of the canvas

<font size = 3> *My new variable is y', red line divided the blue one* </font>

<img src="/img/demo_plot_y.jpeg" width="65%" style="float:left; padding:20px" />

-   areaRelativa is the proportion of the canvas the element occupies 


<font size = 3> *My new variable areaRelativa is: the are of the small rectangle divided
divided the area of the big one* </font>

<img src="/img/area_plot.jpeg" width="65%" style="float:left; padding:20px" />

-   disposition is to know if the elmenet in horizontal position, vertical or if
it is a square

<font size = 3> *My new variable disposicion es: heigth/width* </font>

<img src="/img/rectangular.png" width="30%" style="float:center; padding:0% 35%" />

Results
----------
To begin to analize the results, every "spread" has to have a "gather"



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

Let's first see how the clustering works with and without geometric normalization

<img src="/img/unnamed-chunk-12-1.png" width="30%" style="float:center; padding:0% 35%" />

And finally, examples of each group:

First cluster:

<img src="/img/c1img.jpeg" width="30%" style="float:center; padding:0% 35%" />
000003.png

Second cluster:

<img src="/img/cl2img.jpeg" width="30%" style="float:center; padding:0% 35%" />

Third:

<img src="/img/cl3img.jpeg" width="30%" style="float:center; padding:0% 35%" />
