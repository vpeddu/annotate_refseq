inputCh = Channel.fromPath( 's3://clomp-reference-data/aligner-testing/refseq_genome_download/*.fna.gz' )
//inputCh = Channel.fromPath( '/Users/gerbix/Downloads/nf_refseq_download/testing/*.txt' )
PARSEREFSEQ=file('s3://clomp-reference-data/aligner-testing/parse_refseq.py')
NUCLTOGB=file("s3://clomp-reference-data/aligner-testing/nucl_gb.accession2taxid")
//inputCh = Channel.fromPath( '/Users/gerbix/Downloads/nf_refseq_download/assembly_summary_refseq .txt' )


process Annotate {
  publishDir 's3://clomp-reference-data/aligner-testing/refseq_genome_download/annotated/'

 //publishDir '/Users/gerbix/Downloads/nf_refseq_download/test_output'
  
  errorStrategy 'retry'
    maxErrors 5

  cpus 31
  memory '255 GB'


  input:
  file  "*.fna.gz" from inputCh.flatten().distinct().collate(5000)
  file PARSEREFSEQ
  file NUCLTOGB
  
  output:
  file "*annotated.fasta" into combine_ch
  //cpus 4

  container 'quay.io/vpeddu/clomp_containers'


  //errorStrategy 'ignore'


  //validExitStatus 0,1,2,4,8

script:
 """
 #!/bin/bash

 ls -latr

  cat *.fna.gz | gunzip > combined.fna

  python3 ${PARSEREFSEQ}

  """
}

process Combine {
  publishDir 's3://clomp-reference-data/aligner-testing/refseq_genome_download/combined/'

 //publishDir '/Users/gerbix/Downloads/nf_refseq_download/test_output'
  
  cpus 31
  memory '255 GB'


  input:
  file  "*.annotated.fasta" from combine_ch.collect()
  
  output:
  file "*.fa" 


  container 'quay.io/biocontainers/ucsc-fasplit:377--h199ee4e_0'


  //errorStrategy 'ignore'


  //validExitStatus 0,1,2,4,8

script:
 """
 #!/bin/bash

 ls -latr

 echo "unzipping and combining"

 cat *.fasta > refseq_genome_annotated_combined.fna

 echo "running faSplit"

 faSplit sequence refseq_genome_annotated_combined  6 rf

  """
}
