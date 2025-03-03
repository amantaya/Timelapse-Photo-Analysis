# clear the R environment
rm(list=ls(all=TRUE))

# set the working directory and environment variables
source(paste0(getwd(), "/environment.R"))

# load in the required libraries
source(paste0(getwd(), "/packages.R"))

tic("run entire script")

rename_images_folder <- path_to_temp_data

print(rename_images_folder)

# TODO remove any sub-directories that have NIKON and MISC in their name

# TODO add code for calling Bulk Rename Command PowerShell script but I would need to use glue to substitute in the `environment.R` path variables

system(paste(
  "powershell -f",
  shQuote(
    file.path(currentwd, "scripts", "utilities", "bulk-rename-commands.ps1")
  )
))

# scan the directory containing the photo collections
# store the file paths into a list
tic("scan files")
imagefiles <- list.files(path=rename_images_folder, full.names=T, pattern=c(".JPG|.jpg"), include.dirs = T, recursive=T)
toc()

# convert the character vector into data frame or tibble for pretty printing
imagefiles_df <- tibble::tibble(imagefiles)

# print the file tibble in the console to check its contents
print(imagefiles_df)

# scan the directory containing the photo collections
# store the directory names (folders) into a list
tic("scan directory")
imagefolders <- list.dirs(path=rename_images_folder, recursive=TRUE, full.names = TRUE)
toc()

# convert the character vector into data frame or tibble for pretty printing
imagefolders_df <- tibble::tibble(imagefolders)

# print the directory tibble in the console to check its contents
print(imagefolders_df)

# string split the file paths into a list
imagefiles_string_split <- str_split(imagefiles, pattern = "/")

print(imagefiles_string_split)

# lengths() detects the number of objects in each element within a list
num_data_objects <- lengths(imagefiles_string_split)

print(num_data_objects)

# create an index for the last string split
last_object <- num_data_objects

# create an index for the second to last string split
second_to_last_object <- num_data_objects - 1

# create an index for the third to last string split
third_to_last_object <- num_data_objects - 2

# initialize empty objects to hold data
imagefiles_string_splits <- NULL
keep_last_object <- NULL
keep_second_to_last_object <- NULL
keep_third_to_last_object <- NULL

# use a for loop to keep the last three values from each element in a list
for (i in 1:length(imagefiles_string_split)) {
  keep_last_object[i] <- imagefiles_string_split[[i]][last_object[i]]

  keep_second_to_last_object[i] <-
    imagefiles_string_split[[i]][second_to_last_object[i]]

  keep_third_to_last_object[i] <-
    imagefiles_string_split[[i]][third_to_last_object[i]]

  imagefiles_string_splits[i] <- str_c(
    keep_third_to_last_object[i],
    keep_second_to_last_object[i],
    keep_last_object[i],
    sep = "/",
    collapse = ""
  )
}
# print the vector to check its contents
imagefiles_string_splits

# coerce the image files string split vector into a tibble
imagefiles_tibble_string_split <- tibble::tibble(imagefiles_string_splits)

# print in the console to check its contents
imagefiles_tibble_string_split

# rename the first (and only) column in the tibble to something more descriptive
names(imagefiles_tibble_string_split) <- "path"

# separate the first column of the tibble into new columns to make them easier to read
# preserve the first column, as we may use it to navigate to those files later
# any empty spaces in the resulting tibble will be filled with NAs
# and you will get warnings for any of those places that were filled with NAs
imagefiles_tibble_separated_into_columns <- separate(imagefiles_tibble_string_split, path,
                                                    into = c("sitefolder",
                                                             "subfolder",
                                                             "file"),
                                                    sep = "/",
                                                    remove = FALSE)

# view the resulting tibble, now split into multiple columns
print(imagefiles_tibble_separated_into_columns)

# ------------------------------------------------------------------------------
# prototype a way to handle data using the first site
# get a list of all of the sites
site_list <- unique(imagefiles_tibble_separated_into_columns$sitefolder)

# str(imagefiles_tibble_separated_into_columns$sitefolder)

# grep("DCIM", imagefiles_tibble_separated_into_columns$sitefolder)

# print in the console to check its contents
print(site_list)

# check its structure
str(site_list)

# use a for loop to copy each site one by one
tic("copy files")
for (i in 1:length(site_list)) {
  # filter the out all other data, and keep just the data from the first site
  first_site <- imagefiles_tibble_separated_into_columns %>% dplyr::filter(sitefolder == site_list[i])

  # select the first file from the first site
  first_file <- first_site$file[i]

  # select the last file from the first site using an index
  last_file <- first_site$file[nrow(first_site)]

  # index the file name string to extract the date (remove the the time component)
  # this assumes that the files were already renamed using the Bulk Rename Command
  # to rename each photo using the format Year-Month-Day-Hour-Minute-Seconds
  start_date <- str_sub(first_file, start = 1, end = 10)

  # print in the console to check its structure
  print(start_date)

  # string replace the hyphen to nothing to shorten the length of the date string
  start_date_remove_hyphen <- str_replace_all(start_date, pattern = "-", replacement = "")

  # print in the console to check its structure
  print(start_date_remove_hyphen)

  # do the same thing for the end date
  end_date <- str_sub(last_file, start = 1, end = 10)

  end_date_remove_hyphen <- str_replace_all(end_date, pattern = "-", replacement = "")

  print(end_date_remove_hyphen)

  # get the site folder from the data frame
  site_folder <- unique(first_site$sitefolder)

  # print in the console to check its contents
  print(site_folder)

  # create a new folder name that has the site name, the date of the first photo, and the date of the last photo
  folder_name <- paste(site_folder, start_date_remove_hyphen, end_date_remove_hyphen, sep = "_")

  # print in the console to check its contents
  print(folder_name)

  # duplicate the first site data frame to avoid 'overwriting' the original paths
  first_site_updated_paths <- first_site

  # string replace the site name with the folder name to create a new file path
  first_site_updated_paths$sitefolder <- str_replace(first_site$sitefolder, site_folder, folder_name)

  # construct new file paths using the new folder name
  # this will give R a series of locations to copy the files to
  first_site_new_paths <- paste(first_site_updated_paths$sitefolder, first_site_updated_paths$subfolder, first_site_updated_paths$file, sep = "/")

  # print in the console to check its contents
  print(first_site_new_paths)

  # create a new directory using the folder naming convention of "Site" "First Date" "Last Date"
  dir.create(file.path(path_to_temp_data, first_site_updated_paths$sitefolder[1]))

  subfolders <- unique(first_site$subfolder)

  # print in the console to check how many subfolders are in each site
  print(subfolders)

  # copy the original sub-directories from "00-rename" to the "01-extract"
  source <- file.path(path_to_temp_data, first_site$sitefolder[1], subfolders)

  dest <- file.path(path_to_temp_data, first_site_updated_paths$sitefolder[1])

  file.copy(from = source, to = dest, copy.date = TRUE, recursive = TRUE)
}
toc()

system_time <- Sys.time()

# convert into the correct timezone for your locale (mine is Arizona so we follow Mountain Standard)
attr(system_time,"tzone") <- "MST"

msg_body <- paste("00-rename-photo-directories.R", "completed at", system_time, sep = " ")

RPushbullet::pbPost(type = "note", title = "Script Completed", body = msg_body)
