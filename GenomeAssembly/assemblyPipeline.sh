#!/bin/bash 
start=`date +%s`
usage()
{
  echo "Usage: ./run_PE.sh -d <Directory of fastq files> -s <sample sheet> -m <metadata file> -r <Path to reference genome FASTA File>  -h <help>"
  exit 2
}




OUT=$(date "+%Y.%m.%d-%H.%M.%S")

while getopts d:r:s:m:h: option 
do 
 case "${option}" 
 in 
 d) DIRECTORY=${OPTARG};;
 r) REFERENCE=${OPTARG};;
 s) SAMPLE_SHEET=${OPTARG};;
 m) METADATA=${OPTARG};;

 h|?) usage ;; esac
done



cat $SAMPLE_SHEET | sed -n '/Sample_ID/,$p'  | grep -v Sample_ID | cut -d "," -f1 | sort| uniq > SAMPLE_IDs 
mkdir Fastqc_output_$OUT
mkdir Trimmed_output_$OUT
mkdir Hisat2_LSDV_output_$OUT
mkdir Variant_calling_output_$OUT
mkdir Picard_metrics_$OUT
mkdir PANGO_reports_$OUT

printf "Sample ID\tTotal Reads R1\tTotal Reads R2\tTrimmed Reads R1\tTrimmed Reads R2\tHISAT2_alignment_percentage\tX coverage\tGenome coverage\tVCF Variant Count\tNs in FASTA\n" > SampleSummary.txt

FileList="$(ls $DIRECTORY/*$FASTQ_ZIP | awk '{ print $1}' | awk -F'/' '{ print $2}' | grep "_R1" | awk -F'_R1' '{ print $1}')"


        echo ------------------------------------------------------------------ >> ../LOGFILE.now
        echo "Building HISAT2 indexes for reference genome" >> ../LOGFILE.now
        echo ------------------------------------------------------------------ >> ../LOGFILE.now

        HISAT_BUILD_COMMAND="hisat2-build "$REFERENCE" "$REFERENCE
        echo $HISAT_BUILD_COMMAND
        eval "$HISAT_BUILD_COMMAND"

        echo ------------------------------------------------------------------ >> ../LOGFILE.now
        echo "Done Building Indexes for "$REFERENCE >> ../LOGFILE.now
        echo ------------------------------------------------------------------ >> ../LOGFILE.now

        echo ------------------------------------------------------------------ >> ../LOGFILE.now
        echo "Updating PANGO Lineages version" >> ../LOGFILE.now
        echo ------------------------------------------------------------------ >> ../LOGFILE.now




for i in `cat SAMPLE_IDs`
do
	r1=$(ls -1 $DIRECTORY/"$i"*_R1_*); 
	r2=$(ls -1 $DIRECTORY/"$i"*_R2_*)
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Starting analysis for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Evaluating FASTQC report for Sample "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	FASTQC_COMMAND_R1="fastqc $r1 -o Fastqc_output_"$OUT
	echo $FASTQC_COMMAND_R1
	eval "$FASTQC_COMMAND_R1"
	FASTQC_COMMAND_R2="fastqc $r2 -o Fastqc_output_"$OUT
	echo $FASTQC_COMMAND_R2
	eval "$FASTQC_COMMAND_R2"
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "FASTQC Evaluation Completed for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now



	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Using Trimmomatic to trim low quality bases for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	TRIM_COMMAND_PE="trimmomatic PE $r1 $r2 Trimmed_output_"$OUT"/"$i"_fwd_paired.fastq.gz Trimmed_output_"$OUT"/"$i"_fwd_unpaired.fastq.gz Trimmed_output_"$OUT"/"$i"_rev_paired.fastq.gz Trimmed_output_"$OUT"/"$i"_rev_unpaired.fastq.gz ILLUMINACLIP:"$HOME"/anaconda3/envs/genepi-box/share/trimmomatic/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:15:30 MINLEN:35"	
	echo $TRIM_COMMAND_PE
	eval "$TRIM_COMMAND_PE"

	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Trimmomatic run completed for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now


        
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Using HISAT2 to perform reference based mapping for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	HISAT_COVID_COMMAND="hisat2 -x "$REFERENCE" -1 Trimmed_output_"$OUT"/"$i"_fwd_paired.fastq.gz -2 Trimmed_output_"$OUT"/"$i"_rev_paired.fastq.gz -S Hisat2_LSDV_output_"$OUT"/"$i"_aligned.sam -p 2 --summary-file Hisat2_LSDV_output_"$OUT"/"$i"_hisat.log"        
	echo $HISAT_COVID_COMMAND
	eval "$HISAT_COVID_COMMAND"
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Reference mapping using HISAT2 completed for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now



	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Converting SAM to BAM and performing coordinate sorting for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	SAM2BAM_COMMAND="samtools sort Hisat2_LSDV_output_"$OUT"/"$i"_aligned.sam -o Hisat2_LSDV_output_"$OUT"/"$i"_aligned.bam"
	echo "$SAM2BAM_COMMAND"
	eval "$SAM2BAM_COMMAND"
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Post-processing completed for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	COVID_FLAGSTAT_COMMAND="samtools flagstat Hisat2_LSDV_output_"$OUT"/"$i"_aligned.bam > Hisat2_LSDV_output_"$OUT"/"$i"_flagstat.txt"
	echo "$COVID_FLAGSTAT_COMMAND"
	eval "$COVID_FLAGSTAT_COMMAND"

	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Generating pileup file for variant calling for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	COVID_MPILEUP="samtools mpileup -f "$REFERENCE" Hisat2_LSDV_output_"$OUT"/"$i"_aligned.bam > Variant_calling_output_"$OUT"/"$i".pileup"
	echo "$COVID_MPILEUP"
	eval "$COVID_MPILEUP"
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Pileup file generated for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Calling Variants using VarScan for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	VARSCAN_COMMAND="varscan mpileup2cns Variant_calling_output_"$OUT"/"$i".pileup --output-vcf 1 --variants > Variant_calling_output_"$OUT"/"$i".vcf"
	echo "$VARSCAN_COMMAND"
	eval "$VARSCAN_COMMAND"
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Variant calling using VarScan Completed for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Generating FASTA Sequence for the sample "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	CONSENSUS_MPILEUP_COMMAND="samtools mpileup -uf "$REFERENCE" Hisat2_LSDV_output_"$OUT"/"$i"_aligned.bam | bcftools call -c | vcfutils.pl vcf2fq > Variant_calling_output_"$OUT"/"$i"_consensus.fq"
	eval "$CONSENSUS_MPILEUP_COMMAND"

	FASTQ_FASTA_COMMAND="seqtk seq -aQ64 -q20 -n N Variant_calling_output_"$OUT"/"$i"_consensus.fq > Variant_calling_output_"$OUT"/"$i"_consensus.fasta"
	echo "$FASTQ_FASTA_COMMAND"
	eval "$FASTQ_FASTA_COMMAND"
	echo ------------------------------------------------------------------
	echo "Generated FASTA Sequence for the sample. The output is stored in : Variant_calling_output_"$OUT"/"$i"_consensus.fasta" >> ../LOGFILE.now
	echo ------------------------------------------------------------------

	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Running picard to collect coverage information for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	PICARD_COMMAND="picard CollectMultipleMetrics -I Hisat2_LSDV_output_"$OUT"/"$i"_aligned.bam -O Picard_metrics_"$OUT"/"$i" -R "$REFERENCE
	eval "$PICARD_COMMAND"
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Picard run completed for "$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now 

	echo ------------------------------------------------------------------
	echo "Generating Report for Sample:"$i >> ../LOGFILE.now
	echo ------------------------------------------------------------------

	r1_cmd="zcat $r1 | wc -l | awk -F'\t' '(\$1=\$1/4)'"
	r1=$(eval "$r1_cmd")

	r2_cmd="zcat $r2 | wc -l | awk -F'\t' '(\$1=\$1/4)'"
	r2=$(eval "$r2_cmd")

	tr1_cmd="zcat Trimmed_output_"$OUT"/"$i"_fwd_paired.fastq.gz | wc -l |  awk -F'\t' '(\$1=\$1/4)'"
	tr1=$(eval "$tr1_cmd")

	tr2_cmd="zcat Trimmed_output_"$OUT"/"$i"_rev_paired.fastq.gz | wc -l |  awk -F'\t' '(\$1=\$1/4)'"
	tr2=$(eval "$tr2_cmd")

	hsa_cmd="tail -1 Hisat2_LSDV_output_"$OUT"/"$i"_hisat.log | sed 's/\% overall alignment rate//g'"  
	hsa=$(eval "$hsa_cmd")

	bpcov_cmd="cat Picard_metrics_"$OUT"/"$i".alignment_summary_metrics  | grep -w "PAIR" | cut -f8"
	bpcov=$(eval "$bpcov_cmd")

	xcov=$(echo $bpcov| awk '($1=$1/150773)')

	grzero_cmd="samtools depth -a Hisat2_LSDV_output_"$OUT"/"$i"_aligned.bam | awk -F'\t' '(\$3>0)' | wc -l"
	grzero=$(eval "$grzero_cmd")

	genomecov=$(echo $grzero | awk '($1=100*$1/150773)')

	varcount_cmd="cat Variant_calling_output_"$OUT"/"$i".vcf  | grep -v '#' | wc -l "
	varcount=$(eval "$varcount_cmd")

	fastaN_cmd="cat Variant_calling_output_"$OUT"/"$i"_consensus.fasta  | grep -v '>' | grep -io N| wc -l "
	fastaN=$(eval "$fastaN_cmd")

	

	printf $i"\t"$r1"\t"$r2"\t"$tr1"\t"$tr2"\t"$hsa"\t"$xcov"\t"$genomecov"\t"$varcount"\t"$fastaN"\n" >> SampleSummary.txt
	echo ------------------------------------------------------------------ >> ../LOGFILE.now
	echo "Analysis completed for Sample:"$i  >> ../LOGFILE.now
	echo ------------------------------------------------------------------ >> ../LOGFILE.now

	rm "Variant_calling_output"_$OUT"/"$i".pileup"
	rm "Variant_calling_output_"$OUT"/"$i"_consensus.fq" 
	rm "Trimmed_output_"$OUT"/"$i"_fwd_unpaired.fastq.gz"
        rm "Trimmed_output_"$OUT"/"$i"_rev_unpaired.fastq.gz"
done

echo ------------------------------------------------------------------ >> ../LOGFILE.now
echo "Annotating Variant Calls and Updating Report File" >> ../LOGFILE.now 
echo ------------------------------------------------------------------ >> ../LOGFILE.now


for i in `cat SAMPLE_IDs`; do printf $i"\t"; vars=$(cat "Variant_calling_output_"$OUT"/"$i".vcf" | grep -v "##" | cut -f1,2,4,5,10 | awk -F":" '($7=="100%" || $7>50)' | cut -f1,2,3,4 | tr "\n" "," | sed 's/\t/:/g'); printf $vars"\n"; done > Nucleotide_Mutations.txt

sed -i 's/NC_003027\.1://g' Nucleotide_Mutations.txt
sed -i 's/,$//g' Nucleotide_Mutations.txt


cat Variant_calling_output_$OUT/*.vcf | grep -v "#" | awk -F"\t" '{print "1\t"$2"\t.\t"$4"\t"$5"\t.\t.\t.\t"}' | grep -v "," |sort | uniq > vars_combined.vcf

echo "otherinfo" > otherinfo

cat Variant_calling_output_$OUT/*.vcf | grep -v "#" | awk -F"\t" '{print "1\t"$2"\t.\t"$4"\t"$5"\t.\t.\t.\t"$2":"$4":"$5 }' | grep -v "," |sort | uniq | cut -f9 >> otherinfo

perl scripts/annovar/convert2annovar.pl --format vcf4 vars_combined.vcf --outfile VARS.avi

perl scripts/annovar/table_annovar.pl VARS.avi scripts/annovar/LSDVDB/ --buildver LSDV --outfile ANNOTATED_VARS --protocol refGene --operation g --nastring . --remove --otherinfo


cut -f10,11 ANNOTATED_VARS.LSDV_multianno.txt | cut -d":" -f1,5  | cut -d"," -f1 | sed 's/p\.//g' | cut -f1 > V1
paste V1 otherinfo > AA_VARS.txt

rm V1



python scripts/var_changeToAA.py AA_VARS.txt Nucleotide_Mutations.txt PROTEIN_VARS.txt


x=$(cut -f2 PROTEIN_VARS.txt | tr "," "\n" | grep "[0-9].OR\|[0-9].\." | cut -d":" -f1 | sort | uniq | sed "s/^/sed 's\//g" | sed 's/\./\\./g'|sed "s/$/\/\\/g'/g" | sed "s/ORF1a\//ORF1a\/ORF1a/g"|tr "\n" "|"); y=$(printf "cat PROTEIN_VARS.txt| $x  sed 's/\.,//g' | sed 's/,\.$//g' |sed 's/,$//g' >prot.txt")
eval $y
mv prot.txt AA_Mutations.txt
rm PROTEIN_VARS.txt AA_VARS.txt ANNOTATED_VARS.LSDV_multianno.txt vars_combined.vcf otherinfo VARS.avi

sed -i '1s/^/Sample ID\tNucleotide Mutations\n/' Nucleotide_Mutations.txt
sed -i '1s/^/Sample ID\tAA Mutations\n/' AA_Mutations.txt

paste  SampleSummary.txt  <(awk -F"\t" '{print $2}' Nucleotide_Mutations.txt) > .tmp
paste  .tmp  <(awk -F"\t" '{print $2}' AA_Mutations.txt)> .tmp2


for i in `cat SAMPLE_IDs`; do grep -w $i $METADATA ; done | cut -f4,7   | sed '1s/^/Collection Date\tLocation\n/g' > .dates
paste .tmp2 .dates > SampleSummary.txt

rm .tmp .tmp2 .dates

./scripts/fasta_combine.sh
#./scripts/gisaid_format.sh $METADATA
#./scripts/masterfiles_update.sh $METADATA

end=`date +%s`

runtime=$((end-start))

echo ------------------------------------------------------------------ >> ../LOGFILE.now
echo All done >> ../LOGFILE.now
echo Time Taken: $runtime seconds >> ../LOGFILE.now
echo ------------------------------------------------------------------ >> ../LOGFILE.now
