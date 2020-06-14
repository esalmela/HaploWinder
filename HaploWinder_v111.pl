
# HaploWinder version 1.11
# Copyright 2008 Elina Salmela
     
# This program is free software; copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright notice and this notice are preserved.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# email: haplowinder@gmail.com


#!/usr/bin/perl

use strict;
use warnings;

print "\n";


# open the settings file (named in ARGV; if not, print an error) and read the lines into a list
unless (defined $ARGV[0]) {die "Remember to give the name of the settings file on the command line.\n\n";} #
chomp (my $settings_file = $ARGV[0]);
open (SETTINGS,"<$settings_file") or die "\tERROR: Cannot find the settings file $settings_file. (Check filename, ending and path.)\n\n"; #
print "Opening the settings file...\n";
my @settings_rows = <SETTINGS>;
print "Done.\n";


# read the contents of the settings file into a hash
my %settings = ();
my $emptyrows_in_settings = 0;
foreach (@settings_rows) {
    my @line = split(/\t/, $_);
    if (defined $line[0]) {$line[0] =~ s/\n//; $line[0] =~ s/\r//;} # chomp, also for \r
    if (defined $line[1]) {$line[1] =~ s/\n//; $line[1] =~ s/\r//;} # chomp, also for \r
    if (defined $line[1]) {
        $settings{$line[0]}= $line[1];
    }
    else {
        print "\tNOTE: An empty row or missing parameter value (= missing separation tab?) was detected in settings file.\n";
        $emptyrows_in_settings++;
    }
    
}
chomp %settings;


# take parameter values from %settings; first check that they exist
unless (defined $settings{'input_genotype_file'}) {
    die "\tERROR: Name of genotype input file (input_genotype_file) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'input_tree_file'}) {
    die "\tERROR: Name of haplogroup input file (input_tree_file) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'input_genotype_code_file'}) {
    die "\tERROR: Name of genotype code input file (input_genotype_code_file) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'output_results_file'}) {
    die "\tERROR: Name of result output file (output_results_file) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'output_log_file'}) {
    die "\tERROR: Name of log output file (output_log_file) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'extracols'}) {
    die "\tERROR: Parameter value for number of non-genotype columns (extracols) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'samplename_col'}) {
    die "\tERROR: Parameter value for column number of sample names (samplename_col) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'missing_genotype'}) {
    die "\tERROR: The code for missing genotypes (missing_genotype) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'code_for_no_match'}) {
    die "\tERROR: The code for no matching haplogroups (code_for_no_match) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'code_for_several_matches'}) {
    die "\tERROR: The code for several matching haplogroups (code_for_several_matches) not found in the settings file $settings_file.\n\n"; #
}
unless (defined $settings{'include_extracols'}) {
    die "\tERROR: Parameter value for the option of including non-genotype columns (include_extracols) not found in the settings file $settings_file.\n\n"; #
}
unless (($settings{'include_extracols'} eq 'yes') or ($settings{'include_extracols'} eq 'no')) {
    die "\tERROR: The parameter 'include_extracols' must have either value 'yes' or 'no' in the settings file $settings_file. (Check spelling: no capital letters, no quotation marks.)\n\n"; #
}

print "Reading in the parameter values...\n";
my $input_genotype_file = $settings{'input_genotype_file'};
my $input_tree_file = $settings{'input_tree_file'};
my $genotype_code_file = $settings{'input_genotype_code_file'};
my $output_results_file = $settings{'output_results_file'};
my $output_log_file = $settings{'output_log_file'};
my $extracols = $settings{'extracols'};
my $samplename_col = $settings{'samplename_col'}; 
my $missing_genotype = $settings{'missing_genotype'};
my $code_for_no_match = $settings{'code_for_no_match'};
my $code_for_several_matches = $settings{'code_for_several_matches'};
my $include_extracols = $settings{'include_extracols'};
print "Done.\n";


# open the files etc.
print "Opening input and output files...\n";
open (LABDATA,"<$input_genotype_file") or die "\tERROR: Cannot find the genotype input file $input_genotype_file. (Check filename, ending and path.)\n\n"; #
open (TREE,"<$input_tree_file") or die "\tERROR: Cannot find the haplogroup input file $input_tree_file. (Check filename, ending and path.)\n\n"; #
open (GENOTYPE_CODES, "<$genotype_code_file") or die "\tERROR: Cannot find the genotype code input file $genotype_code_file. (Check filename, ending and path.)\n\n"; #
open (RESULT, ">$output_results_file");
open (LOG, ">>$output_log_file");
print "Done.\n";

# start printing analysis details into the log file
print LOG "\n +------------------------------------+\n";
print LOG   " |      HaploWinder version 1.11      |\n";
print LOG   " |    Copyright 2008 Elina Salmela    |\n";
print LOG   " | www.genome.helsinki.fi/haplowinder |\n";
print LOG   " +------------------------------------+\n\n\n";

print LOG "Analysis started ", scalar localtime, ".\n\n";

print LOG "Analysis results located in $output_results_file.\n\n";

print LOG "Names of input files used in the analysis\n";
print LOG "genotypes: $input_genotype_file\n";
print LOG "haplogroups: $input_tree_file\n";
print LOG "genotype codes: $genotype_code_file\n";
print LOG "settings: $settings_file\n\n";


# print the possible note about empty rows in settings file also to the log file
unless ($emptyrows_in_settings == 0) {
    print LOG "NOTE: $emptyrows_in_settings empty rows or missing parameter values (= missing separation tabs?) were detected in settings file.\n";
}


# read the genotype codes into another hash
print "Reading in the genotype codes...\n";
my @code_rows = <GENOTYPE_CODES>;

my %genotype_codes = ();
foreach (@code_rows) {
        my @line = split(/\t/, $_);
	if (defined $line[0]) {$line[0] =~ s/\n//; $line[0] =~ s/\r//;} # chomp, also for \r
	if (defined $line[1]) {$line[1] =~ s/\n//; $line[1] =~ s/\r//;} # chomp, also for \r
        if (defined $line[1]) {
            $genotype_codes{$line[0]}= $line[1];
        }
        else {
            print "\tNOTE: An empty row or missing parameter value (= missing separation tab?) was detected in genotype code input file.\n"; #
            print LOG "NOTE: An empty row or missing parameter value (= missing separation tab?) was detected in genotype code input file.\n\n"; #
        }
}
chomp %genotype_codes;
print "Done.\n";
print LOG "\n";

# check that the missing genotype code given in settings is a valid genotype code
defined ($genotype_codes{$missing_genotype}) or die "ERROR: The missing genotype code defined in the settings file (as missing_genotype) is not among the valid genotype codes!\n\n";


# read the input (genotype & haplogroup) file rows into elements of corresponding lists
print "Processing input files...\n";
my @labdata_rows = <LABDATA>;
my @tree_rows = <TREE>;

# count the number of samples and haplotypes; print also to log file for later checking
my $sample_n = scalar(@labdata_rows)-1;
my $haplotype_n = scalar(@tree_rows)-1;
print LOG "Your genotype data input file contains $sample_n samples.\n";
print LOG "Your haplogroup input file contains $haplotype_n haplogroups.\n\n";
print "\tInput files contained $sample_n samples and $haplotype_n haplogroups.\n";
print "Done.\n";

# "chomp" the genotype and haplogroup input files, also for \r
foreach (@tree_rows) {$_ =~ s/\n//; $_ =~ s/\r//;}
foreach (@labdata_rows) {$_ =~ s/\n//; $_ =~ s/\r//;}


# check input files for validity of genotype entries (from genotype input hash),
# and print error messages to log file & screen if nonvalid genotypes are found;
# edit the genotype entries if wanted
print "Checking the validity of input genotypes...\n";

# for the haplogroup input file
foreach (@tree_rows[1..scalar(@tree_rows)-1]) {
    my @list = split /\t/, $_;
    foreach (@list[1..scalar(@list)-1]) {
        if (defined $genotype_codes{$_}) {
            $_ = $genotype_codes{$_};
        }
        else {
        print "\tERROR: Nonvalid genotype in haplogroup input file, haplogroup ", $list[0], ".\n"; #
        print LOG "ERROR: Nonvalid genotype in haplogroup input file, haplogroup ", $list[0], ".\n"; #
        }
    }
    $_ = join("\t", @list);
}

# the same for the genotype input file
foreach (@labdata_rows[1..scalar(@labdata_rows)-1]) {
    my @list = split /\t/, $_;
    foreach (@list[$extracols..scalar(@list)-1]) {
        if (defined $genotype_codes{$_}) {
            $_ = $genotype_codes{$_};
        }
        else {
            print "\tERROR: Nonvalid genotype in genotype input file, sample ", $list[$samplename_col-1], ".\n"; #
            print LOG "ERROR: Nonvalid genotype in genotype input file, sample ", $list[$samplename_col-1], ".\n"; #
        }
    }
    $_ = join("\t", @list);
}
print "Done.\n";
print LOG "\n";

# compare the order of columns from their names on first rows
print "Comparing the column order in input files...\n";

my @labdata_headings = split /\t/, $labdata_rows[0];
my @labmarker_headings = @labdata_headings[$extracols..scalar(@labdata_headings)-1];
my @tree_headings = split /\t/, $tree_rows[0];

# first check that haplogroup file headings are unique
my %tree_headings = ();
foreach (@tree_headings) {
    if (defined $tree_headings{$_}) {
        print "\tNOTE: Marker $_ appeared more than once in the haplogroup input file.\n"; #
        print LOG "NOTE: Marker $_ appeared more than once in the haplogroup input file.\n"; #
    }
    $tree_headings{$_} = $_;
}


# check how many markers are completely missing from genotype input file
my $insert_cols = 0;
my @missing_marker_names = ();
foreach my $hm (@tree_headings[1..scalar(@tree_headings)-1]) {
    my $o = 0;
    foreach my $gm (@labmarker_headings) {
        if ($hm eq $gm) {$o++;}
    }
    if ($o == 0) {
        $insert_cols++;
        push(@missing_marker_names, $hm);
        print "\tNOTE: Marker $hm was missing from genotype input data.\n"; #
        print LOG "NOTE: Marker $hm was missing from genotype input data.\n\n"; #
    }
    else {$o == 1 or die "ERROR: Marker $hm appeared more than once in the genotype input file!\n\n";} #
}

# input the appropriate number of columns of missing genotype codes into the genotype file
if ($insert_cols > 0) {
    @labdata_headings = split /\t/, $labdata_rows[0];
    push (@labdata_headings, @missing_marker_names);
    $labdata_rows[0] = join("\t", @labdata_headings);
    my @extra_genotypes = ();
    for (my $p=1; $p<=$insert_cols; $p++) {
        push (@extra_genotypes, $genotype_codes{$missing_genotype});
    }
    foreach (@labdata_rows[1..scalar(@labdata_rows)-1]) {
        my @list = split /\t/, $_;
        push (@list, @extra_genotypes);
        $_ = join("\t", @list);
    }
}

# form the column correspondence array
my @corresp_cols = ();  
  marker: foreach (@tree_headings[1..scalar(@tree_headings)-1]) {
      for (my $q = $extracols; $q <= scalar(@labdata_headings)-1; $q++) {
          if ($labdata_headings[$q] eq $_) { 
              push (@corresp_cols, $q);
              next marker;
          }
      }
  }


print "Done.\n";


# print the header row to the results file
my $leading_entries_hdr = ();
if ($include_extracols eq 'yes') {
    $leading_entries_hdr = join ("\t", @labdata_headings[0..$extracols-1]);
}
if ($include_extracols eq 'no') {
    $leading_entries_hdr = $labdata_headings[$samplename_col-1];
}
my $marker_entries = join ("\t", @labdata_headings[@corresp_cols]);    
my $new_header = join ("\t", $leading_entries_hdr,$marker_entries,'# missing genotypes','# inferred genotypes','# observed genotypes','# matching haplogroups','name of matching haplogroup');
print RESULT $new_header,"\n";


# compare each genotype with all tree rows and count the matches;
# replace missing genotypes with the right ones (in lowercase letters) whenever they are unique in all matching haplogroups;
# count original, replaced and missing genotypes; print to output file

# take each genotype row (skip the 1st row, with headings)
print "Determining haplogroups for each sample:\n";

for (my $i = 1; $i <= $sample_n; $i++) {
    
    # split by tabs into a list
    my @current_genotype = split /\t/, $labdata_rows[$i];

    # take the genotype columns (is sample name needed?) in order of column correspondence
    my @ordered_genotype = @current_genotype[@corresp_cols];

    # initiate the match counter and match lists for this genotype  
    my $n = 0;
    my @compatible_haplogroup_rows = ();
    my @compatible_haplogroup_names = ();
    
    # take each tree row (skip the 1st row, with headings)
    
    eachtreerow: for (my $j = 1; $j <= $haplotype_n; $j++) {
        # print the loop round numbers for an impatient user
        print "\rNow matching sample $i against haplogroup $j... ";
    
        # split by tabs into a list
        my @current_haplogroup = split /\t/, $tree_rows[$j];
    
        # check if rows match element by element (for non-genotyped do not care);
        # count how many haplotypes the current genotype could match, and
        # list the names & numbers of the rows that matched;
        # code constructed as follows:
        # while k < z+1
            # if k==z, n++ & save the haplogroup name
            # elsif geno_k eq missing, take next k
            # elsif geno_k eq tree_k, take next k
            # else (i.e. geno_k ne tree_k) end this loop and take next j
          
        my $k = 0;

        while ($k <= scalar(@ordered_genotype)) {
            if ($k == scalar(@ordered_genotype)) {
                $n++;
                print "Done.\r";
                push (@compatible_haplogroup_rows, $j); 
                push (@compatible_haplogroup_names, $current_haplogroup[0]);
                $k++; 
            }       
            elsif ($ordered_genotype[$k] eq $genotype_codes{$missing_genotype}) {$k++;}       
            elsif ($ordered_genotype[$k] eq $current_haplogroup[$k+1]) {$k++;}
            else {next eachtreerow;}      
        }
    }
    
    my $code = 0;
    my $real_genotypes = 0;
    my $replaced_genotypes = 0;
    my $missing_genotypes = 0;
    
    # if there is one matching haplotype, replace the missing entries of the genotype
    # with those from the matching haplotype (use small letters & count the replaced)
    if ($n == 1) {
        my @compatible_haplogroup = split /\t/, $tree_rows[$compatible_haplogroup_rows[0]];
        for (my $l = 0; $l < scalar(@ordered_genotype); $l++) {
            if ($ordered_genotype[$l] eq $genotype_codes{$missing_genotype}) {
                $ordered_genotype[$l] = lc $compatible_haplogroup[$l+1];
                $replaced_genotypes++;
            }
        }
        $code = $compatible_haplogroup_names[0];
    }
    
    # if there is more than one matching haplogroup, replace genotypes in those markers
    # that appear identical in all matching haplogroups (use small letters & count the replaced)
    elsif ($n > 1) {
        my @first_compatible_haplogroup = split /\t/, $tree_rows[$compatible_haplogroup_rows[0]];
        my @still_identical = ();
        for (my $a = 0; $a <= scalar(@first_compatible_haplogroup)-1; $a++) {
            push (@still_identical, $a);
        }
        
        foreach (@compatible_haplogroup_rows) {
            my @another_compatible_haplogroup = split /\t/, $tree_rows[$_];
            my @passed = ();
            foreach (@still_identical) {
                if ($first_compatible_haplogroup[$_] eq $another_compatible_haplogroup[$_]) {
                    push (@passed, $_);
                }
            }
            @still_identical = @passed;
        }
        
        foreach(@still_identical) {
            if ($ordered_genotype[$_-1] eq $genotype_codes{$missing_genotype}) {
                $ordered_genotype[$_-1] = lc $first_compatible_haplogroup[$_];
                $replaced_genotypes++;                
            }
        }
        $code =  $code_for_several_matches;
    }
    
    else {$code = $code_for_no_match;}
    
    # after replacements, count how many genotypes are still missing; 
    # by subtraction, find out how many successful genotypes the input file had 
    foreach (@ordered_genotype) {
        if ($_ eq $genotype_codes{$missing_genotype}) {$missing_genotypes++;}
    }
    $real_genotypes = scalar(@ordered_genotype) - $missing_genotypes - $replaced_genotypes;
    
    my $leading_entries = ();
    if ($include_extracols eq 'yes') {
        $leading_entries = join ("\t", @current_genotype[0..$extracols-1]);
    }
    if ($include_extracols eq 'no') {
        $leading_entries = $current_genotype[$samplename_col-1];
    }
    my $new_genotype_entries = join ("\t", @ordered_genotype);    
    my $new_entry = join ("\t", $leading_entries, $new_genotype_entries, $missing_genotypes, $replaced_genotypes, $real_genotypes, $n, $code);
    print RESULT $new_entry,"\n";
}

close SETTINGS;
close GENOTYPE_CODES;
close LABDATA;
close TREE;
close RESULT;
close LOG;

print "\n\nAnalysis ready. See $output_results_file for results and $output_log_file for a run log.\n\n";
    
__END__        
