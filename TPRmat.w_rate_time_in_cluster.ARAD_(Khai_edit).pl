#!/usr/bin/perl

# Input file is a renumbered clustering trial file. This file should only contain
# population data. -Khai

#-------------------------- GLOBAL VARIABLES -----------------------------------
	$usage="\nUsage: ./script.pl  <FinalClusterFile>  <NumClusters>  <OutputPrefix>";
	$infile      = $ARGV[0] || die "$usage\n\n";
	$numclusters = $ARGV[1] || die "$usage\n\n";
	$outfile     = $ARGV[2] || die "$usage\n\n";

				
#-------------------------- INITIATE MATRIX VALUES AT ZERO ---------------------
	for (my $i = 0; $i < $numclusters; $i++)
	{
		#$t{$i} = 0;
		for(my $j = 0; $j < $numclusters; $j++)
		{
			$T{"$i,$j"} = 0;
			$r{"$i,$j"} = 0;
		}
	}


#-------------------------- READ IN DATA FROM CLUSTERING INFO FILE -------------
	open (INP, "<$infile") or die "Can't open $infile. $!.\n";
	$lastclone   = -1; #start at -1 because first clone is 0
	$lasttime    = -1; #start at -1 because first time is 0
	$lastcluster = -1; #start at -1 because first cluster is 0

	$startTime   = 100; ## Setting the start time
	$overallTime = 0; ## ???
	while ($line = <INP>)
	{
		chomp ($line); # Removes last new-line char
		foreach($line) 
		{ 
			s/^\s+//;  # Removes leading spaces
			s/\s+$//;  # Removes trailing spaces
			s/\s+/ /g; # Replaces spaces between 2 words by a single space
		}
		@info = split(/ /,$line); # split line into words
	
		$cluster = $info[0];
		$clone   = $info[12];
		$time    = $info[13];
		$time100 = $time - 100;
		
		$t{$cluster}++; # Is this counting the population for each cluster?

		if ($time >= $startTime) # only counts after 100 ps
		{
			$overallTime++;
			if(($clone == $lastclone) && ($lasttime == $time100))
			{
				# time spent in cluster i in nanoseconds
				$T{"$lastcluster,$cluster"}++;
			}
		}
			
		$lastclone   = $clone;
		$lasttime    = $time;
		$lastcluster = $cluster;

		# END OF READING $infile
	}
	close(INP);

	$totalTime = 0; ## ???
	$totalTime = $overallTime / 10000; # shouldn't this be 1000 to convert from ps to ns?


#-------------------------- PRINT OUT RESULTS ----------------------------------
	$outTmatrix = "$outfile" . ".Tmat.txt";
	$outRmatrix = "$outfile" . ".Rmat.txt";
	$outPmatrix = "$outfile" . ".Pmat.txt";

	# TOUT = transition matrix
	# ROUT = rate transition matrix
	# POUT = probability transition matrix
	open(TOUT,">$outTmatrix") || die "Cannot write to $outfile. $!.\n";
	open(ROUT,">$outRmatrix") || die "Cannot write to $outfile. $!.\n";
	open(POUT,">$outPmatrix") || die "Cannot write to $outfile. $!.\n";
				
	for ($i = 0; $i < $numclusters; $i++)
	{  
		for($j = 0; $j < $numclusters; $j++)
		{
			printf TOUT "%12.3f", $T{"$i,$j"};
					
			$time = $t{$i} * 100;
			if($time > 0.0) { $r{$i,$j} = $T{"$i,$j"} / $time; }
			else { $r{"$i,$j"} = 0.0; }
			
			printf ROUT "%12.3f", $r{$i,$j}; # in units of per ps ...
		}
		print TOUT "\n";
		print ROUT "\n";
	}


#--------------------------  GETTING THE SUM OF EACH ROW IN THE ---------------- 
#                            TRANSITION MATRIX TO GET Pmat 
	for(my $i = 0; $i < $numclusters; $i++)
	{
		for(my $j = 0; $j < $numclusters; $j++)
		{
			push (@val, $T{"$i,$j"})
		}
		my $totali = 0;
		$totali += $_ for @val;    
		push (@sum, $totali);
		@val = "";
		print STDOUT "$totali\n";
	}

	for(my $i = 0; $i < $numclusters; $i++)
	{
		for(my $j = 0; $j < $numclusters; $j++)
		{
			if ($sum[$i] > 0.0) 
			{
				$prob = $T{"$i,$j"} / $sum[$i];
				printf POUT "%3.3f \t", $prob;
			}
			else 
			{
				$prob = 0; printf POUT "%3.3f \t", $prob;
			}
		}
		print POUT "\n";
	}

close(TOUT);
close(ROUT);
close(POUT);