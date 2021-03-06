### Zonal statistical (mean) by microwatershed of all the variables involved into the water balance
### Use this script only for input and output variables at montly timescale. Also for yearly-monthly timescale but only for input variables (not efficient and will take long time!)
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
### Contribution: Carlos Navarro <c.e.navarro@cgiar.org>
### Parallelization code lines taken and modified from: http://fabiolexcastrosig.blogspot.com.co/2017/04/realizar-extraccion-por-mascara-en-r.html

# Load libraries
require(raster)
require(rgdal)
require(parallel)
require(foreach)
require(doSNOW)

scenario = "rcp2.6_2030" # This goes with line 20 or 25
#scenario = "baseline" # This goes with line 21 or 25

# Uncomment the variables to be analyzed
# Input variables of water balance
iDir <- paste0("Z:/Water_Planning_System/Inputs/WPS/Balance_Hidrico/climate_change/downscaled_ensemble/", scenario)
#iDir <- "Z:/Water_Planning_System/Inputs/WPS/Balance_Hidrico/shared" # This goes with lines 38 and 39
#varLs <- c("prec", "tmax", "tmean", "tmin", "eto") # This goes with lines 38 and 39
varLs = "prec" # This goes with lines 38 and 39
# Output variables of water balance
#iDir <- paste0("V:/10_outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/", scenario)
#varLs <- c("aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield") # This goes with lines 38 and 39
#varLs = "wyield" # This goes with lines 36 and 37
# Define if the variables to be analyzed are inputs (in) or outputs (out) of the water balance
in_or_out = "in"
# Define if timescale is monthly (m) or yearly-monthly (ym)
timescale = "ym"

oDir <- paste0("V:/06_analysis/Scenarios/", scenario)
#oDir <- paste0(net_drive, "/Water_Planning_System/COSUDE_R13/06_analysis/Calibration/common_files")
# Shapefile of microwatersheds
#mask_shp <- "V:/06_analysis/Scenarios/mask/Micros_ZOI_Incl_Goas_Update2020.shp" # This for wyield when including micros of Goascoran
#suffix = "_inclu_goas"
mask_shp <- "V:/06_analysis/Scenarios/mask/Micros_ZOI_Update2020.shp" # This for other variables - monthly (m)
suffix = ""
#mask_shp <- paste0(net_drive, "/Water_Planning_System/COSUDE_R13/06_analysis/Calibration/mask/Cuencas_Calibracion_Caudal.shp")
# Years of simulation without warm-up year of the water balance
yi <- "2000"
yf <- "2014"
years = yi:yf

months = 1:12

# Temporal folder for raster calculations
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir = paste0(oDir, "/tmp"))

# Configuration of parallelization
#nCores <- detectCores(all.tests = FALSE, logical = TRUE)
ncores = max(1, detectCores() - 1)
cl = makeCluster(ncores)
registerDoSNOW(cl)

# configuration of progress bar
length_run <- length(varLs)
pb <- txtProgressBar(max = length_run, style = 3)
progress <- function(n) setTxtProgressBar(pb, n) 
opts <- list(progress=progress)


zonalStatistic <- function(var, poly_shp, scenario, in_or_out, timescale = "m", iDir, oDir, months = 1:12, years, suffix = "", id = "HydroID", math.operation = "mean"){
  
  cat("\n####################################################\n")
  cat(paste0("Analyzing variable ", var, " ......\n"))
  cat("####################################################\n")
  
  if (in_or_out == "in" ){
    
    if (timescale == "m"){
      # For monthly timescale
      if (scenario == "baseline"){
        rasters = paste0(iDir, "/", var, "/projected/", var, "_month_", months, ".tif")
      }
      else{
        rasters = paste0(iDir, "/", var, "/", var, "_month_", months, ".tif")
      }
      prefix = "mth_avg_timeline"
    } else if(timescale == "ym"){
      # For yearly-monthly timescale 
      # Get combination of year-month
      yr_mth <- expand.grid(months, years)
      if (scenario == "baseline"){
        rasters = paste0(iDir, "/", var, "/projected/", yr_mth[,2], "/", var, "_", yr_mth[,2], "_", months, ".tif")
      }
      else{
        rasters = paste0(iDir, "/", var, "/", yr_mth[,2], "/", var, "_", yr_mth[,2], "_", months, ".tif")
      }
      prefix = "mth_yearly_timeline"
    } else{ stop("Timescale is not an allowed option (m: monthly, ym: yearly-monthly)") }
    
    cat("\tCreating raster stack ......\n")
    # Raster stack
    rs_stk <- stack(rasters)
    
    cat("\tDissagregating raster stack......\n")
    # Dissagregate for smallest poly_shpgons
    rs_stk <- disaggregate(rs_stk, fact=c(33, 33)) # This generates a final resolution of approx. 30 m
  }
  else if (in_or_out == "out" ){
    
    if (timescale == "m"){
      # For monthly timescale
      rasters = paste0(iDir, "/", var, "/",  var, "_month_", months, ".tif")
      prefix = "mth_avg_timeline"
    } else if(timescale == "ym"){
      # This script was not created for yearly-monthly timescale execution
      stop("It is not allowed to execute this script for yearly-monthly timescale of the output variables")
    } else{ stop("Timescale is not the allowed option (m: monthly)") }
    
    cat("\tCreating raster stack ......\n")
    # Raster stack
    rs_stk <- stack(rasters)
  } else { stop("Variables to be analyzed are neither inputs (in) nor outputs (out)") }
  
  cat("\tCroping raster stack with mask_shp ......\n")
  # Convert poly_shpgons to raster with a specific ID
  rs_stk_crop <- crop(rs_stk, extent(poly_shp))
  extent(rs_stk_crop) <- extent(poly_shp)
  cat("\tRasterizing microwatersheds ......\n")
  #poly_shp_rs <- rasterize(poly_shp, rs_stk_crop[[1]], as.integer(levels(poly_shp@data[id][[1]])))
  poly_shp_rs <- rasterize(poly_shp, rs_stk_crop[[1]], as.integer(poly_shp@data[id][[1]]))
  
  cat("\tCarrying out the zonal statistic operation ......\n")
  # Get the zonal statistics
  rs_zonal <- zonal(rs_stk_crop, poly_shp_rs, math.operation)
  
  cat("\tWriting the CSV file ......\n")
  # Write the outputs
  write.csv(rs_zonal, paste0(oDir, "/", prefix, "_", var, suffix, ".csv"), row.names=F)
  
}

# Read mask_shp and convert it to Spatialpoly_shpgonsDataFrame
poly_shp <- readOGR(mask_shp) 

# Execute process in parallel
foreach(i = 1:length_run, .packages = c('raster', 'rgdal'), .options.snow=opts, .verbose=TRUE) %dopar% {
  
  zonalStatistic(varLs[i], poly_shp, scenario, in_or_out, timescale, iDir, oDir, months, years, suffix)
  
}

# It is important to stop the cluster, even when the script is stopped abruptly
stopCluster(cl)
close(pb)

# Delete temp files
unlink(rasterOptions()$tmpdir, recursive=TRUE)

cat("\nDone!!!")