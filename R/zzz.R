# TODO: Add comment
# 
# Author: mfuria
###############################################################################

.cache <- new.env(parent=emptyenv())

kSupportedLayerCodeMap <- list(
		PhenotypeLayer = "C",
		ExpressionLayer = "E",
		GenotypeLayer = "G"

	)
kSupportedLayerStatus <- c("Curated", "QCd", "Raw")
kSupportedPlatforms <- list(
		phenotype.data = c("Custom"),
		expression.data = c("Affymetrix", "Agilent", "Illumina", "Custom"),
		genotype.data = c("Affymetrix", "Illumina", "Perlegen", "Nimblegen", "Custom")
	)

## package-local 'getter'
.getCache <-
		function(key)
{
	.cache[[key]]
}

## package-local 'setter'
.setCache <-
		function(key, value)
{
	.cache[[key]] <- value
}

.deleteCache <-
		function(keys)
{
	indx <- which(names(.cache) %in% keys)
	if(length(indx) > 0)
		.cache <- .cache[[-indx]]
}

.onLoad <-
		function(libname, pkgname)
{
	resetSynapseHostConfig()
	dataLocationPrefs("awss3")
	.setCache("synapseCacheDir", "/synapseCache")
	.setCache("supportedRepositoryLocationTypes", c("awss3"))
	.setCache("layerCodeTypeMap", kSupportedLayerCodeMap)
	.setCache("supportedLayerStatus", kSupportedLayerStatus)
	.setCache("supportedPlatforms", kSupportedPlatforms)
	.setCache("sessionRefreshDurationMin", 60)
	.setCache("repoServicePath", "repo/v1")
	.setCache("authServicePath", "auth/v1")
	.setCache("curlOpts", list(ssl.verifypeer = FALSE))
	.setCache("curlHeader", c('Content-Type'="application/json", Accept = "application/json"))
	.setCache("anonymous", FALSE)
	.setCache("downloadSuffix", "unpacked")
	
}