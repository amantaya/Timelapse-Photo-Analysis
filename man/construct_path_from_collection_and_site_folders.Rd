% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cameratraps_path_constructor.R
\name{construct_path_from_collection_and_site_folders}
\alias{construct_path_from_collection_and_site_folders}
\title{Construct a Path to a Collection Folder}
\usage{
construct_path_from_collection_and_site_folders(sitecode_df)
}
\arguments{
\item{sitecode_df}{A data frame that contains a column named \code{site_code} and
(optionally) a column named \code{collection_folder}. This data frame is usually
generated by the function \code{extract_site_code_from_collection_folder()}.}
}
\value{
Returns a path to the collection folder in a new column \code{path}.
}
\description{
\code{construct_path_from_collection_and_site_folders} constructs a
file path by combining the path to the site_folder and appending onto the
path the collection folder.
}
\examples{
library(GrazingCameratraps)

df <- data.frame(
  site_code = "BUO23",
  collection_folder = "BUO23_20210525_20210624",
  site_folder = "G:/cameratraps2/BUO23"
  )
construct_path_from_collection_and_site_folders(df)

}
