##.readCellsGDAL


#' rcg
#'
#' @param x
#' @param cells
#' @param layers
#'
#' @export
rcg <- function(x, cells, layers) {

  nl <- nlayers(x)
  if (nl == 1) {
    if (inherits(x, 'RasterLayer')) {
      layers <- bandnr(x)
    } else {
      layers <- 1
    }
  }
  laysel <- length(layers)

  colrow <- matrix(ncol=2+laysel, nrow=length(cells))
  colrow[,1] <- colFromCell(x, cells)
  colrow[,2] <- rowFromCell(x, cells)
  colrow[,3] <- NA
  rows <- sort(unique(colrow[,2]))

  nc <- x@ncols
  con <- rgdal::GDAL.open(x@file@name, silent=TRUE)
  rr <- getRasterBand(con)
blocksize <-getRasterBlockSize(rr)
tiled <- FALSE
if (blocksize[1] > 1L) tiled <- TRUE
##print(blocksize)
  if (laysel == 1) {
    for (i in 1:length(rows)) {
      offs <- c(rows[i]-1, 0)
      v <- rgdal::getRasterData(con, offset=offs, region.dim=c(1, nc), band = layers)
      if (i == 1) print(length(v))
      thisrow <- colrow[colrow[,2] == rows[i], , drop=FALSE]
      colrow[colrow[,2]==rows[i], 3] <- v[thisrow[,1]]
    }
  } else {
    for (i in 1:length(rows)) {
      thisrow <- colrow[colrow[,2] == rows[i], , drop=FALSE]
      if (nrow(thisrow) == 1) {
        offs <- c(rows[i]-1, thisrow[,1]-1)
        v <- as.vector( rgdal::getRasterData(con, offset=offs, region.dim=c(1, 1)) )
        colrow[colrow[,2]==rows[i], 2+(1:laysel)] <- v[layers]

      } else {
        offs <- c(rows[i]-1, 0)
        v <- rgdal::getRasterData(con, offset=offs, region.dim=c(1, nc))
        v <- do.call(cbind, lapply(1:nl, function(i) v[,,i]))

        colrow[colrow[,2]==rows[i], 2+(1:laysel)] <- v[thisrow[,1], layers]
      }
    }
  }
  rgdal::closeDataset(con)
  colnames(colrow)[2+(1:laysel)] <- names(x)[layers]
  colrow[, 2+(1:laysel)]
}
