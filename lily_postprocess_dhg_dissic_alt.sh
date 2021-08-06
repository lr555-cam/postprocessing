#!/bin/bash

# *** This script is for models with data in large chunks which span 1850-2014***

# Input where the raw model data downloaded by wget is located 
INPUTDIR=/disk2/lr452/Downloads/dissic_data/raw_data

# Change the present working directory to that directory
cd $INPUTDIR

# Name of the climate variable you want processed
var=dissic

# ******  Postprocessing raw model outputs ******


for CMIP6MODEL in "ACCESS-ESM1-5" "CanESM5" "CESM2" "GFDL-ESM4" "GISS-E2-1-G" "IPSL-CM6A-LR" "MPI-ESM1-2-LR"
do

    case $CMIP6MODEL in
	"ACESS-ESM1-5")   id="r" ; chunk=50 ;;
	"CanESM5")   id="r" ; chunk=20 ;;
	"CESM2")   id="r" ; chunk=50 ;;
	"GFDL-ESM4")   id="r" ; chunk=20 ;;
	"GISS-E2-1-G")   id="r" ; chunk=10 ;;
	"IPSL-CM6A-LR")   id="r" ; chunk=20 ;;
	"MPI-ESM1-2-LR")   id="r" ; chunk=5 ;;
    esac

    
#Step 1: Isolate years 1994-2014
    echo "Isolating year 1994-2014 from the  model data ..."


    ##### Files in 10 year chunks

    if [[ $chunk -eq 10 ]]
    then
       # Grab 1994-1999 inclusive from 1990-1999
       cdo -selyear,1994/1999 ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199001-199912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-199912.nc


       # Now concatenate 1994-2014

       ncrcat ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-199912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_200001-200912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_201001-201412.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.nc
       
    elif [[ $chunk -eq 5 ]]
    then 
       # Grab 1994 from 1990-1994
	cdo -selyear,1994 ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199001-199412.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-199412.nc
	
       ncrcat ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-199412.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199501-199912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_200001-200412.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_200501-200912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_201001-201412.nc  ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.nc

       
   elif [[ $chunk -eq 20 ]]
   then

       cdo -selyear,1994/2009 ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199001-200912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-200912.nc
       
       ncrcat ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-200912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_201001-201412.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.nc

       
    elif [[ $chunk -eq 50 ]]
    then

	cdo -selyear,1994/1999 ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f2_g${id}_195001-199912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f2_g${id}_199401-199912.nc
	
        ncrcat ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f2_g${id}_199401-199912.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f2_g${id}_200001-201412.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f2_g${id}_199401-201412.rg.nc


    fi

    
    #Step 2:  Regrid to 1 deg by 1 deg
    echo "Regridding files to 1 degree by 1 degree ..."

    # Pattern is: cdo remapbil,r360x180 -selvar,[variable name] inputfile.nc outputfile.rg.nc  (rg=regridded)



    cdo remapbil,r360x180 -selvar,$var  ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.nc ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.yr.nc

    


    #Step 3: Extract Southern Ocean
    echo "Spatially extracting southern ocean data points from the regridded 1994-2014 files ..."

    # Pattern is: cdo sellonlatbox,-180,180,-40,-80 globalfile1994-2014.rg.nc  southern_oceanonly1994-2014.rg.so.nc  (so is southern ocean)

    cdo sellonlatbox,-180,180,-40,-80   ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.yr.nc  ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.yr.so.nc
    

 

    #Step 4: Mask to ocean only
    echo "Masking out land points from regridded southern ocean 1994-2104 fixed metadata files so that the files only contain ocean points ..."

    # Pattern is: cdo setctomiss,1.0e20 inputfile.rg.so.fix.nc  outputfile.rg.so.fix.mask.nc
    
    cdo setctomiss,1.0e20  ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.yr.so.fix.nc  ${var}_Omon_${CMIP6MODEL}_historical_r1i1p1f1_g${id}_199401-201412.rg.yr.so.fix.mask.nc
    

done  #End of the loop around the models


# In the end, it's the files ending in *.mask.nc that are the final product. You can see them after the script runs by typing
# ls -l *rg.so.fix.mask.nc





