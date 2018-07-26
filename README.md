
# compressPDF
This bash script can reduce the file size of a `.pdf` file. It works best for scanned documents and documents created with `pdfLaTeX`.

Observed compressions:

- Scans: 10% - 60% reduced file size
- pdfLaTeX: 30% - 80% reduced file size


## Features
- Compress PDF data
- Select color mode
- Reduce image DPI


## Dependencies
- GhostScript


## Usage
```
$> ./compressPDF INPUT.pdf [OUTPUT.pdf]
```
If no output file name is given it will default to `output.pdf`. If you leave all prompts blank, the script will compress the PDF without any quality loss.





