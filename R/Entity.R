#
# 
# Author: furia
###############################################################################


setClass(
  Class = "Entity",
  contains = "SimplePropertyOwner",
  representation = representation(
    attachOwn = "AttachmentOwner",
    annotations = "SynapseAnnotations",
    synapseEntityKind = "character",
    synapseWebUrl = "character",
    generatedBy = "activityOrNULL",
    generatedByChanged = "logical"
  ),
  prototype = prototype(
    annotations = new("SynapseAnnotations"),
    SynapseWebUrl = "",
    generatedByChanged = FALSE,
    properties = SynapseProperties(getEffectivePropertyTypes("org.sagebionetworks.repo.model.Entity"))
  )
)

defineEntityConstructors("org.sagebionetworks.repo.model.Entity", package="synapseClient")

setMethod(
  f = "getParentEntity",
  signature = "Entity",
  definition = function(entity){
    if(is.null(entityId <- propertyValue(entity, "parentId")))
      return(NULL)
    parent <- tryCatch(
      getEntity(entityId),
      error = function(e){
        warning(as.character(e))
        NULL
      }
    )
    parent
  }
)

setMethod(
  f = "onWeb",
  signature = signature("Entity"),
  definition = function(entity){
    .doOnWeb(entity)
  }
)

setMethod(
  f = "available.versions",
  signature = signature("Entity"),
  definition = function(object){
    if(is.null(object$properties$id))
      return(NULL)
    .jsonListToDataFrame(synapseGet(sprintf("/entity/%s/version", object$properties$id))$results)
  }
)

setMethod(
  f = "storeAttachment",
  signature = signature("Entity", "missing"),
  definition = function(object){
    storeAttachment(object, object$attachments)
  }
)

setMethod(
  f = "storeAttachment",
  signature = signature("Entity", "character"),
  definition = function(object, which){
    files = file.path(object$attachDir, which)
    for(f in files){
      synapseAttach(object, f)
    }
    object
  }
)

setMethod(
  f = "downloadAttachment",
  signature = signature("Entity", "missing"),
  definition = function(object){
    stop("not implemented")
  }
)


setMethod(
  f = "attachDir",
  signature = signature('Entity'),
  definition = function(object){
    cacheDir(object@attachOwn)
  }
)

setMethod(
  f = "attachments",
  signature = "Entity",
  definition = function(object){
    files(object@attachOwn)
  }
)

setMethod(
  f = "addAttachment",
  signature = signature("Entity", "character"),
  definition = function(object, file){
    if(length(file) != 1L)
      stop("can only attach a single file")
    if(!file.exists(file))
      stop(sprintf("file %s does not exists."), file)
    if(file.info(file)$isdir)
      stop("file must be a regular file.")
    
    addFile(object@attachOwn, file)
    invisible(object)
  }
)

setMethod(
  f = "deleteAttachment",
  signature = signature("Entity", "missing"),
  definition = function(object){
    if(length(object$attachments) == 0L)
      return(object)
    deleteAttachment(object, object$attachements)
  }
)

setMethod(
  f = "deleteAttachment",
  signature = signature("Entity", "character"),
  definition = function(object, file){
    if(any(!(file %in% object$attachments)))
      stop("could not find one or more of the specified attachments")
    
    for(f in file)
      deleteFile(object@attachOwn, f)
    
    invisible(object)
  }
)


##
## Initialize the attachment owner
##
setMethod(
  f = "initialize",
  signature = "Entity",
  definition = function(.Object){
    .Object@attachOwn <- new("AttachmentOwner")
    .Object@attachOwn@fileCache <- getFileCache(.Object@attachOwn@fileCache$getCacheRoot())
    .Object
  }
)


#####
## Entity "show" method
#####
setMethod(
  f = "show",
  signature = signature("Entity"),
  definition = function(object){
    cat('An object of class "', class(object), '"\n', sep="")
    
    cat("Synapse Entity Name : ", properties(object)$name, "\n", sep="")
    cat("Synapse Entity Id   : ", properties(object)$id, "\n", sep="")
    
    if (!is.null(properties(object)$parentId))
      cat("Parent Id     : ", properties(object)$parentId, "\n", sep="")
    if (!is.null(properties(object)$type))
      cat("Type    : ", properties(object)$type, "\n", sep="")
    if (!is.null(properties(object)$versionNumber)) {
      cat("Version Number  : ", properties(object)$versionNumber, "\n", sep="")
      cat("Version ID   : ", properties(object)$versionId, "\n", sep="")
    }
    
    cat("\nFor complete list of annotations, please use the annotations() function.\n")
    
  }
)

# return the metadata (as a list) for the existing entity having the 
# given name and parentId where parentId may be null
# error is thrown if zero or if more than one entity are returned
findExistingEntity<-function(name, parentId=NULL) {
  if (is.null(name)) stop("'name' parameter is required")
  if (is.null(parentId))  parentId<-"syn4489"
  queryString<-sprintf("select id from entity where name==\"%s\" and parentId==\"%s\"", name, parentId)
  result<-synapseQuery(queryString)
  if (is.null(result)) stop(sprintf("Cannot find entity with name %s and parent %s.", name, parentId))
  if (nrow(result)>1) stop(sprintf("Expected one but found %d entities with name %s and parent %s.", nrow(result), name, parentId))
  entityId<-result[1,1]
  synapseGet(.generateEntityUri(entityId))
}

copyProperties<-function(fromEntityAsList, toEntityAsList) {
  propertiesNOTtoTransfer<-c("etag")
  for (propName in names(fromEntityAsList)) {
    if (!any(propName==propertiesNOTtoTransfer)) {
      toEntityAsList[[propName]]<-fromEntityAsList[[propName]]
    }
  }
  toEntityAsList
}

createEntityMethod<-function(entity, generatingActivity, createOrUpdate, forceVersion) {
  if (missing(createOrUpdate)) createOrUpdate<-FALSE
  
  oldAnnots <- entity@annotations
  
  createUri = "/entity"
  if (!is.null(generatingActivity)) {
    if(is.null(propertyValue(generatingActivity, "id"))) {
      generatingActivity <-createEntity(generatingActivity)
    }
    createUri <- sprintf("%s?generatedBy=%s", createUri, propertyValue(generatingActivity, "id"))
  }
  
  entity <- as.list.SimplePropertyOwner(entity)

  if (createOrUpdate) {
    curlHandle=getCurlHandle()
    entityAsList<-synapsePost(createUri, entity, curlHandle=curlHandle, checkHttpStatus=FALSE)
    # is it a 409 response?  If so, the entity already exists
    curlInfo <- .getCurlInfo(curlHandle)
    if (curlInfo$response.code==409) {
      # retrieve the object
      entityAsList<-findExistingEntity(entity$name, entity$parentId)
      # apply the properties of the new entity to the discovered one
      entity<-copyProperties(entity,entityAsList)
      # now update the existing entity
      updateUri<-sprintf("/entity/%s", entity$id)
      if (missing("forceVersion")) forceVersion=FALSE
      # only do the following for versionable entities
      if (forceVersion && any("versionNumber"==names(entity))) {
        updateUri <-sprintf("%s/version", updateUri)
        # make sure the version label changes!
        versionLabel<-entity$versionLabel
        # if the version is the string version of the numeric version field...
        if (!is.null(versionLabel) && !is.null(entity$versionNumber) && entity$versionNumber==versionLabel) {
          # ... then increment it
        entity$versionLabel <- sprintf("%d", 1+as.numeric(versionLabel))
        }
      }
      if (!is.null(generatingActivity)) {
        updateUri<-sprintf("%s?generatedBy=%s", updateUri, propertyValue(generatingActivity, "id"))
      }
      entityAsList<-synapsePut(updateUri, entity)
    } else {
      .checkCurlResponse(curlHandle, toJSON(entityAsList))
    }
  } else {
    entityAsList<-synapsePost(createUri, entity)
  }
  entity <- getEntityInstance(entityAsList)
  # create the entity in Synapse and get back the id
  annots <- getAnnotations(entity$properties$id)
  
  # merge annotations from input variable into 'annots'
  for (n in annotationNames(oldAnnots)) {
    annotValue(annots, n) <- annotValue(oldAnnots, n)
  }
  
  if(length(annotationNames(annots)) > 0L){
    annots <- updateEntity(annots)
    propertyValue(annots, "id") <- entity$properties$id
  }
  entity$properties$etag <- propertyValue(annots, "etag")
  
  ## store the annotations
  entity@annotations <- annots
  entity@generatedBy <- generatingActivity
  
  entity
}

setMethod(
  f = "createEntity",
  signature = "Entity",
  # without the wrapper I get this error in R 2.15: methods can add arguments to the generic ‘createEntity’ only if '...' is an argument to the generic
  definition = function(entity){createEntityMethod(entity=entity, generatingActivity=generatedBy(entity), createOrUpdate=FALSE, forceVersion=FALSE)}
)

setMethod(
    f = "deleteEntity",
    signature = "Entity",
    definition = function(entity){
      envir <- parent.frame(2)
      inherits <- FALSE
      name <- deparse(substitute(entity, env=parent.frame()))

      ## delete the entity in synapse
      if(!is.null(entity$properties$id))
        deleteEntity(entity$properties$id)

      ## remove entity from the cache
      purgeCache(entity)

      ## remove the enity from the parent environment
      if(any(grepl(name,ls(envir=envir))))
        remove(list = name, envir=envir, inherits=inherits)

      ## strip out the system controlled properties and invisibly
      ## return the entity
      entity <- deleteProperty(entity, "id")
      entity <- deleteProperty(entity, "accessControlList")
      entity <- deleteProperty(entity, "uri")
      entity <- deleteProperty(entity, "annotations")
      entity <- deleteProperty(entity, "etag")
      invisible(entity)
    }
)

setMethod(
  f = "getEntity",
  signature = signature("Entity", "missing"),
  definition = function(entity){
    id <- propertyValue(entity, "id")
    if(is.null(id))
      stop("entity id cannot be null")
    
    getEntity(as.character(id))
  }
)

setMethod(
  f = "getEntity",
  signature = signature("Entity", "character"),
  definition = function(entity, versionId){
    getEntity(entity$properties$id, versionId)
  }
)

setMethod(
  f = "getEntity",
  signature = signature("Entity", "numeric"),
  definition = function(entity, versionId){
    getEntity(entity$properties$id, as.character(versionId))
  }
)

updateEntityMethod<-function(entity, newGeneratingActivity, forceVersion)
  {
    if(is.null(entity$properties$id))
      stop("entity ID was null so could not update. use createEntity instead.")
    
    annots <- entity@annotations
    updateUri <- sprintf("/entity/%s", entity$properties$id)
    
    if (missing(forceVersion)) forceVersion=FALSE
    # only do the following for versionable entities
    if (forceVersion && any("versionNumber"==propertyNames(entity))) {
      updateUri <-sprintf("%s/version", updateUri)
      # make sure the version label changes!
      versionLabel<-propertyValue(entity, "versionLabel")
      # if the version is the string version of the numeric version field...
      if (propertyValue(entity,"versionNumber")==versionLabel) {
        # ... then increment it
        propertyValue(entity, "versionLabel") <- sprintf("%d", 1+as.numeric(versionLabel))
      }
    }
    
    if (!is.null(newGeneratingActivity)) {
      if(is.null(propertyValue(newGeneratingActivity, "id"))) {
        newGeneratingActivity <-createEntity(newGeneratingActivity)
      }
      updateUri <- sprintf("%s?generatedBy=%s", updateUri, propertyValue(newGeneratingActivity, "id"))
    }
    
    ee <- getEntityInstance(synapsePut(updateUri, as.list.SimplePropertyOwner(entity)))
    
    propertyValue(annots, "etag") <- ee$properties$etag
    propertyValue(annots, "id") <- ee$properties$id
    propertyValue(annots, "uri") <- ee$properties$annotations
    annots <- updateEntity(annots)
    propertyValue(annots, "id") <- ee$properties$id
    
    ee$properties$etag <- propertyValue(annots, "etag")
    ee@annotations <- annots
    
    # now take care of the 'generatedBy' field
    if (is.null(newGeneratingActivity) && is.null(generatedBy(entity))) {
      # need to ensure the 'generatedBy' field is also cleared on the server side
      # it's unfortunate to have to make another method call to update 'generatedBy' but
      # eventually 'generatedBy' may be part of the entity schema, obviating the need for the extra method call
      synapseDelete(sprintf("/entity/%s/generatedBy", entity$properties$id))
      updatedEtagEntity<-synapseGet(sprintf("/entity/%s", entity$properties$id))
      propertyValue(ee, "etag")<-updatedEtagEntity$etag
    }
    ee@generatedBy<-newGeneratingActivity
    
    ee
}

setMethod(
  f = "updateEntity",
  signature = signature("Entity"),
  definition = function(entity){
    newGeneratingActivity<-NULL
    if (entity@generatedByChanged) newGeneratingActivity<-generatedBy(entity)
    updateEntityMethod(entity=entity, newGeneratingActivity=newGeneratingActivity, forceVersion=FALSE)
  }
)
 
setMethod(
  f = "downloadEntity",
  signature = signature("Entity","missing"),
  definition = function(entity){
    getEntity(entity)
  }
)

setMethod(
  f = "downloadEntity",
  signature = signature("Entity","character"),
  definition = function(entity, versionId){
    getEntity(entity, versionId)
  }
)

setMethod(
  f = "downloadEntity",
  signature = signature("Entity","numeric"),
  definition = function(entity, versionId){
    getEntity(entity, as.character(versionId))
  }
)

setMethod(
  f = "loadEntity",
  signature = signature("Entity","missing"),
  definition = function(entity){
    getEntity(entity)
  }
)

setMethod(
  f = "loadEntity",
  signature = signature("Entity","character"),
  definition = function(entity, versionId){
    getEntity(entity, versionId)
  }
)

setMethod(
  f = "loadEntity",
  signature = signature("Entity","numeric"),
  definition = function(entity, versionId){
    getEntity(entity, as.character(versionId))
  }
)

storeEntityMethod<-function(entity, forceVersion) {
  if (missing(forceVersion)) forceVersion=FALSE
  if (is.null(propertyValue(entity, "id"))) {
    entity <- createEntity(entity)
  }
  else {
    newGeneratingActivity<-NULL
    if (entity@generatedByChanged) newGeneratingActivity<-generatedBy(entity)
    entity <- updateEntityMethod(entity, newGeneratingActivity, forceVersion)
  }
}

setMethod(
  f = "storeEntity",
  signature= signature("Entity"),
  definition = function(entity){storeEntityMethod(entity=entity, forceVersion=FALSE)}
)

#####
## as.list function. Coerce Entity to list by returning annotations
#####
as.list.Entity <- 
  function(x, ...){
  as.list(annotations(x))   
}

#####
## Get annotation names
#####
setMethod(
  f = "annotationNames",
  signature = "Entity",
  definition = function(object){
    annotationNames(annotations(object))
  }
)

#####
## Get annotation values
#####
setMethod(
  f = "annotationValues",
  signature = "Entity",
  definition = function(object){
    annotationValues(annotations(object))
  }
)

#####
## Set the values for multiple annotations
#####
setMethod(
  f = "annotationValues<-",
  signature = signature("Entity","list"),
  definition = function(object, value){
    annotationValues(annotations(object)) <- value
    object
  }
)

setMethod(
  f = "annotValue<-",
  signature = signature("Entity", "character", "ANY"),
  definition = function(object, which, value){
    annotValue(object@annotations, which = which) <- value
    object
  }
)

#####
## return the annotations object 
#####
setMethod(
  f = "annotations",
  signature = "Entity",
  definition = function(object){
    object@annotations
  }
)


setMethod(
    f = "annotations<-",
    signature = signature("Entity", "list"),
    definition = function(object, value){
      if(any(names(value) == ""))
        stop("all elements of the list must be named")
      aa <- SynapseAnnotations(properties(object))
      for(n in names(value)){
            annotValue(aa, n) <- value[[n]]
          }
      annotations(object) <- aa
      object
    }
)

#####
## set the annotations object
#####
setMethod(
  f = "annotations<-",
  signature = signature("Entity","SynapseAnnotations"),
  definition = function(object, value){
    object@annotations <- value
    object
  }
)

#####
## replace annotations with the values
#####
setMethod(
  f = "annotations<-",
  signature = signature("Entity", "list"),
  definition = function(object, value){
    
    a <- new("SynapseAnnotations")
    annotations(a)<-value
    annotations(object) <- a
    object
  }
)

#####
## get an annotation value by name
#####
setMethod(
  f = "annotValue",
  signature = signature("Entity", "character"),
  definition = function(object, which){
    annotValue(annotations(object), which)  
  }
)



#####
## Delete an annotation
#####
setMethod(
  f = "deleteAnnotation",
  signature = signature("Entity", "character"),
  definition = function(object, which){
    annotations(object) <- deleteAnnotation(annotations(object), which)
    object
  }
)

#####
## convert the S4 entity to a list entity
#####
setMethod(
  f = ".extractEntityFromSlots",
  signature = "Entity",
  definition = function(object){
    properties(object)
  }
)

#####
## convert the list entity to an S4 entity
#####
setMethod(
  f = ".populateSlotsFromEntity",
  signature = signature("Entity", "list"),
  definition = function(object, entity){
    if(any(names(entity) == "") && length(entity) > 0)
      stop("All elements of the entity must be named")
    
    ## all entity fields should be stored as properties
    for(name in names(entity))
      propertyValue(object, name) <- entity[[name]]
    object
  }
)

#####
## Get the Synapse entity kind
#####
setMethod(
  f = "synapseEntityKind",
  signature = "Entity",
  definition = function(entity){
    entity@synapseEntityKind
  }
)

#####
## Set the entity kind
#####
setMethod(
  f = "synapseEntityKind<-",
  signature = "Entity",
  definition = function(entity, value){
    entity@synapseEntityKind <- value
    entity
  }
)

#####
## Refresh the entities annotations
#####
setMethod(
  f = "refreshAnnotations",
  signature = "Entity",
  definition = function(entity){
    #  MF will refactor this code
    annotations(entity) <- do.call(class(annotations(entity)), list(entity = getAnnotations(.extractEntityFromSlots(entity))))
    entity
  }   
)

setMethod(
  f = "getAnnotations",
  signature = "Entity",
  definition = function(entity){
    as.list(entity@annotations)
  }
)

names.Entity <-
  function(x)
{
  c("properties", "annotations", "attachments", "attachDir", "available.versions")
}

setMethod(
  f = "[",
  signature = "Entity",
  definition = function(x, i, j, ...){
    if(length(as.character(as.list(substitute(list(...)))[-1L])) > 0L || !missing(j))
      stop("incorrect number of subscripts")
    if(is.numeric(i)){
      if(any(i > length(names(x))))
        stop("subscript out of bounds")
      i <- names(x)[i]
    }else if(is.character(i)){
      if(!all(i %in% names(x)))
        stop("undefined objects selected")
    }else{
      stop(sprintf("invalid subscript type '%s'", class(i)))
    }
    retVal <- lapply(i, function(i){
        if(i == "attachDir"){
          retVal <- attachDir(x)
        }else if(i == "attachments"){
          attachments(x)
        } else if(i == "available.versions"){
          if(is.null(x$properties$id)){
            retVal <- NULL
          }else{
            retVal <- available.versions(x$properties$id)
          }
        } else if(i %in% names(x)){
          retVal <- slot(x, i)
        }else{
          retVal <- NULL
        }
      }
    )
    names(retVal) <- i
    retVal
  }
)

setMethod(
  f = "[[",
  signature = "Entity",
  definition = function(x, i, j, ...){
    if(length(as.character(as.list(substitute(list(...)))[-1L])) > 0L || !missing(j))
      stop("incorrect number of subscripts")
    if(length(i) > 1)
      stop("subscript out of bounds")
    x[i][[1]]
  }
)

setMethod(
  f = "$",
  signature = "Entity",
  definition = function(x, name){
    x[[name]]
  }
)

setReplaceMethod("$", 
  signature = "Entity",
  definition = function(x, name, value) {
    if(!(name %in% names(x)))
      stop("invalid element")
    slot(x, name) <- value
    x
  }
)

setMethod(
  f = "getAnnotations",
  signature = "Entity",
  definition = function(entity){
    id <- entity$properties$id
    if(is.null(id))
      stop("entity id cannot be null")
    getAnnotations(id)
  }
)

setMethod(
  f = "purgeCache",
  signature = "Entity",
  definition = function(entity){
    ##warning('not implemented')
  }
)

setMethod(
  f = "generatedBy",
  signature = "Entity",
  definition = function(entity){
    entity@generatedBy
  }
)

setMethod(
  f = "generatedBy<-",
  signature = signature("Entity", "Activity"),
  definition = function(entity, value) {
    entity@generatedBy <- value
    entity@generatedByChanged <- TRUE
    entity
  }
)

setMethod(
  f = "generatedBy<-",
  signature = signature("Entity", "NULL"),
  definition = function(entity, value) {
    entity@generatedBy <- NULL
    entity@generatedByChanged <- TRUE
    entity
  }

)

setMethod(
  f = "used",
  signature = "Entity",
  definition = function(entity){
    activity <- generatedBy(entity)
    if (is.null(activity)) {
      return(NULL)
    }
    used(activity)
  }
)

entitySetUsedMethod<-function(entity, value) {
  activity <- generatedBy(entity)
  if (is.null(activity)) {
    activity <- new("Activity")
  } 
  used(activity)<-value
  generatedBy(entity)<-activity
  entity
}

setMethod(
  f = "used<-",
  signature = signature("Entity", "list"),
  definition = function(entity, value) {
    entitySetUsedMethod(entity, value)
  }
)

setMethod(
  f = "used<-",
  signature = signature("Entity", "character"),
  definition = function(entity, value) {
    entitySetUsedMethod(entity, value)
  }
)

setMethod(
  f = "used<-",
  signature = signature("Entity", "Entity"),
  definition = function(entity, value) {
    entitySetUsedMethod(entity, value)
  }
)

setMethod(
  f = "used<-",
  signature = signature("Entity", "NULL"),
  definition = function(entity, value) {
    generatedBy(entity)<-NULL
    entity
  }
)

setMethod(
  f = "executed",
  signature = "Entity",
  definition = function(entity){
    activity <- generatedBy(entity)
    if (is.null(activity)) {
      return(NULL)
    }
    executed(activity)
  }
)

entitySetExcecutedMethod<-function(entity, value) {
  activity <- generatedBy(entity)
  if (is.null(activity)) {
    activity <- new("Activity")
  } 
  executed(activity)<-value
  generatedBy(entity)<-activity
  entity
}

setMethod(
  f = "executed<-",
  signature = signature("Entity", "list"),
  definition = function(entity, value) {
    entitySetExcecutedMethod(entity, value)
  }
)

setMethod(
  f = "executed<-",
  signature = signature("Entity", "character"),
  definition = function(entity, value) {
    entitySetExcecutedMethod(entity, value)
  }
)

setMethod(
  f = "executed<-",
  signature = signature("Entity", "Entity"),
  definition = function(entity, value) {
    entitySetExcecutedMethod(entity, value)
  }
)

setMethod(
  f = "executed<-",
  signature = signature("Entity", "NULL"),
  definition = function(entity, value) {
    generatedBy(entity)<-NULL
    entity
  }
)



