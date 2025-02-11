# Background and Configuration --------------------------------------------

## Horse-Cattle-Elk Grazing Interaction Study Rproj
## Step 6: Copy Chunk to Blank Macro

## What this script does:
## Reads in the CSV file 'subjects_chunk_1.csv'from metadata sub-folder
## Copies the data from the CSV file into the blank macro .XLSM
## Writes out a macro for each chunk that is ready for scoring

## What this script requires:
## The CSV files from 05-Chunk Subject Photos and Copy to Sub-Folder.R
## e.g. WCS_05262017_06142017_subjects_chunk1.csv

# Setup R Environment -----------------------------------------------------

# clear the R environment
rm(list = ls(all.names = TRUE))

# set the working directory and environment variables
source(here::here("environment.R"))

# load in the required packages
source(here::here("packages.R"))

# load in the required functions
source(here::here("functions.R"))

# Select Folders to Extract -----------------------------------------------

project_switch <- "white mountains"

if (project_switch == "heber") {
  blankmacro <- "HorseImaging-2021-Heber.xlsm"
} else if (project_switch == "white mountains") {
  blankmacro <- "HorseImaging-2020-White-Mountains.xlsm"
} else if (project_switch == "heber motion") {
  blankmacro <- "HorseImaging-2021-Heber-Motion.xlsm"
} else {
  warning("The project has not been selected or was entered incorrectly.")
}

# create a variable to hold the file name
# in case we switch to a different project kanban board
project_kanban_file <-
  here::here(
    "docs",
    "project boards",
    "White Mountains Project Kanban.md"
  )

# read in the kanban board for the Heber project
project_kanban <-
  readr::read_lines(
    here::here(
      project_kanban_file
    ),
    skip_empty_rows = FALSE,
    progress = readr::show_progress()
  )

# heading patterns to find

copy_to_blank_macro_heading_regex <-
  "##\\sFolders\\sto\\sCopy\\sinto\\sBlank\\sMacro"

upload_to_box_scoring_heading_regex <-
  "##\\sFolders\\sto\\sUpload\\sto\\sBox\\sfor\\sSCORING"

# create and index of the two headings
# we want what's in between the headings
copy_to_blank_macro_heading_index <-
  stringr::str_which(
    project_kanban,
    pattern = copy_to_blank_macro_heading_regex
  )

upload_to_box_scoring_heading_index <-
  stringr::str_which(
    project_kanban,
    pattern = upload_to_box_scoring_heading_regex
  )

# add 1 because we don't want to include the first heading
# subtract 1 because we don't want to include the last heading
# subset the kanban board using these indexes
kanban_board_subset <-
  project_kanban[
    (copy_to_blank_macro_heading_index + 2):
    (upload_to_box_scoring_heading_index - 2)
  ]

folders_to_copy_regex <-
  "([[:upper:]][[:upper:]][[:upper:]]_\\d{8}_\\d{8}|A\\d{2}_\\d{8}_\\d{8}|[[:upper:]][[:upper:]][[:upper:]]_5min_\\d{8}_\\d{8}|[[:upper:]][[:upper:]][[:upper:]]\\d{2}_\\d{8}_\\d{8})" # nolint: line_length_linter

folders_to_copy_pattern_matches <-
  stringr::str_extract(kanban_board_subset,
                       pattern = folders_to_copy_regex)

# return only the pattern matches that were not NA
folders_to_copy <-
  folders_to_copy_pattern_matches[
    is.na(folders_to_copy_pattern_matches) == FALSE
  ]

# create a data frame with a "site" column
# that we can use to construct file paths
# TODO replace these path constructing functions with reading the file paths from a JSON
# the fromJSON creates a data frame whereas the read_json creates a list
sites_from_json <- jsonlite::fromJSON(
  here::here("data", "metadata", "cameratraps.json"))

cameratraps_folders_to_copy <-
  extract_site_code_from_collection_folder(
    folders_to_copy
  )

cameratraps_folders_to_copy <-
  construct_path_to_site_folder_from_site_code(
    cameratraps_folders_to_copy,
    path = "G:"
  )

cameratraps_folders_to_copy <-
  construct_path_from_collection_and_site_folders(cameratraps_folders_to_copy)


# Find Number of Chunks in Collection Folder ------------------------------

# list all of the chunk subfolders in the collection
subfolders_in_collection_folder_relative_path <-
  list.dirs(
    cameratraps_folders_to_copy$path[1],
    full.names = FALSE
  )

subfolders_in_collection_folder_absolute_path <-
  list.dirs(
    cameratraps_folders_to_copy$path[1]
  )

# create a wildcard pattern to match just the "chunk" subfolders
chunk_wildcard <- "chunk*"

# use a global regular expression to match
# and return just the "chunk" subfolders
chunk_subfolders_in_collection_folder <-
  grep(chunk_wildcard,
    subfolders_in_collection_folder_relative_path,
    value = TRUE
  )

chunk_subfolders_absolute_paths <-
  grep(chunk_wildcard,
    subfolders_in_collection_folder_absolute_path,
    value = TRUE
  )

if (length(chunk_subfolders_in_collection_folder) == 0) {
  stop(
    paste(
      "There Are 0 Chunk Folders in",
      cameratraps_folders_to_copy$collection_folder[1],
      "Please check to collection folder for problems."
    )
  )
}

# number of chunks in the collection folder
# use this object to indexing
n_chunks_in_collection_folder <-
  length(chunk_subfolders_in_collection_folder)

# Copy and Rename Blank XLSM into Chunk Folder ----------------------------

for (j in seq_len(n_chunks_in_collection_folder)) {
  chunk_name <- chunk_subfolders_in_collection_folder[j]

  path_to_chunk_csv <-
    file.path(
      cameratraps_folders_to_copy$path[1],
      "metadata",
      paste0(
        cameratraps_folders_to_copy$collection_folder[1],
        "_subjects_",
        chunk_name,
        ".csv"
      )
    )

  # copy the template excel macro from the templates folder
  from <-
    file.path(
      currentwd,
      "templates",
      "excelmacro",
      blankmacro
    )

  # create a file name for each XLSM
  xlsm_file_name <-
    paste0(
      cameratraps_folders_to_copy$collection_folder[1],
      "_subjects_",
      chunk_name,
      ".xlsm"
    )

  # copy each renamed XLSM into each chunk folder within the collection
  to <- file.path(
    cameratraps_folders_to_copy$path[1],
    chunk_name,
    xlsm_file_name
  )

  file.copy(from = from, to = to)
}

# Read Chunk CSV File and Copy into Blank XLSM ----------------------------

for (k in seq_len(n_chunks_in_collection_folder)) {

  chunk_name <- chunk_subfolders_in_collection_folder[k]

  path_to_chunk_csv <-
    file.path(
      cameratraps_folders_to_copy$path[1],
      "metadata",
      paste0(
        cameratraps_folders_to_copy$collection_folder[1],
        "_subjects_",
        chunk_name,
        ".csv"
      )
    )

chunk_csv <- readr::read_csv(path_to_chunk_csv)

# keep only the columns that we want
chunk_discard_columns <-
  chunk_csv %>%
  dplyr::select(
    RecordNumber,
    ImageFilename,
    ImagePath,
    ImageRelative,
    ImageSize,
    ImageTime,
    ImageDate,
    ImageAlert
  )

  chunk_ImageRelative_keep_filename <-
    chunk_discard_columns %>%
    dplyr::mutate(
      ImageRelative =
        basename(ImageRelative)
    )

  xlsm_file_name <-
    paste0(
      cameratraps_folders_to_copy$collection_folder[1],
      "_subjects_",
      chunk_name,
      ".xlsm"
    )

  # copy and paste the data from the csv file into the macro
  xlsm_workbook <-
    openxlsx::loadWorkbook(
      file.path(
        cameratraps_folders_to_copy$path[1],
        chunk_name,
        xlsm_file_name
      )
    )

  # "writeData" writes data to workbook object bound to R
  # but those changes are not yet saved to the file
  openxlsx::writeData(
    xlsm_workbook,
    "ImageData",
    chunk_ImageRelative_keep_filename,
    startCol = 1,
    startRow = 2,
    colNames = FALSE
  )

  # write out a filled macro
  openxlsx::saveWorkbook(
    xlsm_workbook,
    file.path(
      cameratraps_folders_to_copy$path[1],
      chunk_name,
      xlsm_file_name
    ),
    overwrite = TRUE
  )
}

# Copy Chunk to Temp Folder for Uploading ---------------------------------

# create a new folder to use as a temporary folder for uploading to the cloud
for (i in seq_along(chunk_subfolders_absolute_paths)) {
  temp_folder_for_uploading_chunk <-
    file.path(
      path_to_temp_data,
      "upload",
      "scoring",
      cameratraps_folders_to_copy$collection_folder[1],
      paste0("chunk", i)
    )

  # the source is the folder "chunks" on the external hard drive
  from <- chunk_subfolders_absolute_paths[i]

  to <- temp_folder_for_uploading_chunk

  # copy the chunks onto my local drive for upload
  fs::dir_copy(
    path = from,
    new_path = to
  )
}

# Archive Completed Task on Kanban Board ----------------------------------

# create a regex to match the "Archive" heading
archive_heading_regex <- "^##\\sArchive"

# find the index of the Archive heading
archive_heading_index <-
  stringr::str_which(project_kanban,
    pattern = archive_heading_regex
  )

# create a regex to match the kanban settings section
# this is the last section on the board
kanban_settings_regex <- "^%% kanban:settings"

# find the end of the Archive heading
kanban_settings_heading_index <-
  stringr::str_which(project_kanban,
    pattern = kanban_settings_regex
  )

location_to_write_archived_task <- kanban_settings_heading_index - 2

completed_task_string <- kanban_board_subset[1]

# trim the first 6 characters from the completed task string
# i.e. remove "- [ ] "
completed_task_string_remove_checkbox <-
  stringr::str_remove(
    string = completed_task_string,
    pattern = "- \\[ \\] "
  )

# create an archived task string
archived_task_string <-
  paste("- [x]",
    Sys.time(),
    completed_task_string_remove_checkbox,
    sep = " "
  )

# add the completed task to the Archive heading
project_kanban <-
  append(project_kanban,
    values = archived_task_string,
    after = location_to_write_archived_task
  )

# Create Next Task for Kanban Board ---------------------------------------

# create a new task string to put in the next section
next_task_string <- stringr::str_replace(
  string = completed_task_string,
  pattern = "copytoxlsm",
  replacement = "uploadtobox/scoring")

# create a regex to find the next heading
folders_to_add_to_basecamp_as_scoring_assignments_heading_regex <-
  "## Folders to Add to Basecamp as SCORING Assignments"

# find the location of where to put the next task
folders_to_add_to_basecamp_as_scoring_assignments_heading_index <-
  stringr::str_which(
    string = project_kanban,
    pattern = folders_to_add_to_basecamp_as_scoring_assignments_heading_regex
  )

# subtract 2 so we don't include the heading and 1 new line
location_to_put_next_task <-
  folders_to_add_to_basecamp_as_scoring_assignments_heading_index - 2

project_kanban <-
  append(project_kanban,
    values = next_task_string,
    after = location_to_put_next_task
  )

# Remove Completed Task from Kanban Board ---------------------------------

# find the line number of the task we completed
completed_task_index <- copy_to_blank_macro_heading_index + 2

# remove the task we completed from the kanban board
project_kanban <- project_kanban[-completed_task_index]


# Write to Kanban Board ---------------------------------------------------

readr::write_lines(project_kanban,
                   file = project_kanban_file)

# Push Notification Script Completed --------------------------------------

system_time <- Sys.time()

msg_body <-
  paste("06-copy-chunk-to-blank-macro.R",
    "ran on folder",
    cameratraps_folders_to_copy$collection_folder[1],
    "completed at",
    system_time,
    sep = " "
  )

RPushbullet::pbPost(
  type = "note",
  title = "Script Completed",
  body = msg_body
)

# Re-Run Script if Folders Remain -----------------------------------------

# re-run this script on the next collection folder
# stop if no collection folders remain to process
# send a notification if all folders have been processed

cameratraps_folders_to_copy <- cameratraps_folders_to_copy[-1, ]

if (nrow(cameratraps_folders_to_copy) != 0) {
  source(
    here:::here(
      "scripts",
      "utilities",
      "06-copy-chunk-to-blank-macro.R"
    )
  )
} else {
  msg_body <- paste(
    "06-copy-chunk-to-blank-macro.R",
    "completed at",
    system_time,
    sep = " "
  )

  RPushbullet::pbPost(
    type = "note",
    title = "All Folders Completed",
    body = msg_body)
}
