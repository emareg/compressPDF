#!/bin/bash
# Author: emanuel.regnath@tum.de

# help
function print_usage(){
	echo "Usage: $0 FILE.pdf [OUTPUT.pdf]"
}



bytes_saved(){
  # print stats
  if [ -f "$1" ]; then
    orgsize=$(stat -c "%s" "${1}")
    optsize=$(stat -c "%s" "${2}")
    if [[ "${optsize}" -eq 0 ]]; then
        rm -f "${2}"
        printf '\033[0;33m%s\033[0m\n' "ERROR, 0B. Deleted."
    fi 
    bytesSaved=$(expr $orgsize - $optsize)
    percent=$(expr $optsize '*' 100 / $orgsize)
    if [[ "${percent}" -gt 100 ]]; then
      printf '\033[0;31m%3d%% now, sorry.\033[0m\n' ${percent}
    elif [[ "${percent}" -gt 80 ]]; then
      printf '\033[1;33m%3d%%\033[0m now, saved %d bytes.\n' ${percent} $bytesSaved
    else
      printf '\033[1;32m%3d%%\033[0m now, saved %d bytes.\n' ${percent} $bytesSaved
    fi
  fi 
}



# check arguments
if [[ -f $1 ]]; then
  INPUT="$1"
  if [[ -z "$2" ]]; then
    OUTPUT="./output_compressed.pdf"
  elif [[ -f "$2" ]]; then
    echo "$2 already exists. Please move or delete it first and try again."
    exit 1
  else 
    OUTPUT="$2"
  fi
elif [[ -d $1 ]]; then
  INPUT_DIR="${1%/}"
  OUTPUT_DIR="${INPUT_DIR}_compressed"
# save and change IFS
OLDIFS=$IFS
IFS=$'\n'
  pdfs=($(\ls "$1" | \grep -E '^*.pdf$'))
  #pdfs=($(find "$1" -maxdepth 1 -iname '*.pdf'))
  IFS=$OLDIFS
  echo "'$INPUT_DIR/' is a directory. I will compress the following ${#pdfs[@]} PDFs and write them to '${OUTPUT_DIR}/'."
  printf '  - %s\n' "${pdfs[@]}"
  if [[ -d "$OUTPUT_DIR" ]]; then
    echo -en "\033[1;31mWarning:\033[0m '$OUTPUT_DIR/' already exists. "
    read -p "Overwrite it? (y|n)" -n 1 yn
  else
    read -p "Do you want to compress all of the above? (y|n) " -n 1 yn
  fi 
  echo ""
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    echo "OK. Please select compression options."
  else
    echo "Sorry. Bye."
    exit 0
  fi
else
  echo "'$1' is neither a PDF nor a directory."
  print_usage
  exit 1
fi




# menu
echo "
Select Color Option (or ENTER to leave untouched): 

  1) Gray
  2) Color
  "
  read -p "Your Choice: " color
  case $color in
      1) COLOR_FLAGS="-sColorConversionStrategy=Gray -sColorConversionStrategyForImages=Gray -dProcessColorModel=/DeviceGray";;
      2) COLOR_FLAGS="";;
      "") COLOR_FLAGS="";;
      *) echo "invalid option";;
  esac


  echo "
Select Base Qualtity (printer is default): 

  1) screen (72 DPI)
  2) ebook (150 DPI)
  3) printer (300 DPI, default)
  "
  read -p "Your Choice: " pdfset
  case $pdfset in
      1) PDF_FLAGS="-dPDFSETTINGS=/screen";;
      2) PDF_FLAGS="-dPDFSETTINGS=/ebook";;
      3) PDF_FLAGS="-dPDFSETTINGS=/printer";;
      "") PDF_FLAGS="-dPDFSETTINGS=/printer";;
      *) echo "invalid option";;
  esac


echo "
Select Image Quality (or ENTER to leave untouched):

  1) 150 DPI (readable text)
  2) 200 DPI (good looking scans)
  3) 300 DPI (print photographs)
  4) 600 DPI (high resolution)

  or type a number between 72 and 1200 DPI
"
read -p "DPI: " dpichoice
case $dpichoice in
    1) DPI=150;;
    2) DPI=200;;
    3) DPI=300;;
    3) DPI=600;;
    "") DPI="";;
    *) DPI=$dpichoice;;
esac


if [[ "" -eq $DPI ]]; then
  DPI_FLAGS=""
else
  DPI_FLAGS=" -dDownsampleGrayImages=true \
 -dDownsampleColorImages=true \
 -dDownsampleMonoImages=true \
 -dColorImageDownsampleType=/Bicubic \
 -dColorImageResolution=$DPI \
 -dGrayImageDownsampleType=/Bicubic \
 -dGrayImageResolution=$DPI \
 -dMonoImageDownsampleType=/Bicubic \
 -dMonoImageResolution=$DPI"
fi


# todo:
echo "
Select Font Options (or ENTER to leave untouched):

  1) embed all fonts as subsets (recommended)
  2) embed all fonts completely
  3) remove all embedded fonts
"
read -p "Your Choice: " fontchoice
case $fontchoice in
    1) FONT_FLAGS=" -dEmbedAllFonts=true -dSubsetFonts=true";;
    2) FONT_FLAGS=" -dEmbedAllFonts=true -dSubsetFonts=false";;
    3) FONT_FLAGS=" -dEmbedAllFonts=false";;
    "") FONT_FLAGS="";;
    *) echo "invalid option";;
esac



# convert using ghostscript
echo "Optimizing PDF ..."

if [ -z "$OUTPUT_DIR" ]; then
  echo "Converting $INPUT to $OUTPUT"

  gs -dBATCH -dNOPAUSE -dSAFER \
   -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
   ${PDF_FLAGS} \
   ${COLOR_FLAGS} \
   ${DPI_FLAGS} \
   ${FONT_FLAGS} \
   -sOutputFile="$OUTPUT" "$INPUT"

   printf "Compressed ${INPUT}: "; bytes_saved "$INPUT" "$OUTPUT"
else

  mkdir "${OUTPUT_DIR}"
  echo "Compressing PDFs from ${INPUT_DIR} to ${OUTPUT_DIR}"
  echo ""

for pdf in "${pdfs[@]}"; do
  OUTPUT="${OUTPUT_DIR}/$pdf"
  INPUT="${INPUT_DIR}/$pdf"

  printf '\033[1;37m%-40s\033[0m' "${pdf}..."

  gs -dBATCH -dNOPAUSE -dSAFER -q \
   -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
   ${PDF_FLAGS} \
   ${COLOR_FLAGS} \
   ${DPI_FLAGS} \
   ${FONT_FLAGS} \
   -sOutputFile="$OUTPUT" "${INPUT}"

   bytes_saved "$INPUT" "$OUTPUT"

done

  echo "All done."

fi










exit 0


