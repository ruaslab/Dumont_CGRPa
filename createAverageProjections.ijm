// Function to create Average Z-projections
function createAverageProjections() {
    // Set the input folder to the location of the macro
    inputFolder = getDirectory("macro");

    // Create a main output folder named "MaxProjections" inside the input folder
    outputFolder = inputFolder + "AverageProjections/";
    if (!File.exists(outputFolder)) {
        File.makeDirectory(outputFolder);
    }

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

    // Process each .tif file
    for (i = 0; i < tifList.length; i++) {
        // Construct the full path for the current file
        inputImagePath = inputFolder + tifList[i];
        // Extract the shortname from the file name (without the extension)
        shortname = stripExtension(tifList[i]);

        print("Processing file: " + inputImagePath);

        // Open the .tif file
        open(inputImagePath);
        rename("raw");

        // Check if the image is a stack
        if (nSlices() < 2) {
            print("File " + inputImagePath + " is not a stack or has less than 2 slices.");
            close(); // Close the image if it is not a stack
            run("Collect Garbage"); // Clear memory
            continue;
        }

        // Perform the Average Z projection
        run("Z Project...", "start=1 stop=" + nSlices() + " projection=[Average Intensity]");
        rename("average_projection");

        // Construct the full path for saving the output file
        outputFilePath = outputFolder + shortname + "_average_projection.tif";

        // Save the projection
        saveAs("Tiff", outputFilePath);

        // Check if the file was saved correctly
        if (File.exists(outputFilePath)) {
            print("Saved projection to: " + outputFilePath);
        } else {
            print("Error saving file: " + outputFilePath);
        }

        // Close the image after processing
        run("Close All");
        
        // Clear memory after closing the image
        run("Collect Garbage");
    }

	// Close any remaining open windows
	run("Close All");
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

// Run the macro
createAverageProjections();
