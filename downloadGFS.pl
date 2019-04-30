    use Net::FTP;
    use IPC::Open3;
    
    use Benchmark;

   my @fileArray;
   
    $tS = Benchmark->new;
    #Get Current Date
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
    
    $year = $year + 1900;
    $mon = sprintf("%02d",$mon + 1);
    
    $yearDir = "$year$mon";
    $day = sprintf("%02d",$mday );
    $hr = "12";
    
    @listOfHours = ("000","003","006","009","012","015","018","024","027","030","033","036","039","042","048");
    
    #Create a function here to download the information if doesn't exist.
    
        foreach $fhour (@listOfHours){
    
            if (-e "gfs.t".$hr."z.pgrb2.0p25.f".$fhour) {
            push (@fileArray,"gfs.t".$hr."z.pgrb2.0p25.f".$fhour);
    
            } else {
            
            retrieveFiles($fhour);
            }
        }
    
    sub retrieveFiles(){
    
    my ($arg1) = @_;
    
    
    $ftp = Net::FTP->new("ftp.ncep.noaa.gov", Debug => 0) or die "Cannot connect to ftp.ncep.noaa.gov: $@";
    
    $ftp->login("anonymous",'sd19surf@gmail.com') or die "Cannot login ", $ftp->message;
    
    $ftp->binary;   
	
	print "$yearDir$day$hr/"; 

    $ftp->cwd("/pub/data/nccf/com/gfs/prod/gfs.$yearDir$day$hr/") or die "Cannot change working directory ", $ftp->message;
    

    $t0 = Benchmark->new;

    print "Getting hour.....".$fhour."\n";
        $ftp->get("gfs.t".$hr."z.pgrb2.0p25.f".$fhour) or warn "get failed ", $ftp->message;
    $t1 = Benchmark->new;
    $td = timediff($t1, $t0);
    print "the download took:",timestr($td),"\n";
    #add to the list of files that were downloaded
    push (@fileArray,"gfs.t".$hr."z.pgrb2.0p25.f".$fhour);
    

     $ftp->quit;
     
    }
     
    $tF = Benchmark->new;
    $told = timediff($tF, $tS);
     
     print "total download time was:",timestr($told),"\n";
     foreach(@fileArray){
     #could open in wgrib2 at this point and create a structure will all of the data needed to create an extracted bulletin
     #store each parameter and then create a library of functions create more parameters if they aren't available.
     #gfs.t00z.pgrb2.0p25.f012
    # system("c:/Users/Shawn/Downloads/wgrib2.exe $_ -match ':RH:2 m above ground:' -text rh.txt");
    print "$_ is currently being processed\n";
          #system("wgrib2 $_ -s -match ':CAPE:surface:' -undefine_val -9e20:1000 | wgrib2 -i $_ -csv $_.csv");
          system("wgrib2 $_ -s -match ':TMP:surface:' -undefine_val -9e20:95 -grib_out c:/python27/scripts/jpp/grib2shape/ingrib/CENTCOM_DRAFT_TMP_$_.grb");
	  system("wgrib2 $_ -s -match ':VIS:surface:' -undefine_val -9e20:4 -grib_out c:/python27/scripts/jpp/grib2shape/ingrib/CENTCOM_DRAFT_VIS_$_.grb");
     }
     
      