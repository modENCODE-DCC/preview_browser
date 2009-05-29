package MyConstants;

# various lookup tables etc;

# The base directory for uploaded/extracted data files
use constant WHERE      => "$ENV{HOME}/preview_data";


# If the final location of wib files is somewhere else, 
# set the base directory for ./browser here
use constant DESTINATION_DIR => "/nfs/preview_data"; 

# verbose reporting
use constant DEBUG      => 1;

# Which types will trigger a peak (wiggle box) summary
use constant WIG        => qw/transcript_region
                              protein_binding_site
                              histone_binding_site
                              binding_site
                              TF_binding_site
                              computed_peaks
                              computed_peak
                              peak
                              peaks/;

# for the config reasoner
# adjust as required
use constant TYPES =>  (
                         WIG                  => 'wiggle',
                         microarray_oligo     => 'wiggle',
                         gene                 => 'gene',
                         mRNA                 => 'gene',
                         ncRNA                => 'gene',
                         miRNA                => 'gene',
                         tRNA                 => 'gene',
                         transcript           => 'gene',
                         EST                  => 'est',
                         EST_match            => 'est',
                         expressed_sequence_match=>'est',
                         match                => 'quantitative',
                         match_part           => 'quantitative',
                         Signal_Graph_File    => 'wiggle',
                         transcript_region    => 'peak',
                         protein_binding_site => 'peak',
			 TF_binding_site      => 'peak',
                         histone_binding_site => 'peak',
                         binding_site         => 'peak',
                         computed_peaks       => 'peak',
                         peaks                => 'peak',
			 peak                 => 'peak',
                         rnaseq_wiggle        => 'hybrid_wiggle',
                         SNP                  => 'basic',
                         unknown              => 'basic'
			);

# lab -> organism chart
use constant ORG => (
                     Celniker   => 'fly',
                     Henikoff   => undef,
                     Karpen     => 'fly',
                     Lai        => 'fly',
                     Lieb       => 'worm',
                     MacAlpine  => 'fly',
                     Piano      => 'worm',
                     Snyder     => 'worm',
                     Stein      => undef,
                     Waterston  => 'worm',
                     White      => 'fly',
                     );


# Lab color chart 
use constant LABCOLOR => (
			  Celniker   => 'red',
			  Henikoff   => 'green',
			  Karpen     => 'lightsteelblue',
			  Lai        => 'peachpuff',
			  Lieb       => 'cyan',
			  MacAlpine  => 'blue',
			  Piano      => 'steelblue',
			  Snyder     => 'magenta',
			  Stein      => 'yellow',
			  Waterston  => 'purple',
			  White      => 'black',
			  );

# Allowed chromosome names to get rid of bogus junk target lines in the GFF
use constant REFSEQ  => (
			 qw/
			 2L 2LHet 2R 2RHet 4 M MtDNA U UExtra X XHet Y YHetI
			 2Lhet 2Rhet Xhet YhetI
			 I II III IV V X
			 /		 
			 );


1;
