#######################################################
## Organize data frame with all stations in a specific time period
## Created by: Lizeth Llanos
## March 2017
#######################################################


###################################
#---------Daily data--------------#
###################################
organize_data = function(inDir,outDir,rutCat,variable,time_period,inst=NULL){
 
  rutOrigen = paste0(inDir,variable,"-per-station/")
    
  files <-list.files(rutOrigen,pattern="\\.txt$")
  nom.files<-substring(files,1,nchar(files)-13)
  
  idstation = read.csv(rutCat,header=T) #Cargar base con c�digo y nombre de la estaci�n
  names(idstation) = tolower(names(idstation))
  idstation = idstation[which(idstation$variable==variable),]
  if(!is.null(inst)){ 
       idstation = idstation[which(idstation$operator==inst),]
    }
   
  cod=as.character(idstation$national_code)
  # not_f = which(is.na(cod))
  # cod = cod[-not_f]
  
  where <- match(cod,nom.files)
  station_find=nom.files[where[which(!is.na(where))]]
  station_find_n=paste0(cod[which(!is.na(where))],"_",idstation[which(!is.na(where)),"name_station"])
  
   #Definir periodo que se desea analizar
  
  fechas=format(time_period,"%Y%m%d")
  fechas=cbind.data.frame("Date"=fechas,"NA")
  
  cat("Leyendo datos para cada estaci�n de ",variable,"... \n")
  Datos <- lapply(paste(rutOrigen,cod[which(!is.na(where))],"_raw_",variable,".txt",sep=""),function(x){read.table(x,header=T,sep="\t")})
  
  datos_to=as.data.frame(matrix(NA,nrow(fechas),length(Datos)))
  
  
  cat("Organizando todos los datos en un solo archivo... \n")
  for(j in 1:length(Datos)) {  
    
    old=na.omit(Datos[[j]])
    if(nrow(old)!=0){
      combnew=old[!duplicated(old[,1]),]
    }else{
      combnew = old
    }
    
    
    final=merge(fechas,combnew,by="Date",all.x=T)
    #if(nrow(final)==nrow(datosprecip)){
    datos_to[,j]=final[,3]
    #}
    
  }
  
  year=as.numeric(substr(fechas[,1],1,4))
  month=as.numeric(substr(fechas[,1],5,6))
  day=as.numeric(substr(fechas[,1],7,8))
  
  datos_fin=cbind(day,month,year,datos_to)
  
  names(datos_fin)=c("day","month","year",as.character(station_find_n))
  
  cat("Escribiendo datos en .csv... \n")
  #Se guardan los archivos en formato .csv con la info organizada
  write.csv(datos_fin,paste(outDir,"/daily_processed/",variable,"_daily_raw.csv",sep=""),row.names=F)
  cat("Proceso finalizado! \n")
}


##Run para datos DGRH
variable = c("tmax","tmin")

inDir = "X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_raw/"
outDir ="X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_raw/" 
rutCat = "X:/Water_Planning_System/01_weather_stations/catalog_daily.csv"

dir.create(paste0(outDir,"daily_processed"),showWarnings = F)

time_period=seq(as.Date("1970/1/1"), as.Date("2017/12/31"), "days")


for(j in 1:length(variable)) organize_data(inDir,outDir,rutCat,variable[j],time_period)

##Run para datos ENEE
variable = c("prec","tmax","tmin")

inDir = "X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_raw/"
outDir ="X:/Water_Planning_System/01_weather_stations/hnd_enee/" 
rutCat = "X:/Water_Planning_System/01_weather_stations/catalog_daily.csv"
dir.create(paste0(outDir,"daily_processed"),showWarnings = F)

time_period=seq(as.Date("1990/1/1"), as.Date("2016/12/31"), "days")

j=1
organize_data(inDir,outDir,rutCat,variable[j],time_period,inst="ENEE")



##Run para datos COPECO

organize_data_cop = function(inDir,outDir,rutCat,variable,time_period,inst=NULL){
  
  rutOrigen = paste0(inDir,variable,"-per-station/")
  
  files <-list.files(rutOrigen,pattern="\\.txt$")
  nom.files<-substring(files,1,nchar(files)-13)
  
  idstation = read.csv(rutCat,header=T) #Cargar base con c�digo y nombre de la estaci�n
  names(idstation) = tolower(names(idstation))
  if(variable== "tmax" | variable== "tmin"){
     idstation = idstation[which(idstation$tmax=="si"),]
 
  }
  
  if(!is.null(inst)){ 
    idstation = idstation[which(idstation$operator==inst),]
  }
  
  cod=as.character(idstation$national_code)
  # not_f = which(is.na(cod))
  # cod = cod[-not_f]
  
  where <- match(cod,nom.files)
  station_find=nom.files[where[which(!is.na(where))]]
  station_find_n=paste0(cod[which(!is.na(where))],"_",idstation[which(!is.na(where)),"name_station"])
  
  #Definir periodo que se desea analizar
  
  fechas=format(time_period,"%Y%m%d")
  fechas=cbind.data.frame("Date"=fechas,"NA")
  
  cat("Leyendo datos para cada estaci�n de ",variable,"... \n")
  Datos <- lapply(paste(rutOrigen,cod[which(!is.na(where))],"_raw_",variable,".txt",sep=""),function(x){read.table(x,header=T,sep=" ")})
  
  datos_to=as.data.frame(matrix(NA,nrow(fechas),length(Datos)))
  
  
  cat("Organizando todos los datos en un solo archivo... \n")
  for(j in 1:length(Datos)) {  
    
    old=na.omit(Datos[[j]])
    if(nrow(old)!=0){
      combnew=old[!duplicated(old[,1]),]
    }else{
      combnew = old
    }
    
    
    final=merge(fechas,combnew,by="Date",all.x=T)
    #if(nrow(final)==nrow(datosprecip)){
    datos_to[,j]=final[,3]
    #}
    
  }
  
  year=as.numeric(substr(fechas[,1],1,4))
  month=as.numeric(substr(fechas[,1],5,6))
  day=as.numeric(substr(fechas[,1],7,8))
  
  datos_fin=cbind(day,month,year,datos_to)
  
  names(datos_fin)=c("day","month","year",as.character(station_find_n))
  
  cat("Escribiendo datos en .csv... \n")
  #Se guardan los archivos en formato .csv con la info organizada
  write.csv(datos_fin,paste(outDir,"/daily_processed/",variable,"_daily_raw.csv",sep=""),row.names=F)
  cat("Proceso finalizado! \n")
}



variable = c("prec","tmax","tmin")

inDir = "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/"
outDir ="Z:/Water_Planning_System/01_weather_stations/hnd_copeco/" 
rutCat = "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_raw/_primary_files/coordenadas.csv"
dir.create(paste0(outDir,"daily_processed"),showWarnings = F)

time_period=seq(as.Date("1981/1/1"), as.Date("2017/12/31"), "month")


for(j in 1:3) organize_data_cop(inDir,outDir,rutCat,variable[j],time_period,inst=NULL)


##Run para datos SANAA

organize_data_cop = function(inDir,outDir,rutCat,variable,time_period,inst=NULL){
  
  rutOrigen = paste0(inDir,variable,"-per-station/")
  
  files <-list.files(rutOrigen,pattern="\\.txt$")
  nom.files<-substring(files,1,nchar(files)-13)
  
  idstation = read.csv(rutCat,header=T) #Cargar base con c�digo y nombre de la estaci�n
  names(idstation) = tolower(names(idstation))
  idstation = idstation[which(idstation$variable==variable),] 
  
  if(!is.null(inst)){ 
    idstation = idstation[which(idstation$operator==inst),]
  }
  
  cod=idstation$code
  # not_f = which(is.na(cod))
  # cod = cod[-not_f]
  
  where <- match(cod,nom.files)
  station_find=nom.files[where[which(!is.na(where))]]
  station_find_n=paste0(cod[which(!is.na(where))],"_",idstation[which(!is.na(where)),"station"])
  
  #Definir periodo que se desea analizar
  
  fechas=format(time_period,"%Y%m")
  fechas=cbind.data.frame("Date"=fechas,"NA")
  
  cat("Leyendo datos para cada estaci�n de ",variable,"... \n")
  Datos <- lapply(paste(rutOrigen,cod[which(!is.na(where))],"_raw_",variable,".txt",sep=""),function(x){read.table(x,header=T,sep=" ")})
  
  datos_to=as.data.frame(matrix(NA,nrow(fechas),length(Datos)))
  
  
  cat("Organizando todos los datos en un solo archivo... \n")
  for(j in 1:length(Datos)) {  
    
    old=na.omit(Datos[[j]])
    if(nrow(old)!=0){
      combnew=old[!duplicated(old[,1]),]
    }else{
      combnew = old
    }
    
    
    final=merge(fechas,combnew,by="Date",all.x=T)
    #if(nrow(final)==nrow(datosprecip)){
    datos_to[,j]=final[,3]
    #}
    
  }
  
  year=as.numeric(substr(fechas[,1],1,4))
  month=as.numeric(substr(fechas[,1],5,6))
 # day=as.numeric(substr(fechas[,1],7,8))
  
  datos_fin=cbind(month,year,datos_to)
  
  names(datos_fin)=c("month","year",as.character(station_find_n))
  
  cat("Escribiendo datos en .csv... \n")
  #Se guardan los archivos en formato .csv con la info organizada
  write.csv(datos_fin,paste(outDir,"/monthly_processed/",variable,"_monthly_raw.csv",sep=""),row.names=F)
  cat("Proceso finalizado! \n")
}



variable = c("prec","tmax","tmin")

inDir = "Z:/Water_Planning_System/01_weather_stations/hnd_sanaa/monthly_raw/"
outDir ="Z:/Water_Planning_System/01_weather_stations/hnd_sanaa/" 
rutCat = "Z:/Water_Planning_System/01_weather_stations/hnd_sanaa/monthly_raw/stations_catalog.csv"
dir.create(paste0(outDir,"monthly_processed"),showWarnings = F)

time_period=seq(as.Date("1981/1/1"), as.Date("2017/12/31"), "month")


for(j in 1:3) organize_data_cop(inDir,outDir,rutCat,variable[j],time_period,inst=NULL)













##################################
#-------Monthly data-------------#
##################################

rutOrigen="X:/Water_Planning_System/01_weather_stations/hnd_dgrh/monthly_raw/tmax-per-station" #Ruta donde se encuentran los archivos .txt
dir.create(paste0(outDir,"monthly_processed"),showWarnings = F)


files <-list.files(rutOrigen,pattern="\\.txt$")
nom.files<-substring(files,1,nchar(files)-13)

idstation=read.csv("X:/Water_Planning_System/01_weather_stations/hnd_dgrh/monthly_raw/stations_catalog.csv",header=T) #Cargar base con c�digo y nombre de la estaci�n
cod=idstation[,2]

where <- match( cod,nom.files)
station_find=nom.files[where[which(!is.na(where))]]
station_find_n1=idstation[which(where!="NA"),1]

x=seq(as.Date("1980/1/1"), as.Date("2015/12/31"), "month") #Definir periodo que se desea analizar

fechas=format(x,"%Y%m")
fechas=cbind.data.frame("Date"=fechas,"NA")

Datos <- lapply(paste(rutOrigen,"/",station_find,"_raw_tmax.txt",sep=""),function(x){read.table(x,header=T,sep=" ")})

Rain = Datos
datosprecip=as.data.frame(matrix(NA,nrow(fechas),length(Rain)))



for(j in 1:length(Rain)) {  
  
  old=na.omit(Rain[[j]])
  if(nrow(old)!=0){
    combnew=old[!duplicated(old[,1]),]
  }else{
    combnew = old
  }
  
  
  final=merge(fechas,combnew,by="Date",all.x=T)
  #if(nrow(final)==nrow(datosprecip)){
  datosprecip[,j]=final[,3]
  #}
  
}

year=as.numeric(substr(fechas[,1],1,4))
month=as.numeric(substr(fechas[,1],5,6))
#day=as.numeric(substr(fechas[,1],7,8))

precipfin=cbind(month,year,datosprecip)

names(precipfin)=c("month","year",as.character(station_find_n1))


#Se guardan los archivos en formato .csv con la info organizada
write.csv(precipfin,paste("hnd_precip_all.csv",sep=""),row.names=F)


