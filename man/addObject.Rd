\name{addObject}
\alias{addObject}
\alias{deleteObject}
\alias{getObject}
\alias{listObjects}
\alias{renameObject}
\title{
Manipulate Objects held by an Entity
}
\description{
Functions for manipulating R objects held by an entity.
}
\usage{
addObject(owner, object, name, unlist)
deleteObject(owner, which)
getObject(owner, which)
listObjects(owner)
renameObject(owner, which, name)
}
\arguments{
  \item{owner}{
The entity to be modified
}
  \item{object}{
The object to be added or renamed
}
  \item{name}{
optional argument specifying the to be given to the object. Defaults to the name of the object when passed as an argument.
}
  \item{unlist}{
  		boolean indicating whether list objects should be added as a single object (unlist = TRUE) or as one object for each named element (unlist=FALSE)
}
\item{which}{
the name of the object to be deleted or returned.
}
}
\details{
getObject(owner) (omitting 'which'), for an entity having just one object, will return that object. 

It is important to note that the objects held by an entity are stored in an environment. In R environments are passed by reference. So, if 
you make multiple copies of an entity, any modifications made to the objects held by one copy of the entity will be propagated to all copies
of that entity. use \code{\link{copyEntity}} to prevent this. 

Another implication of using environments is that it is not technically necessary to catch the return value from these functions. However, it
may help the clarity of your code to do so.
}
\value{
The modified owner (invisibly)
}

\author{
Matt Furia
}

\seealso{
\code{\link{addFile}}
\code{\link{copyEntity}}

}

