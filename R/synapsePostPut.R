## Send a post or put request to Synapse
## 
## Author: Matthew D. Furia <matt.furia@sagebase.org>
###############################################################################

.synapsePostPut <- 
  function(
    uri, 
    entity, 
    endpoint, 
    requestMethod, 
    curlHandle = getCurlHandle(), 
    anonymous = FALSE, 
    opts = .getCache("curlOpts"),
    checkHttpStatus=T
)
{
  ## constants
  kValidMethods <- c("POST", "PUT", "DELETE")
  ## end constants

  if(is.null(uri))
    stop("uri cannot be null")

  path<-endpoint$endpointPrefix
  
  if(is.null(path))
    stop("path cannot be null")

  
  if(!(requestMethod %in% kValidMethods)){
    stop("invalid request method")
  }
  
  if(!is.character(uri)){
    stop("a uri must be supplied of R type character")
  }
  
  if (missing(entity) || is.null(entity)) {
	  stop("no content for post/put")
  }
  
  if(!is.list(entity)) {
    stop("an entity must be supplied of R type list")
  }
  
  if((any(names(entity) == "") || is.null(names(entity))) && length(entity) > 0){
    stop("all entity elements must be named")
  }
  
  if(length(entity) == 0)
    entity <- emptyNamedList
  
  ## change dates to characters
  indx <- grep("date", tolower(names(entity)))
  indx <- indx[as.character(entity[indx]) != "NULL"]
  indx <- indx[names(entity)[indx] != "dateAnnotations"]
  for(ii in indx)
    entity[ii] <- as.character(entity[ii])
  
  
  ## convert integers to characters
  if(length(entity) > 0){
    for(ii in 1:length(entity)){
      if(all(checkInteger(entity[[ii]])))
        entity[[ii]] <- as.character(as.integer(entity[[ii]]))
    }
  }
  
  httpBody <- toJSON(entity)
  
  ## uris formed by the service already have their servlet prefix
  pathIndex<-regexpr(path, uri, fixed=T)
  if(pathIndex>0) {
    uri<-substr(uri, pathIndex+nchar(path), nchar(uri))
  }
  paramIndex<-regexpr("?", uri, fixed=T)
  if(paramIndex>0) {
    uriWithoutParams<-substr(uri, 1, paramIndex-nchar("?"))
  } else {
    uriWithoutParams<-uri
  }
  
  ## Prepare the header. If not an anonymous request, stuff API key or session token into the header
  header <- .getCache("curlHeader")
  if(is.null(anonymous) || !anonymous) {
    header <- .stuffHeader(header, paste(path, uriWithoutParams, sep=""))
  }
  if("PUT" == requestMethod) {
    # Add the ETag header
    header <- c(header, ETag = entity$etag)
  }
  
  if(length(path) > 1)
    stop("put", paste(length(path), path))
  ## Submit request and check response code
  d = debugGatherer()
  
  ##curlSetOpt(opts,curl=curlHandle)
  
  if(!is.null(.getCache("debug")) && .getCache("debug")) {
    message("----------------------------------")
    message("REQUEST: ", requestMethod, " ", uri)
    headerAsString<-paste(lapply(names(header), function(n,x){sprintf("%s=%s",n, x[[n]])}, header), collapse=",")
    message("HEADERS: ", listToString(header))
    message("REQUEST_BODY: ", httpBody)
  }
  
  # check own version, stopping if blacklisted
  checkBlackList()
  
  response<-synapseRequestFollowingAllRedirects(
    uri,
    endpoint,
    postfields = httpBody,
    customrequest = requestMethod,
    httpheader = header,
    curl = curlHandle,
    debugfunction=d$update,
    .opts=opts
  )
  
  if(!is.null(.getCache("debug")) && .getCache("debug")) {
    message("RESPONSE_BODY:: ", response$body)
  }
  
  if (checkHttpStatus) .checkCurlResponse(curlHandle, response$body)
  
  ## Parse response and prepare return value
  parseResponseBody(response)
}

# parse response body based on content type
# the argument is a list in the format returned by 'parseHttpResponse'
parseResponseBody<-function(response) {
  contentType<-response$headers[["Content-Type"]]
  if (is.null(contentType) || contentType=="" || regexpr("application/json", contentType, fixed=T)>0) {
    if (is.null(response$body) || response$body=="") {
      response$body
    } else {
      tryCatch(
        as.list(fromJSON(response$body)),
        error = function(e){NULL}
      )
    }
  } else {
    response$body
  }
  
}
