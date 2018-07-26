#!/bin/bash
# author: emanuel.regnath@tum.de

# help
function print_usage(){
	echo "Usage: $0 FILE.pdf [OUTPUT.pdf]"
}


# check arguments
if [[ -f $1 ]]; then
  INPUT="$1"
  if [[ -f $2 ]]; then
    OUTPUT=$2
  else
    OUTPUT="./output.pdf"
  fi
  echo "Convertig $INPUT to $OUTPUT"
else
  print_usage
  exit 0
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
  Select Base Qualtity (or ENTER to leave untouched): 

  1) printer (300 DPI)
  2) ebook (150 DPI)
  3) screen (72 DPI)
  "
  read -p "Your Choice: " pdfset
  case $pdfset in
      1) PDF_FLAGS="-dPDFSETTINGS=/printer";;
      2) PDF_FLAGS="-dPDFSETTINGS=/ebook";;
      3) PDF_FLAGS="-dPDFSETTINGS=/screen";;
      "") PDF_FLAGS="";;
      *) echo "invalid option";;
  esac


echo "
Select Image Quality (or ENTER to leave untouched):

  1) 150 DPI (readable text)
  2) 200 DPI (good looking scans)
  3) 300 DPI (print photographs)
  4) 600 DPI (too high)

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
# echo "
# Select Font Options (or ENTER to leave untouched):
#   1) embedd all fonts as subsets
#   2) embedd all fonts completeley
#   2) remove all embedded fonts
# "
# read -p "Your Choice: " fontchoice
# case $fontchoice in
#     1) FONT_FLAGS=" -dEmbedAllFonts=true -dSubsetFonts=true";;
#     1) FONT_FLAGS=" -dEmbedAllFonts=true -dSubsetFonts=false";;
#     1) FONT_FLAGS=" -dEmbedAllFonts=false";;
#     "") FONT_FLAGS="";;
#     *) echo "invalid option";;
# esac



# convert using ghostscript
echo "Optimizing PDF ..."

gs -dBATCH -dNOPAUSE -dSAFER \
 -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
 ${PDF_FLAGS} \
 ${COLOR_FLAGS} \
 ${DPI_FLAGS} \
 -sOutputFile=$OUTPUT $1



# print stats
if [ $? == '0' ]; then
    optsize=$(stat -c "%s" "${OUTPUT}")
    orgsize=$(stat -c "%s" "${INPUT}")
    if [ "${optsize}" -eq 0 ]; then
        echo "No output!  Keeping original"
        rm -f "${OUTPUT}"
        exit;
    fi
    if [ ${optsize} -ge ${orgsize} ]; then
        echo "Didn't make it smaller! Keeping original"
        rm -f "${OUTPUT}"
        exit;
    fi
    bytesSaved=$(expr $orgsize - $optsize)
    percent=$(expr $optsize '*' 100 / $orgsize)
    echo Saving $bytesSaved bytes \(now ${percent}% of old file size\)
fi

exit 0


