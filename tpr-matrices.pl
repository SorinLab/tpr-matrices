#!/usr/bin/perl

# KHAI REMIX
# FALL 2014

	# Definitions
	# T = Transition matrix
	# R = Rate transition matrix
	# P = Probability transition matrix
	# M = Micro Second matrix (timescale of a transition)

#------------------ GLOBAL VARIABLES -------------------------------------------
	$usage = "Usage: ./script.pl  <Macrostate File>  <# clusters>  <vectorLength>  <cutoff time>  <output files prefix>";
	$infile       = $ARGV[0] or die "$usage\n";
	$numClusters  = $ARGV[1] or die "$usage\n";
	$vectorLength = $ARGV[2] or die "$usage\n";
	$startTime    = $ARGV[3] or die "$usage\n"; # time when equilibrium occurs
	$outPrefix    = $ARGV[4] or die "$usage\n";

	# In clustering trial files (output of Kmeans_*_v20.pl), the first four 
	# columns are always Class, dist(1), dist(2), <Delta(dist)>. The last four
	# columns are always run, clone, time, and project. Vector length from the
	# command line is the number of metrics used for clustering. So after this
	# addition, $dataLineLength should represent the length (in word count) of the
	# line (in the clustering file) the script should process, and ignore others.
	$dataLineLength = $vectorLength + 8;

	$startTime = int $startTime; # time gotta be whole

	# Exit the script if there is a wrong number of 
	# argument passed from the command line.
	if (scalar @ARGV != 5) 
	{
		print "ERROR: Missing or having extra parameters. \n$usage\n";
		exit;
	}


#------------------ INITIATE MATRIX VALUES AT ZERO -----------------------------
	%t = (); # count the number of frames/population in a cluster
	%T = (); # Transition from state i to state j
	%P = (); # Probability of transition from i to j
	%R = (); # Rate of transition from i to j. Inverse of rate is timescale
	for ($i = 0; $i < $numClusters; $i++)
	{
		$t{$i} = 0;
		for ($j = 0; $j < $numClusters; $j++)
		{
			$T{"$i,$j"} = 0;
			$P{"$i,$j"} = 0;
			$R{"$i,$j"} = 0;
		}
	}


#------------------ READ IN DATA FROM CLUSTERING words FILE --------------------
	open (INPUT, "<$infile") or die "Can't open $infile. $!.\n";
	$lastClone   = "";
	$lastTime    = "";
	$lastCluster = "";

	print "=================================================================\n";
	print "Importing data from $infile...\n\n";
	while ($line = <INPUT>)
	{
		if ($line =~ m/#/) {  next;  } # skip comments

		foreach($line)
		{
			s/^\s+//;  # removes leading spaces
			s/\s+$//;  # removes trailing spaces
			s/\s+/ /g; # replaces spaces between 2 words by a single space
		}
		@words = split(/ /,$line); # splits line into words

		if (scalar @words != $dataLineLength) {  next;  } # ignore non-population lines
		
		$cluster     = $words[0];

		$timeColumn  = (4 + $vectorLength + 3) - 1; # see comments above $dataLineLegth
		$time        = $words[$timeColumn];

		$cloneColumn = (4 + $vectorLength + 2) - 1; # see comments above $vectorLength
		$clone       = $words[$cloneColumn];

		# Print some progress message to STDOUT so users don't freak out why the
		# terminal suddenly becomes "frozen".
		if ($. % 1000 == 0)
		{
			print "$. lines processed... ";
			print "cluster: $cluster, clone: $clone, time: $time\n";
		}
		

		#$time100 = $time - 100; # to avoid missing frames
		if ($time > $startTime)
		{
			# do not count "artificial" jump at end of sim 
			if (($clone == $lastClone)
				# do not count if there's missing (frames)
				&& ($time - 100 == $lastTime)
				# do not count jumps from state at $startTime to current $time
				&& ($lastTime != $startTime))
			{
				$T{"$lastCluster,$cluster"}++;
				#$t{$cluster}++; # time spent in cluster i in ps/100
				$t{$lastCluster}++;
			}
		}
		$lastClone   = $clone;
		$lastTime    = $time;
		$lastCluster = $cluster;
		
		# Testing purposes: Only read in $x number of lines
		# $x = 100;
		# if ($. == $x) {  last;  exit;  }
	}
	close INPUT;
	print "Importing done.\n\n";
		

#------------------ PRINT OUT RESULTS -----------------------------------------#
	print "=================================================================\n";
	print "Writing results to output files...\n";
	$outTmatrix = "$outPrefix.$startTime.Tmat.txt";
	$outPmatrix = "$outPrefix.$startTime.Pmat.txt";
	$outRmatrix = "$outPrefix.$startTime.Rmat.txt";
	$outMmatrix = "$outPrefix.$startTime.Mmat.txt";

	open(TOUT,">$outTmatrix") or die "Cannot write to $outTmatrix. $!.\n";
	open(ROUT,">$outRmatrix") or die "Cannot write to $outPmatrix. $!.\n";
	open(POUT,">$outPmatrix") or die "Cannot write to $outRmatrix. $!.\n";
	open(MOUT,">$outMmatrix") or die "Cannot write to $outMmatrix. $!.\n";
		
	for ($i = 0; $i < $numClusters; $i++) # Rows
	{
		for ($j = 0; $j < $numClusters; $j++) # Columns
		{
			$MMM = 0;
			if ($t{$i} != 0)
			{
				$P{"$i,$j"} = ($T{"$i,$j"} / $t{$i}) * 100; # in percent
				
				$time = $t{$i} * 100; # why 100? 100ps/frame, so $time is now in ps	
				# Note: leave the time alone! It's $time / 1000000 = Micro-s
				$R{"$i,$j"} = $T{"$i,$j"} / ($time/1000000); # $R{$i,$j} in micro-s

				if ($R{"$i,$j"} != 0)
				{
					$MMM = 1 / $R{"$i,$j"}; # inverse of rate is timescale
				}
				# else {  $MMM = 0; }
			}
			else 
			{
				$P{"$i,$j"} = 0;
				$R{"$i,$j"} = 0;
			}
			printf TOUT "\t% 12d", $T{"$i,$j"};
			printf POUT "\t%12.2f", $P{"$i,$j"}; # in percent
			printf ROUT "\t%12.2f", $R{"$i,$j"}; # in units of per micro-s
			printf MOUT "\t%12.4f", $MMM;
		} # end of inner for loop

		print TOUT "\n";
		print ROUT "\n";
		print POUT "\n";
		print MOUT "\n";
	} # end of outter for loop

# Closing them files
close(TOUT); close(ROUT); close(POUT); close(MOUT);