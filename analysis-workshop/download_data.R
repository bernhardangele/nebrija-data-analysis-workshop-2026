# Download Workshop Data Files from Google Drive
#
# This function downloads the required CSV data files for the LMM workshop from
# Google Drive. It checks if files already exist and only downloads them if they
# are not present, unless force_download is set to TRUE.
#
# @param force_download Logical. If TRUE, downloads files even if they already exist.
#                      Default is FALSE.
# @param quiet Logical. If TRUE, suppresses download progress messages.
#              Default is FALSE (shows progress).
#
# @return NULL (invisibly). The function is called for its side effects of
#         downloading files and printing status messages.
#
# @details The function downloads:
#   - RASTROS_sample.csv: Portuguese reading data
#   - Hindi_new.csv: Hindi reading time data
#
# @examples
# # Download files if not already present
# download_workshop_data()
#
# # Force re-download even if files exist
# download_workshop_data(force_download = TRUE)
#
# # Download quietly without progress messages
# download_workshop_data(quiet = TRUE)

download_workshop_data <- function(force_download = FALSE, quiet = FALSE) {
  # Create data directory if it doesn't exist
  if (!dir.exists("data")) {
    dir.create("data")
  }
  
  # Define file URLs and destinations
  files <- list(
    list(
      name = "RASTROS_sample.csv",
      url = "https://drive.google.com/uc?export=download&id=1MkCzyXhYsDTBhpQJNjyDlGRjHQGc93PW",
      dest = "data/RASTROS_sample.csv"
    ),
    list(
      name = "Hindi_new.csv",
      url = "https://drive.google.com/uc?export=download&id=1LyfUaGdEsO7_P7uAA5PJ1yNZEgGCnXz7",
      dest = "data/Hindi_new.csv"
    )
  )
  
  # Download each file
  for (file in files) {
    if (force_download || !file.exists(file$dest)) {
      cat("Downloading", file$name, "...\n")
      tryCatch({
        # Download the file
        download.file(file$url, file$dest, mode = "wb", quiet = quiet)
        
        # Validate that the file was created and has content
        file_info <- file.info(file$dest)
        if (file.exists(file$dest) && file_info$size > 0) {
          cat("✓ Successfully downloaded", file$name, 
              sprintf("(%d bytes)\n\n", file_info$size))
        } else {
          cat("✗ Download failed:", file$name, 
              "- file is empty or was not created\n\n")
          # Clean up empty file if it exists
          if (file.exists(file$dest)) {
            file.remove(file$dest)
          }
        }
      }, error = function(e) {
        cat("✗ Error downloading", file$name, ":", e$message, "\n")
        cat("  Please check your internet connection and try again.\n\n")
        # Clean up any partially downloaded file
        if (file.exists(file$dest)) {
          file.remove(file$dest)
        }
      })
    } else {
      cat("✓", file$name, "already exists. Skipping download.\n")
      cat("  (Use force_download = TRUE to re-download)\n\n")
    }
  }
  
  cat("Data download complete!\n")
  
  invisible(NULL)
}
