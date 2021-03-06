### Test CRUD operations for S4 entities
### 
### Author: Matthew D. Furia <matt.furia@sagebase.org>
################################################################################ 

.setUp <-
		function()
{
	activity<-Activity(list(name="test activity"))
	activity<-createEntity(activity)
	synapseClient:::.setCache("testActivity", activity)
}

.tearDown <- 
  function()
{
	if(!is.null(synapseClient:::.getCache("testActivity"))) {
		try(deleteEntity(synapseClient:::.getCache("testActivity")))
		synapseClient:::.deleteCache("testActivity")
	}
	if(!is.null(synapseClient:::.getCache("testProject"))) {
		try(deleteEntity(synapseClient:::.getCache("testProject")))
		synapseClient:::.deleteCache("testProject")
	}
	if(!is.null(synapseClient:::.getCache("testProject2"))) {
		try(deleteEntity(synapseClient:::.getCache("testProject2")))
		synapseClient:::.deleteCache("testProject2")
	}
}

integrationTestCreateS4Entities <- 
  function()
{
  ## Create Project
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  ## Create Study
  study <- Study()
  propertyValue(study, "name") <- "testStudyName"
  propertyValue(study,"parentId") <- propertyValue(createdProject, "id")
  createdStudy <- createEntity(study)
  checkEquals(propertyValue(createdStudy,"name"), propertyValue(study, "name"))
  checkEquals(propertyValue(createdStudy,"parentId"), propertyValue(createdProject, "id"))
  study <- createdStudy
  
  ## Create Data
  data <- Data()
  propertyValue(data, "name") <- "testPhenoDataName"
  propertyValue(data, "parentId") <- propertyValue(study,"id")
  createdData <- createEntity(data)
  checkEquals(propertyValue(createdData,"name"), propertyValue(data, "name"))
  checkEquals(propertyValue(createdData,"parentId"), propertyValue(study, "id")) 
  
}

integrationTestCreateEntityWithAnnotations <- 
		function()
{
	## Create Project
	project <- Project()
	annotValue(project, "annotationKey") <- "projectAnnotationValue"
	createdProject <- createEntity(project)
	synapseClient:::.setCache("testProject", createdProject)
	checkEquals(annotValue(createdProject, "annotationKey"), annotValue(project, "annotationKey"))
	
	## Create Study
	study <- Study()
	propertyValue(study, "name") <- "testStudyName"
	propertyValue(study,"parentId") <- propertyValue(createdProject, "id")
	annotValue(study, "annotKey") <- "annotValue"
	createdStudy <- createEntity(study)
	checkEquals(propertyValue(createdStudy,"name"), propertyValue(study, "name"))
	checkEquals(propertyValue(createdStudy,"parentId"), propertyValue(createdProject, "id"))
	checkEquals(annotValue(createdStudy,"annotKey"), annotValue(study, "annotKey"))
	checkEquals(NULL, generatedBy(createdStudy))
	
}

integrationTestCreateEntityWithGeneratedBy <- 
  function()
{
  ## Create Project
  project <- Project()
  annotValue(project, "annotationKey") <- "projectAnnotationValue"
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  checkEquals(annotValue(createdProject, "annotationKey"), annotValue(project, "annotationKey"))
  
  ## Create Data
  data <- Data()
  propertyValue(data, "name") <- "testDataName"
  propertyValue(data,"parentId") <- propertyValue(createdProject, "id")
  testActivity <-synapseClient:::.getCache("testActivity")
  checkTrue(!is.null(testActivity))
  generatedBy(data)<-testActivity
  data <- createEntity(data)
  createdData<-getEntity(propertyValue(data, "id"))
  checkEquals(propertyValue(createdData,"name"), propertyValue(data, "name"))
  checkEquals(propertyValue(createdData,"parentId"), propertyValue(createdProject, "id"))
  checkTrue(!is.null(generatedBy(createdData)))
  checkEquals(propertyValue(testActivity,"id"), propertyValue(generatedBy(createdData), "id"))
}

integrationTestUpdateEntityWithGeneratedBy <- 
  function()
{
  ## Create Project
  project <- Project()
  annotValue(project, "annotationKey") <- "projectAnnotationValue"
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  checkEquals(annotValue(createdProject, "annotationKey"), annotValue(project, "annotationKey"))
  
  ## Create Data
  data <- Data()
  propertyValue(data, "name") <- "testDataName"
  propertyValue(data,"parentId") <- propertyValue(createdProject, "id")
  data <- createEntity(data)
  testActivity <-synapseClient:::.getCache("testActivity")
  checkTrue(!is.null(testActivity))
  generatedBy(data)<-testActivity
  data <- updateEntity(data)
  updatedData<-getEntity(propertyValue(data, "id"))
  checkEquals(propertyValue(updatedData,"name"), propertyValue(data, "name"))
  checkEquals(propertyValue(updatedData,"parentId"), propertyValue(createdProject, "id"))
  checkTrue(!is.null(generatedBy(updatedData)))
  checkEquals(propertyValue(testActivity,"id"), propertyValue(generatedBy(updatedData), "id"))
}

integrationTestStoreEntityWithGeneratedBy <- 
  function()
{
  ## Create Project
  project <- Project()
  annotValue(project, "annotationKey") <- "projectAnnotationValue"
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  checkEquals(annotValue(createdProject, "annotationKey"), annotValue(project, "annotationKey"))
  
  ## Create Data
  data <- Data()
  propertyValue(data, "name") <- "testDataName"
  propertyValue(data,"parentId") <- propertyValue(createdProject, "id")
  data <- createEntity(data)
  testActivity <-synapseClient:::.getCache("testActivity")
  checkTrue(!is.null(testActivity))
  generatedBy(data)<-testActivity
  data <- storeEntity(data)
  updatedData<-getEntity(propertyValue(data, "id"))
  checkEquals(propertyValue(updatedData,"name"), propertyValue(data, "name"))
  checkEquals(propertyValue(updatedData,"parentId"), propertyValue(createdProject, "id"))
  checkTrue(!is.null(generatedBy(updatedData)))
  checkEquals(propertyValue(testActivity,"id"), propertyValue(generatedBy(updatedData), "id"))
}

integrationTestCreateEntityWithNAAnnotations <- 
  function()
{
  ## Create Project
  project <- Project()
  annotValue(project, "annotationKey") <- "projectAnnotationValue"
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  checkEquals(annotValue(createdProject, "annotationKey"), annotValue(project, "annotationKey"))
  
  ## Create Study
  study <- Study()
  propertyValue(study, "name") <- "testStudyName"
  propertyValue(study,"parentId") <- propertyValue(createdProject, "id")
  
  annots <- list()
  annots$rawdataavailable <- TRUE 
  annots$number_of_samples <- 33 
  annots$contact <- NA 
  annots$platform <- "HG-U133_Plus_2"
  annotationValues(study) <- annots
  
  createdStudy <- createEntity(study)
  
  checkEquals(propertyValue(createdStudy,"name"), propertyValue(study, "name"))
  checkEquals(propertyValue(createdStudy,"parentId"), propertyValue(createdProject, "id"))
  checkEquals(annotValue(createdStudy,"platform"), "HG-U133_Plus_2")
  checkEquals(annotValue(createdStudy,"number_of_samples"), 33)
  checkEquals(annotValue(createdStudy,"rawdataavailable"), "TRUE")
  checkTrue(is.null(annotValue(createdStudy,"contact")[[1]]))
}

integrationTestUpdateS4Entity <-
  function()
{
  ## Create Project
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  ## set an annotation value and update. 
  annotValue(createdProject, "newKey") <- "newValue"
  updatedProject <- updateEntity(createdProject)
  checkEquals(propertyValue(updatedProject,"id"), propertyValue(createdProject,"id"))
  checkTrue(propertyValue(updatedProject, "etag") != propertyValue(createdProject, "etag"))
  
  ## create a study
  study <- Study()
  propertyValue(study, "name") <- "testStudyName"
  propertyValue(study,"parentId") <- propertyValue(createdProject, "id")
  createdStudy <- createEntity(study)
  
  ## update the study annotations
  annotValue(createdStudy, "newKey") <- "newValue"
  updatedStudy <- updateEntity(createdStudy)
  checkEquals(annotValue(createdStudy, "newKey"), annotValue(updatedStudy, "newKey"))
  checkTrue(propertyValue(createdStudy, "etag") != propertyValue(updatedStudy, "etag"))
  checkEquals(propertyValue(createdStudy, "id"), propertyValue(updatedStudy, "id"))
  
  ## create a data
  data <- Data()
  propertyValue(data, "name") <- "testPhenoDataName"
  propertyValue(data, "parentId") <- propertyValue(createdStudy,"id")
  createdData <- createEntity(data)
  checkEquals(propertyValue(createdData,"name"), propertyValue(data,"name"))
  
  
  ## update the description property
  propertyValue(createdData, "description") <- "This is a description"
  updatedData <- updateEntity(createdData)
  checkEquals(propertyValue(createdData, "description"), propertyValue(updatedData, "description"))
  
  ## update the description property on a project
  createdProject <- getEntity(createdProject)
  propertyValue(createdProject, "description") <- "This is a new description"
  updatedProject <- updateEntity(createdProject)
  checkEquals(propertyValue(createdProject, "description"), propertyValue(updatedProject, "description"))
  
}

integrationTestDeleteEntityById <-
  function()
{
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  study <- Study()
  propertyValue(study, "name") <- "testStudyName"
  propertyValue(study,"parentId") <- propertyValue(createdProject, "id")
  createdStudy <- createEntity(study)
  createdData <- Data(list(name="aData", type="C", parentId=propertyValue(createdStudy, "id")))
  data <- addObject(createdData, "foo", "bar")
  createdData <- storeEntity(createdData)
  
  cacheDir <- createdData$cacheDir
  checkTrue(file.exists(cacheDir))
  synDelete(createdData)
  checkTrue(!file.exists(cacheDir))
  
  
  synDelete(createdProject$properties$id)
  checkException(getEntity(createdStudy))
  checkException(getEntity(createdProject))
  synapseClient:::.deleteCache("testProject")
}

createFile<-function(content, filePath) {
  if (missing(content)) content<-"this is a test"
  if (missing(filePath)) filePath<- tempfile()
  connection<-file(filePath)
  writeChar(content, connection, eos=NULL)
  close(connection)  
  filePath
}

integrationTestSYNR580<-function() {
  ## Create Project
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  testActivity <-synapseClient:::.getCache("testActivity")
  genF <- File(path=createFile(), parentId=propertyValue(createdProject, "id"))
  generatedBy(genF) <- testActivity
  genF <- synStore(genF)
  checkTrue(!is.null(generatedBy(genF)))
}

integrationTestUpdateS4EntityWithGeneratedBy <-
		function()
{
	## Create Project
	project <- Project()
	createdProject <- createEntity(project)
	synapseClient:::.setCache("testProject", createdProject)
	
	## set generatedBy and update. 
	testActivity <-synapseClient:::.getCache("testActivity")
	checkTrue(!is.null(testActivity))
	generatedBy(createdProject) <- testActivity
	updatedProject <- updateEntity(createdProject)
	testActivity <- generatedBy(updatedProject)
	# since storing the entity also stores the activity, we need to update the cached value
	synapseClient:::.setCache("testActivity", testActivity)
	checkEquals(propertyValue(testActivity, "id"), propertyValue(generatedBy(updatedProject), "id"))
	checkTrue(propertyValue(updatedProject, "etag") != propertyValue(createdProject, "etag"))

  #  get the entity by ID and verify that the generatedBy is not null
  gotProject <- getEntity(propertyValue(createdProject, "id"))
  checkTrue(!is.null(gotProject))
  checkTrue(!is.null(generatedBy(gotProject)))
  
	## remove generatedBy and update
	createdProject<-updatedProject
	generatedBy(createdProject) <- NULL
	updatedProject <- updateEntity(createdProject)
	checkTrue(is.null(generatedBy(updatedProject)))
	
	## now *create* an Entity having a generatedBy initially
	deleteEntity(synapseClient:::.getCache("testProject"))	
	synapseClient:::.deleteCache("testProject")
	project <- Project()
	generatedBy(project) <- testActivity
	createdProject <- createEntity(project)
	checkTrue(!is.null(generatedBy(createdProject)))
	synapseClient:::.setCache("testProject", createdProject)
	testActivity <- generatedBy(createdProject)
	# since storing the entity also stores the activity, we need to update the cached value
	synapseClient:::.setCache("testActivity", testActivity)
	
  #  get the entity by ID and verify that the generatedBy is not null
  gotProject <- getEntity(propertyValue(createdProject, "id"))
  checkTrue(!is.null(gotProject))
  checkTrue(!is.null(generatedBy(gotProject)))
  
  ## remove generatedBy and update
	generatedBy(createdProject)<-NULL
	updatedProject <- updateEntity(createdProject)
	checkTrue(is.null(generatedBy(updatedProject)))
	
}
# a variation of the previous test, using the 'used' convenience function
integrationTestUpdateS4EntityWithUsed <-
		function()
{
	## Create Project
	project <- Project()
	createdProject <- createEntity(project)
	synapseClient:::.setCache("testProject", createdProject)
	
	project2 <- Project()
	createdProject2 <- createEntity(project2)
	synapseClient:::.setCache("testProject2", createdProject2)
	
	checkTrue(is.null(used(createdProject)))
	## 2nd project was 'used' to generate 1st project
	used(createdProject)<-list(createdProject2)
	updatedProject <- updateEntity(createdProject)
	checkTrue(propertyValue(updatedProject, "etag") != propertyValue(createdProject, "etag"))
	usedList<-used(updatedProject)
	checkTrue(!is.null(usedList))
	checkEquals(1, length(usedList))
	targetId<-usedList[[1]]$reference$targetId
	names(targetId)<-NULL # needed to make the following check work
	checkEquals(propertyValue(createdProject2, "id"), targetId)
	
	## remove "used" list and update
	createdProject<-updatedProject
	used(createdProject) <- NULL
	updatedProject <- updateEntity(createdProject)
	checkTrue(is.null(used(updatedProject)))
	
	## now *create* an Entity having a "used" list initially
	deleteEntity(synapseClient:::.getCache("testProject"))	
	synapseClient:::.deleteCache("testProject")
	project <- Project()
	used(project)<-list(list(entity=createdProject2, wasExecuted=F))
	
	createdProject <- createEntity(project)
	synapseClient:::.setCache("testProject", createdProject)
	usedList2 <- used(createdProject)
	checkTrue(!is.null(usedList2))
	checkEquals(1, length(usedList2))
	targetId<-usedList2[[1]]$reference$targetId
	names(targetId)<-NULL # needed to make the following check work
	checkEquals(propertyValue(createdProject2, "id"), targetId)
	checkEquals(F, usedList2[[1]]$wasExecuted)
	
	## remove "used" list and update
	used(createdProject)<-NULL
	updatedProject <- updateEntity(createdProject)
	checkTrue(is.null(used(updatedProject)))
}

# this is the test to show that SYNR-327 is fixed
# use the same activity in two different entities
integrationTestTwoEntitiesOneActivity<-function() {
  ## Create Project
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  pid<-propertyValue(createdProject, "id")
  foo<-Folder(name="foo", parentId=pid)
  foo<-storeEntity(foo)
  bar<-Folder(name="bar", parentId=pid)
  bar<-storeEntity(bar)
  
  activity<-Activity(list(name="foobarActivity"))
  activity<-storeEntity(activity)

  generatedBy(foo)<-activity
  generatedBy(bar)<-activity
  foo<-storeEntity(foo)
  bar<-storeEntity(bar) 
}

integrationTestDeleteEntity <- 
  function()
{
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  study <- Study()
  propertyValue(study, "name") <- "testStudyName"
  propertyValue(study,"parentId") <- propertyValue(createdProject, "id")
  createdStudy <- createEntity(study)
  createdData <- Data(list(name="aData", type="C", parentId=propertyValue(createdStudy, "id")))
  data <- addObject(createdData, "foo", "bar")
  createdData <- storeEntity(createdData)
  
  cacheDir <- createdData$cacheDir
  checkTrue(file.exists(cacheDir))
  deleteEntity(createdData)
  checkTrue(!file.exists(cacheDir))
  
  
  deletedProject <- deleteEntity(createdProject)
  checkEquals(propertyValue(deletedProject, "id"), NULL)
  
  ## need to fix this
  ##checkTrue(!any(grepl('createdProject', ls())))
  createdProject <- synapseClient:::.getCache("testProject")
  checkEquals(propertyValue(deletedProject,"id"), NULL)
  
  checkException(getEntity(createdStudy))
  checkException(getEntity(createdProject))
  synapseClient:::.deleteCache("testProject")
}

integrationTestGetEntity <-
  function()
{
  ## Create Project
  project <- Project()
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  fetchedProject <- getEntity(propertyValue(createdProject, "id"))
  checkEquals(propertyValue(fetchedProject, "id"), propertyValue(createdProject, "id"))
  
  fetchedProject <- getEntity(as.character(propertyValue(createdProject, "id")))
  checkEquals(propertyValue(fetchedProject, "id"), propertyValue(createdProject, "id"))
  
  fetchedProject <- getEntity(synapseClient:::.extractEntityFromSlots(createdProject))
  checkEquals(propertyValue(fetchedProject, "id"), propertyValue(createdProject, "id"))
  
  fetchedProject <- getEntity(createdProject)
  checkEquals(propertyValue(fetchedProject, "id"), propertyValue(createdProject, "id"))
}

integrationTestReplaceAnnotations <- 
  function()
{
  # fix this test
  ## Create Project
  project <- Project()
  annotations(project) <- list(annotation1="value1", annotation2="value2")
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  
  annotations(createdProject) <- list(annotation3="value3", annotation4="value4", annotation5="value5")
  createdProject <- updateEntity(createdProject)
  
  checkEquals(length(annotationNames(createdProject)), 3L)
  checkTrue(all(c("annotation3", "annotation4", "annotation5") %in% annotationNames(createdProject)))
}

integrationTestFindExistingEntity <- function(){
  ## Create Project, append a random integer to make it unique
  projectName<-sprintf("integrationTestFindExistingEntity_%d", sample(1000,1))
  project <- Project(name=projectName)
  createdProject <- createEntity(project)
  synapseClient:::.setCache("testProject", createdProject)
  pid<-propertyValue(createdProject, "id")
  
  folder<-Folder(name="testName", parentId=pid)
  folder<-synStore(folder)
  
  result<-synapseClient:::findExistingEntity(projectName)
  checkEquals(pid, result$id)
  
  result<-synapseClient:::findExistingEntity(name="testName", parentId=pid)
  checkEquals(propertyValue(folder, "id"), result$id)
  
}

