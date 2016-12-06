
#!/usr/bin/perl
    
    
########## global variables ####################
$usage="\nUsage: \.\/renumber_clustered_data\.pl  \[Final Cluster File]  \[Output File Name] \n\n";
$infile  = $ARGV[0] || die "$usage\n";
$outfile = $ARGV[1] || die "$usage\n";

# Definitions
# TOUT = transition matrix
# ROUT = rate transition matrix
# POUT = probability transition matrix

$numclusters = 27;      ## Setting the cluster numbers
$overalltime = 0;       
$starttime = 100;     ## Setting the start time
$tottime = 0; 
        
        
############### initiate matrix values at zero  ##############
for($i=0;$i<$numclusters;$i++){
  #$t{$i} = 0;
  for($j=0;$j<$numclusters;$j++){
    $T{$i,$j} = 0;
    $r{$i,$j} = 0;
  }
}
          
          
############### read in data from clustering info file ###########
open (INP, "<$infile") or die "Can't open $infile\n";
$lastclone = -1;
$lasttime  = -1;
$lastcluster  = -1;         #start at -1 because first cluster is 0

while ($line = <INP>){
        chomp ($line);
        foreach($line) { s/^\s+//;s/\s+$//; s/\s+/ /g; }
        @info = split(/ /,$line);
        $cluster = $info[0];
        $time    = $info[11];
        $clone   = $info[10];
        $time100 = $time - 100;
# print STDOUT " cluster = $cluster, time = $time, clone = $clone \n\n";
if ($time >= $starttime) {
        $overalltime++;
        if(($clone == $lastclone)&&($lasttime == $time100)){
            # time spent in cluster i in nanoseconds
          $T{$lastcluster,$cluster}++;
        }}
        
        $lastclone = $clone;
        $lasttime  = $time;
        $lastcluster = $cluster;
                 
# print STDOUT "$time, \n\n $starttime \n\n";
    
}
close(INP);
        
$tottime = $overalltime / 10000;  
############# print out results #############
$outTmatrix = "$outfile".".Tmat.txt";
$outRmatrix = "$outfile".".Rmat.txt";
$outPmatrix = "$outfile".".Pmat.txt";

open(TOUT,">$outTmatrix") || die "Cannot write to $outfile\n\n";
open(ROUT,">$outRmatrix") || die "Cannot write to $outfile\n\n";
open(POUT,">$outPmatrix") || die "Cannot write to $outfile\n\n";
        
for($i=0;$i<$numclusters;$i++){  
  for($j=0;$j<$numclusters;$j++){

    printf TOUT "%12.3f",$T{$i,$j};
        
 
    if($tottime > 0.0) { $r{$i,$j} = $T{$i,$j} / $tottime; }
        else { $r{$i,$j} = 0.0 }
                 printf ROUT "%12.3f",$r{$i,$j}; # in units of per ps ...

  #  printf POUT "%12.3f",$t{$i};
        
  }
  
  print TOUT "\n";
  print ROUT "\n";
 # print POUT "\n";
}



####### getting the sum of each row in the transition matrix to get Pmat ####
for($i=0;$i<$numclusters;$i++){
    for($j=0;$j<$numclusters;$j++){
        push (@val, $T{$i, $j})
      }
      my $totali = 0;
      $totali += $_ for @val;    
      push (@sum, $totali);
      @val = "";
      print STDOUT " $totali \n\n";
        
   }
for($i=0;$i<$numclusters;$i++){
    for($j=0;$j<$numclusters;$j++){
      if ($sum[$i] > 0.0) {$prob = $T{$i,$j} / $sum[$i];
        printf POUT "%3.3f \t", $prob;}
      else { $prob = 0; printf POUT "%3.3f \t", $prob;}
    }
    print POUT "\n";
}

exit();
                 
close(TOUT);
close(ROUT);
close(POUT);
