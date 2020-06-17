
#use Time::Piece;
#use Time::Seconds;
use Benchmark;
use threads;
#use Thread::Queue qw( );
#use Thread::Semaphore;


##################################################################################################
## Purpose to build an ensemble TARP file for any station
## using wgrib2 bypasses the need for LEADS and is faster
## wgrib2 is loaded on JET Distro
## output is going to be JSON since it's faster for web code to read it
## written by :John Delaney 2020 (coronavirus)
#################################################################################################

#################################################################################################
## Read in a config file
## built for grib files to produce point json files with variable names, times, and values
## removed need for Time::Pieces
#################################################################################################

#test for necessary files first and complain if thif they aren't there


####################################################################################################################

START:
####################################################################################################################
##Read in the config file

readConfig('testConfig.txt');


####Gather filenames with extension

my @files = checkDirForFiles($fileInfo{'filepath'},$fileInfo{'modelName'});
my @processedFiles = readProcessed('processed.txt');

@diff{ @processedFiles }= ();

my @need = grep !exists($diff{$_}), @files;
my $need = @need;
print "$fileInfo{'log name'}\n";
print "Number of files needed: $fileInfo{'Number Of Files'} and Number available: $need\n";
if($fileInfo{'Number Of Files'} != $need){
    sleep($timeToWaitForNewFiles);
    goto START;
}else{
    goto RUN;
}

#####################################################################################################################
RUN:
my @threads;
#my $sem = Thread::Semaphore->new(15);

my @station_list;
$tS = Benchmark->new;

open my $handle, '<', $station_list;
chomp(@station_list = <$handle>);
close $handle;

my $i = 0;
foreach(@station_list){

    my @parse = split /,/, $_;
    my $lat = @parse[1];
    my $lon = @parse[2];
    my $icao = @parse[0];
    my $thrd = $i++;
    my $varsToMatch = $listOfVariables{'variables'}; #from config file
    push @threads, threads->new(\&main, $lon, $lat, $icao, $thrd, $varsToMatch);
}

 foreach(@threads){
     $_->join();
    
 }   

     $tF = Benchmark->new;
    $told = timediff($tF, $tS);
     print "total run time was:",timestr($told),"\n";
     processedLog(@files);
     logFiles("total run time was:",timestr($told),"\n");

     goto START;




sub main(){
my $paramLat = @_[0];
my $paramLon = @_[1];
my $paramICAO = @_[2];
my $threadNumber = @_[3];
my $variableList = @_[4];
#$sem->up;
print "running thread: $threadNumber for $paramICAO\n";
@parseFileName = split /\./, @files[0];
my $outfile = $fileInfo{'output directory'}.$paramICAO."_".@parseFileName[0]."_tarp.json";
my $HoA; #Hash of Arrays of data
my @jsonArray;
push @{ $HoA{"ICAO"} }, '"'.$paramICAO.'"';

foreach my $file(@files){
    my $newFile = $filepath.$file;
createHashTable($newFile, $paramLat, $paramLon, $variableList);
print "finished $newFile: $threadNumber for $paramICAO\n";
}
 
 #change to file print out
unless(open FILE, '>'.$outfile) {
    # Die with error message 
    # if we can't open it.
    die "\nUnable to create $outfile\n";
}
# change the output to json format
for $family (keys %HoA){
    my $dataString = join (",", @{ $HoA{$family} });
    push(@jsonArray, '"'.$family.'":['.$dataString.']');
}
my $jsonString = join ",",@jsonArray;

print FILE "{$jsonString}";
# close the file.
close FILE;
print "finished thread: $threadNumber for $paramICAO\n";
logFiles("finished thread: $threadNumber for $paramICAO\n");
}


sub createHashTable(){
 my $file = @_[0];
 my $lat = @_[1];
 my $lon = @_[2];
 my $vars = @_[3];
 my $time;
 my $pattern = "";

 #create a pattern from variable listing to filter

$pattern = '('.$vars.')';

my $output = qx(wgrib2 "$file" -match "$pattern" -lon $lat $lon -vt -var -s);

foreach my $line (split /\n+/, $output){
    my ($recNumber, $byteSector, $data, $vt, $sVar, $time, $varKey ) = split /:/, $line, 7;
        push @{ $HoA{createKey($varKey)} }, '{"time": "'.getTime($vt).'","value":'.getValue($data).'}';
}

}

sub checkFileType(){
my $file = @_[0];
my $fileinfo = qx(wgrib2 "$file" -vt -t);
}

sub createKey(){
my $rawKey;
my $newKey;
foreach(@_){
$rawKey = $_;
    my ($shortVar, $elevation, $timeref, $type) = split /:/, $rawKey;
    $newKey = $shortVar."-".$elevation."(".$type.")";
}
return $newKey;
}


sub getTime(){
my $value;
my $rawValue;
    foreach(@_){
        $rawValue = $_;
    }
    $value = (split/=/,$rawValue)[1];
    $year = substr $value, 0, 4; 
    $mon = substr $value, 4, 2;
    $day = substr $value, 6, 2;
    $hour = substr $value, 8, 2;
 
$datestring = $year.'-'.$mon.'-'.$day.'T'.$hour.':00';

return $datestring;
}

sub getValue(){
my $value;
my $rawValue;
    foreach(@_){
        $rawValue = $_;
    }
    my($lon,$lat,$val) = split /,/,$rawValue;
    $value = (split /=/,$val)[1]; 
 return $value;
}

sub readConfig() {
#---------------------------------------------------------------------------------------#
# do what's needed to read in the configuration file.                                   #
# see the bottom of this url (http://www.perl.com/pub/a/2003/08/07/design2.html?page=3) #
#---------------------------------------------------------------------------------------#
my $config_file =  @_[0];
open CONFIG, "$config_file" or die "Program stopping, couldn't open the configuration file '$config_file'.\n";
my $config = join "", <CONFIG>;
close CONFIG;
eval $config;
die "Couldn't interpret the configuration file ($config_file) that was given.\nError details follow: $@\n" if $@;
}

sub readProcessed() {
my $file =  @_[0];
my @filelist;
open FILELIST, "$file" or die "Program stopping, couldn't open the processed log file '$file'.\n";
chomp (@filelist = <FILELIST>);
close CONFIG;
return  @filelist;
}


sub checkDirForFiles() {
#--------------------------------------------------------------------------------------#
# Looks in the directory and checks for the amount of files before processing          #
# Works in tandem with the log function so we don't process files we already processed #
#--------------------------------------------------------------------------------------#
my $filepath = $_[0];
my $partialFilename = $_[1];
my @newFiles;
opendir my $dir, $filepath or die "Cannot open directory: $!";
my @files = readdir($dir);

closedir $dir;
foreach(@files){
($device, $inode, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime,
   $ctime, $blksize, $blocks) = stat($_);
   if ((time() - $mtime) < $ageToProcessEpochSecs && $_ =~ $partialFilename ){
       push(@newFiles, $_);
       #logFiles($_);
   } 
}
return @newFiles;
}

sub logFiles(){
my $file = $_[0];
my $currentTime = gmtime();
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
$mon = $mon+1;
my $dateStamp = $mday.$mon.$year;
my $logFileName = $fileInfo{'log directory'}.'TARP_LOG_'.$fileInfo{'log name'}.$dateStamp.'.txt';

open(my $fh, '>>', $logFileName) or die "Could not open file '$logFileName' $!";
print $fh "$file was processed at $currentTime \n";
close $fh;
}

sub processedLog(){
my @file = @_;
open(my $fh, '>>', "processed.txt") or die "Could not open file processed.txt $!";
foreach(@files){
print $fh "$_\n";
}
close $fh;
}
