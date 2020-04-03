get_density <- function(x, y, n = 100) {
  dens <- MASS::kde2d(x = x, y = y, n = n)
  ix <- findInterval(x, dens$x)
  iy <- findInterval(y, dens$y)
  ii <- cbind(ix, iy)
  return(dens$z[ii])
}


correct_latlong<- function(x){
  if(is.na(x)){
    return(x)
  }
  if (x>0) {
    return(-x) 
  }
  
  return(x)
}




findOutlier <- function(data, cutoff = 3) {
  ## Calculate the sd
  sds <- apply(data, 2, sd, na.rm = TRUE)
  ## Identify the cells with value greater than cutoff * sd (column wise)
  result <- mapply(function(d, s) {
    which(d > cutoff * s)
  }, data, sds, na.rm = T)
  result
}
