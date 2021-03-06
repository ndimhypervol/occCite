#' @title Occurrence Citations
#'
#' @description Harvests citations for occurrence data
#'
#' @param x An object of class \code{\link{occCiteData}}
#'
#' @return A data frame with citations information for occurrences
#'
#' @importFrom stats na.omit
#'
#' @examples
#' \dontrun{
#' data(myOccCiteObject)
#' myCitations <- occCitation(x = myOccCiteObject)
#' cat(paste(myCitations$Citation, " Accessed via ",
#'      myCitations$occSearch, " on ", myCitations$`Accession Date`, "."),
#'      sep = "\n")
#' }
#' @export

occCitation <-function(x = NULL){
  #Error check input x.
  if (!class(x)=="occCiteData"){
    warning("Input x is not of class 'occCiteData'. Input x must be result of a studyTaxonList() search.\n");
    return(NULL);
  }

  citationTables <- list()

  for(sp in names(x@occResults)) {
    #Initializing citation lists
    GBIFCitationList <- vector(mode = "list");
    GBIFDatasetCount <- NULL;
    BIENCitationList <- vector(mode = "list");
    BIENDatasetCount <- NULL;

    occResults <- x@occResults[[sp]]

    #GBIF
    if(!is.null(occResults$GBIF)){
      ##Pull dataset keys from occurrence table
      datasetKeys <- unlist(as.character(occResults$GBIF$OccurrenceTable$DatasetKey));
      GBIFDatasetCount <- as.data.frame(table(unlist(datasetKeys)));
      GBIFdatasetKeys <- unique(unlist(datasetKeys));
      GBIFdatasetKeys <- stats::na.omit(GBIFdatasetKeys);
      ##Look up citations on GBIF based on dataset keys and removes accession date (supplied date from rGBIF is date citation was sought, not the date the data was accessed)
      for(j in GBIFdatasetKeys){
        temp <- gsub(rgbif::gbif_citation(j)$citation$text, pattern = " accessed via GBIF.org on \\d+\\-\\d+\\-\\d+.", replacement = "", useBytes = T);
        GBIFCitationList <- append(GBIFCitationList,temp);
      }
    }

    #BIEN
    if (!is.null(occResults$BIEN)){
      ##Pull dataset keys from occurrence table
      BIENdatasetKeys <- vector(mode = "list");
      BIENKeysNAs <- vector(mode = "list");
      if (anyNA(occResults$BIEN$OccurrenceTable$DatasetKey)){
        BIENKeysNAs <- append(occResults$BIEN$OccurrenceTable$Dataset[is.na(occResults$BIEN$OccurrenceTable$DatasetKey)]);
      }
      BIENdatasetKeys <- append(BIENdatasetKeys,unlist(as.character((occResults$BIEN$OccurrenceTable$DatasetKey))));
      BIENdatasetKeys <- BIENdatasetKeys[!is.na(BIENdatasetKeys)];

      BIENdatasetCount <- as.data.frame(table(unlist(BIENdatasetKeys)));
      BIENdatasetKeys <- unique(unlist(BIENdatasetKeys));

      #Handle datasets without keys
      if (length(BIENKeysNAs) > 0){
        print(paste0("NOTE: ", length(BIENKeysNAs),
                     " BIEN dataset(s) for ", sp, " do not have dataset keys to link citations. They are: ",
                     unique(unlist(BIENKeysNAs))));
      }

      ##Get data sources
      query <- paste("WITH a AS (SELECT * FROM datasource where datasource_id in (",
                     paste(shQuote(BIENdatasetKeys, type = "sh"),collapse = ', '),")) SELECT * FROM datasource where datasource_id in (SELECT datasource_id FROM a);");
      BIENsources <- BIEN:::.BIEN_sql(query);
    }

    #Columns: UUID, Citation, Access date, number of records
    if(!is.null(occResults$GBIF)){
      GBIFaccessDate <- strsplit(occResults$GBIF$Metadata$modified,"T")[[1]][1]# Assumes that all species queries occurred at the same time, which may not necessarily be the case FIX LATER
      gbifTable <- data.frame(rep("GBIF", length(GBIFdatasetKeys)),
                              GBIFdatasetKeys, unlist(GBIFCitationList),
                              rep(GBIFaccessDate, length(GBIFdatasetKeys)),
                              GBIFDatasetCount[,2], stringsAsFactors = F);
      colnames(gbifTable) <- c("occSearch", "Dataset Key", "Citation", "Accession Date", "Number of Occurrences");
    }

    if(!is.null(occResults$BIEN)){
      BIENcitations <- BIENsources$source_citation;
      # If there is no citation available, replace it with the full name of the primary provider
      for (i in 1:length(BIENcitations)){
        if (is.na(BIENcitations[i])){
          BIENcitations[i] <- BIENsources$source_fullname[i];
        }
      }
      bienTable <- data.frame(as.character(rep("BIEN", length(BIENdatasetKeys))), as.character(BIENdatasetKeys), as.character(BIENcitations), as.character(BIENsources$date_accessed), as.numeric(BIENdatasetCount[,2]), stringsAsFactors = F);
      colnames(bienTable) <- c("occSearch", "Dataset Key", "Citation", "Accession Date", "Number of Occurrences")
    }

    if(!is.null(occResults$GBIF) & !is.null(occResults$BIEN)){
      citationTable <- rbind(gbifTable,bienTable);
    }
    else if(!is.null(occResults$BIEN)){
      citationTable <- bienTable
      # not sure why this is here -- doesn't it erase the bien citation table?
      # citationTable <- NULL;
    }
    else{
      citationTable <- gbifTable
    }

    citationTables[[sp]] <- citationTable[order(citationTable$Citation),]
  }

  # flatten list if only one species to be compatible with vignette, etc.
  if(length(citationTables) == 1) citationTables <- citationTables[[1]]

  return(citationTables);
}
