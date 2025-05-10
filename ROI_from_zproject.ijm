// Set the input folder to the location of the macro
inputFolder = getDirectory("macro");

// Create a main output folder named "ROI" inside the input folder
outputFolder = inputFolder + "ROI/";
File.makeDirectory(outputFolder);

// Get the list of files in the input folder
fileList = getFileList(inputFolder);

// Initialize an empty array for .tif files
tifList = newArray();

// Manually filter the list to get only .tif files
for (i = 0; i < fileList.length; i++) {
    if (endsWith(fileList[i], ".tif")) {
        tifList = Array.concat(tifList, fileList[i]);
    }
}

// Function to generate ROIs
function processImage(inputImagePath, outputFolder, shortname) {
    // Create a unique folder for each image inside the "ROI" directory
    imageOutputFolder = outputFolder + shortname + "/";
    File.makeDirectory(imageOutputFolder);
    
    // Open the specified .tif file and rename the image window to "raw"
    open(inputImagePath);
    rename("raw");
    
    // Print the image file name in the log to indicate that processing has started
    print("//Clear");
    print("Processing image: " + inputImagePath);

    // Get file dimensions and pixel to micron ratio
    getDimensions(width, height, channels, slices, frames);
    getVoxelSize(pixelWidth, pixelHeight, pixelDepth, unit);
    imageName = getTitle();

    // Define the size of the region of interest (ROI) in microns and convert it to pixels
    roiSizeMicron = 800;
    roiSizePixels = roiSizeMicron / pixelWidth;
    // Define the spacing between ROIs in microns and convert it to pixels.
    // Decreasing the spacingMicron value will reduce the distance between the ROIs, thereby increasing the number of ROIs generated.
    // You might want to set this to a smaller value depending on how densely you want the ROIs to be placed.
    // If you want ROIs to overlap, reduce the spacingMicron to be less than the roiSizeMicron.
    // If you want them to be adjacent without overlapping, spacingMicron should equal roiSizeMicron.
    spacingMicron = 800;
    spacingPixels = spacingMicron / pixelWidth;
    
    // Print the ROI size in the log
    print("ROI size: " + roiSizeMicron + " um");

    // Initialize counters
    savedROIs = 0;
    notSavedROIs = 0;

    // Loop through the slices, and within each slice, loop through the x and y coordinates to generate ROIs
    for (x = 0; x < width; x += spacingPixels) {
        for (y = 0; y < height; y += spacingPixels) {
            
            // Ensure the ROI fits within the image boundaries
            if (x + roiSizePixels <= width && y + roiSizePixels <= height) {
                
                // Select the "raw" image window and create a rectangular ROI at the current x, y position
                selectWindow(imageName);
                makeRectangle(x, y, roiSizePixels, roiSizePixels);
                
                // Get basic statistics for the current ROI, including area, mean, min, max, and standard deviation
                getStatistics(area, mean, min, max, std);
                totalarea = area;

                // Check if the maximum pixel intensity in the ROI exceeds 4000 (indicating a significant signal)
                if (max > 1000) {
                    
                    // Duplicate the ROI for further processing
                    run("Duplicate...", "use");
                    
                    // Apply a threshold to isolate high-intensity pixels
                    setThreshold(1000, max);
                    
                    // Create a selection based on the threshold
                    run("Create Selection");
                    
                    // Get statistics for the high-signal area within the ROI
                    getStatistics(area, mean, min, max, std);
                    highsignalarea = area;
                    
                    // Reset the threshold and deselect the current selection
                    resetThreshold();
                    run("Select None");

                    // Check if the high-signal area is between 5% and 50% of the total ROI area
                    if (highsignalarea / totalarea > 0.05 && highsignalarea / totalarea < 0.5) {
                        
                        // Convert the image to RGB color format
                        run("RGB Color");
                        
                        // Generate a filename for the cropped ROI and save it as a .tif file in the unique folder
                        fileName = shortname + "_crop_" + roiSizeMicron + "um_x-" + x + "_y-" + y + ".tif";
                        
                        // Log the ROI statistics along with the coordinates
                        print("ROI Stats: x=" + x + ", y=" + y + 
                              ", Area=" + totalarea + 
                              ", Mean=" + mean + 
                              ", Max=" + max + 
                              ", High Signal Area=" + highsignalarea);

                        saveAs("Tiff", imageOutputFolder + fileName);
                        
                        // Increment the saved ROIs counter
                        savedROIs++;
                        
                        // Close the duplicated ROI image window
                        close();
                    } else {
                        // Increment the not saved ROIs counter without saving the thresholded image
                        notSavedROIs++;
                        
                        // Close the duplicated ROI image window
                        close();
                    }
                }
            }
        }
    }
    
    // Log the total number of ROIs analyzed and the number saved
    print("Total ROIs saved: " + savedROIs);
    print("Total ROIs not saved: " + notSavedROIs);
    
    // Select the "Log" window and save its content to a text file in the unique folder
    selectWindow("Log");
    save(imageOutputFolder + shortname + "_log.txt");
    close("Log");

    // Close the original "raw" image window
    close();
}

// Helper function to strip the extension from a filename
function stripExtension(filename) {
    dotIndex = indexOf(filename, ".");
    if (dotIndex > 0) {
        return substring(filename, 0, dotIndex);
    } else {
        return filename; // Return the filename as is if there's no dot
    }
}

// Process each .tif file
for (i = 0; i < tifList.length; i++) {
    inputImagePath = inputFolder + tifList[i];
    shortname = stripExtension(tifList[i]);
    processImage(inputImagePath, outputFolder, shortname);
}
