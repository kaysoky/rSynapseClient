## Unit tests converting  hex to base64
## 
## Author: Nicole Deflaux <nicole.deflaux@sagebase.org>
###############################################################################

unitTestMd5hexToBase64 <- function() {
  checkEquals('BP5xIZ38aXAq1sYBz2iDbw==', synapseClient:::.hexMD5ToBase64MD5(checksumHex='04fe71219dfc69702ad6c601cf68836f')) 
}


