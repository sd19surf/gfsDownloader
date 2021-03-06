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
    $day = sprintf("%02d",$mday-1);
    $hr = "12";
    
      @listOfHours = ("000","003","006","009","012","015","018","021","024","027","030","033","036","039","042","045","048","051","054","057","060","063","066","069","072","075","078","081","084","087","090","093","096","099","102","105","108","111","114","117","120");
#     @listOfHours = ("000","003","006","009","012");
    
    #Create a function here to download the information if doesn't exist.
    
        foreach $fhour (@listOfHours){
    
            if (-e "gfs.t".$hr."z.pgrb2.0p50.f".$fhour) {
            push (@fileArray,"gfs.t".$hr."z.pgrb2.0p50.f".$fhour);
    
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

    $ftp->cwd("/pub/data/nccf/com/gfs/prod/gfs.$yearDir$day/$hr/") or die "Cannot change working directory ", $ftp->message;
    

    $t0 = Benchmark->new;

    print "Getting hour.....".$fhour."\n";
        $ftp->get("gfs.t".$hr."z.pgrb2.0p50.f".$fhour) or warn "get failed ", $ftp->message;
    $t1 = Benchmark->new;
    $td = timediff($t1, $t0);
    print "the download took:",timestr($td),"\n";
    #add to the list of files that were downloaded
    push (@fileArray,"gfs.t".$hr."z.pgrb2.0p50.f".$fhour);
    

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
         # system("wgrib2 $_ -match ':TMP:surface:' -rpn '304:max:304.1:min:' -grib_out c:/python27/scripts/jpp/grib2shape/ingrib/CENTCOM_DRAFT_TMP_$_.grb");
	 # system("wgrib2 $_ -s -match ':VIS:' -rpn '3:max' -grib_out c:/python27/scripts/jpp/grib2shape/ingrib/CENTCOM_DRAFT_VIS_$_.grb");
    #print "Processing winds for $_\n";
	 # system("java -jar c:/users/shawn/grib2json/grib2json-0.8.0-SNAPSHOT/lib/grib2json-0.8.0-SNAPSHOT.jar --names --data --fs 103 --fv 10.0 --fp 2 --o C:/python27/scripts/jpp/grib2shape/ingrib/CENTCOM_WINDS_TEST_$_.json $_");
     }
     
      