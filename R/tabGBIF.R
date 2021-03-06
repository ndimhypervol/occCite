#' @title GBIF Table
#'
#' @description Internal function--imports results from `occ_download_get()`
#' and processes them into a table for an `occCiteData` object.
#'
#' @param GBIFresults The results of a GBIF search that will be tabulated
#' into a common format for an occCite object.
#'
#' @param taxon A single species name, for tracing/error checking purposes
#' only.
#'
#' @return A list of lists containing \enumerate{ \item a data frame of
#' occurrence data  \item GBIF search metadata for every GBIF download in
#' the specified directory.}
#'
#' @examples
#' \dontrun{
#' res <- rgbif::as.download(system.file("extdata/Protea_cynaroides",
#'                  "0012335-190621201848488.zip",
#'             package = "occCite"))
#' tabGBIF(GBIFresults = res, taxon = "Protea cynaroides")
#' }
#' @keywords internal

tabGBIF <- function(GBIFresults, taxon){

  occFromGBIF <- rgbif::occ_download_import(GBIFresults);

  if(nrow(occFromGBIF)==0){
    print(paste("Note: there are no GBIF points for ", taxon, ".", sep = ""));
    return(NULL);
  }

  occFromGBIF <- data.frame(occFromGBIF$gbifID, occFromGBIF$species,
                            occFromGBIF$decimalLongitude,
                            occFromGBIF$decimalLatitude,
                            occFromGBIF$day, occFromGBIF$month,
                            occFromGBIF$year, occFromGBIF$datasetName,
                            as.character(occFromGBIF$datasetKey))
  dataService <- rep("GBIF", nrow(occFromGBIF));
  occFromGBIF <- cbind(occFromGBIF, dataService);
  occFromGBIF <- occFromGBIF[stats::complete.cases(occFromGBIF[,-8]),]# "Dataset" column excluded because it is not always filled out, but is useful for quick human checks

  colnames(occFromGBIF) <- c("gbifID", "name", "longitude",
                             "latitude", "day", "month",
                             "year", "Dataset",
                             "DatasetKey", "DataService");
  return(occFromGBIF)
}
