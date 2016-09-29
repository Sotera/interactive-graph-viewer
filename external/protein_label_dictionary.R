
appendlabel<-function(x){
  if(!is.null(mp[[x]]))
  {
    print(x)
    lbllist<<-append(lbllist,mp[[x]])
    
    lbl<-strsplit(mp[[x]],split=" ")
    lapply(lbl,function(y){new<-data.frame(Pathway=y,Protein=x);protienDSpathway<<-rbind(protienDSpathway,new)})
    
    
  }
  
}



getallparentforentity<-function(entityname,first=TRUE){
  
  con <- file("./www/data/database.json")
  open(con)
  matchexp=""
  if(first==TRUE){
    matchexp <- paste0("\"name\": \"", entityname, "\"",sep="")
  }
  else
  {
    matchexp <- paste0("\"comm_id\": ", entityname, ",", sep="")
  }
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
    if((grepl(matchexp,line,fixed=TRUE))==TRUE){
      jsobj <- fromJSON(line)
      
      if(names(jsobj)!= "-1"){
        id = as.numeric(names(jsobj)) 
        getallparentforentity(toString(id),FALSE)
        print(id)
        lbllist<<-append(lbllist,toString(id))
      }
    }
  }
  
  close(con)
}


getrawentititesfromComm<-function(id,con=NULL){
  
  #print(id)
  con <- file("./www/data/database.json")
  open(con)
  matchexp <- paste0("{\"", id,"\":",sep="")
  
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
    if((grepl(matchexp,line,fixed=TRUE))==TRUE){
      pos = regexpr(matchexp, line,fixed=TRUE)
      writesubsr = substr(line,attr(pos,"match.length") + 1,nchar(line) -1)
      jsobj <- fromJSON(writesubsr)
      if(jsobj$nodes$type[1] == "Community"){
        lapply(jsobj$nodes$label,getrawentititesfromComm,con)
      }
      else{
        lapply(jsobj$nodes$name,appendlabel )
        
      }
      
    }
    
  }
  close(con)
}




getmax<-function(t){
  
  return(names(t)[which.max(t)])
}

len=function(x) {
  z <- unlist(x)
  getmap<-function(y){
    vl<-unlist(y)
    return(mp[[vl]])
  }
  return(lapply(z, getmap))
  
}

getpie<- function(x){
  if(nrow(x) ==0){
    return(NULL)
  }
  else
  {
    return(pie(x))
  } 
  
}

getproteinlabeldict <- function(){ 
  con <- file("./www/data/GESA_Canonical_pathways_c2.cp.v5.0.symbols.gmt_filtered.tsv") 
  open(con);
  results.list <- list();
  current.line <- 1
  map <- new.env(hash=T, parent=emptyenv())
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
    
    dt <- strsplit(line, split="\t")
    val<-unlist(dt[[1]][1])
    keys<-unlist(dt[[1]][-1])
    for(key in keys){
      if(key %in% names(map)){
        oldval <- map[[key]]
        map[[key]] <- paste(oldval,val,sep=" ") 
      }
      else
      {
        map[[key]] <- val
      }
    }
    
    #results.list[[current.line]] <- toString(unlist(strsplit(line, split="\t")))
    current.line <- current.line + 1
  } 
  close(con)
  
  return(map)
}
